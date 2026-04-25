import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../ai_chat/services/ai_chat_service.dart';
import '../../ai_chat/models/chat_message.dart';
import 'package:permission_handler/permission_handler.dart';

enum VoiceState { initial, listening, processing, speaking, error }

class VoiceAssistantProvider extends ChangeNotifier {
  final AiChatService _aiService;
  final SpeechToText _speechToText = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  String _userId = '';

  VoiceAssistantProvider(this._aiService) {
    _initTts();
  }

  VoiceState _state = VoiceState.initial;
  VoiceState get state => _state;

  String _currentLanguageCode = 'en_US';
  String get currentLanguageCode => _currentLanguageCode;

  String _transcript = '';
  String get transcript => _transcript;

  String _aiResponse = '';
  String get aiResponse => _aiResponse;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  List<ChatMessage> _history = [];
  List<ChatMessage> get history => _history;

  ActionDraft? _pendingAction;
  ActionDraft? get pendingAction => _pendingAction;

  void clearPendingAction() {
    _pendingAction = null;
    notifyListeners();
  }

  bool _speechEnabled = false;

  Future<bool> _initSpeech() async {
    if (_speechEnabled) return true;
    _speechEnabled = await _speechToText.initialize(
      onError: (val) {
        if (val.errorMsg != 'error_no_match') {
          _handleError('Speech error: ${val.errorMsg}');
        }
      },
      onStatus: (val) {
        if (val == 'notListening' && _state == VoiceState.listening) {
          _stopListeningAndProcess();
        }
      },
    );
    return _speechEnabled;
  }

  Future<void> _initTts() async {
    if (!kIsWeb) {
      await _flutterTts.setSharedInstance(true);
    }
    await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
        [
          IosTextToSpeechAudioCategoryOptions.allowBluetooth,
          IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
          IosTextToSpeechAudioCategoryOptions.mixWithOthers,
          IosTextToSpeechAudioCategoryOptions.defaultToSpeaker
        ],
        IosTextToSpeechAudioMode.defaultMode
    );
    _flutterTts.setCompletionHandler(() {
      if (_state == VoiceState.speaking) {
        _state = VoiceState.initial;
        notifyListeners();
      }
    });
  }

  void setLanguage(String code) {
    _currentLanguageCode = code;
    notifyListeners();
  }

  Future<void> startListening() async {
    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _handleError('Microphone permission denied.');
        return;
      }
    }

    final isInit = await _initSpeech();
    if (!isInit) {
      _handleError('Speech recognition not available. Please allow microphone access.');
      return;
    }

    await _flutterTts.stop();
    _transcript = '';
    _aiResponse = '';
    _errorMessage = null;
    _pendingAction = null;
    _state = VoiceState.listening;
    notifyListeners();

    await _speechToText.listen(
      onResult: (result) {
        _transcript = result.recognizedWords;
        if (result.finalResult && _state == VoiceState.listening) {
          _stopListeningAndProcess();
        }
        notifyListeners();
      },
      localeId: _currentLanguageCode,
      cancelOnError: true,
      partialResults: true,
      listenMode: ListenMode.confirmation,
    );
  }

  Future<void> _stopListeningAndProcess() async {
    await _speechToText.stop();
    if (_transcript.trim().isEmpty) {
      _state = VoiceState.initial;
      notifyListeners();
      return;
    }

    _state = VoiceState.processing;
    notifyListeners();
    await _processQuery(_transcript);
  }

  /// Called by the "Answer Query" button to manually trigger RAG on current transcript
  Future<void> submitTranscript() async {
    if (_transcript.trim().isEmpty) return;
    _aiResponse = '';
    _errorMessage = null;
    _state = VoiceState.processing;
    notifyListeners();
    await _processQuery(_transcript);
  }

  Future<void> stop() async {
    if (_state == VoiceState.listening) {
      await _speechToText.stop();
    } else if (_state == VoiceState.speaking) {
      await _flutterTts.stop();
    }
    _state = VoiceState.initial;
    notifyListeners();
  }

  Future<void> _processQuery(String query) async {
    try {
      final langName = _getLanguageName(_currentLanguageCode);
      final systemPromptAddition = "IMPORTANT: You are a helpful school assistant for a parent. "
          "The parent is asking queries via VOICE. "
          "You MUST respond ONLY in $langName. "
          "If the parent asks to send a message to a teacher, formulate your response exactly like: ACTION:SEND_MESSAGE|teacher_name|subject|message_content. "
          "Otherwise, answer concisely in $langName. Refuse to answer non-school related queries (movies, politics, coding, etc).";

      final contextMap = _currentContext ?? {};
      contextMap['system_instruction'] = systemPromptAddition;

      final response = await _aiService.sendMessage(
        userId: _userId,
        query: query,
        role: 'parent',
        context: contextMap,
        history: _history,
      );

      _history.add(ChatMessage(isUser: true, content: query, timestamp: DateTime.now()));

      if (response.startsWith('ACTION:SEND_MESSAGE')) {
        final parts = response.split('|');
        if (parts.length >= 4) {
          _pendingAction = ActionDraft(
            teacherName: parts[1],
            subject: parts[2],
            message: parts[3],
          );
          _aiResponse = _currentLanguageCode.startsWith('te') ? 'సరే, నేను టీచర్‌కి మెసేజ్ డ్రాఫ్ట్ చేశాను. నిర్ధారించండి.' :
                        _currentLanguageCode.startsWith('hi') ? 'ठीक है, मैंने टीचर को मैसेज ड्राफ्ट कर दिया है। कृपया पुष्टि करें।' :
                        'Okay, I have drafted the message to the teacher. Please confirm to send.';
        } else {
          _aiResponse = response;
        }
      } else {
        _aiResponse = response;
      }
      
      _history.add(ChatMessage(isUser: false, content: _aiResponse, timestamp: DateTime.now()));

      _state = VoiceState.speaking;
      notifyListeners();

      await _flutterTts.setLanguage(_currentLanguageCode);
      await _flutterTts.speak(_aiResponse);

    } catch (e) {
      _handleError('Failed to process: $e');
    }
  }

  Map<String, dynamic>? _currentContext;
  void updateContext(Map<String, dynamic> contextData) {
    _currentContext = contextData;
  }

  void setUserId(String id) {
    _userId = id;
  }

  void _handleError(String msg) {
    _errorMessage = msg;
    _state = VoiceState.error;
    notifyListeners();
  }

  String _getLanguageName(String code) {
    if (code.startsWith('te')) return 'Telugu';
    if (code.startsWith('hi')) return 'Hindi';
    return 'English';
  }
}

class ActionDraft {
  final String teacherName;
  final String subject;
  final String message;

  ActionDraft({required this.teacherName, required this.subject, required this.message});
}
