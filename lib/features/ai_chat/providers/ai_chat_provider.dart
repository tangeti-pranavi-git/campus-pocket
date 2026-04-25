import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../services/ai_chat_service.dart';

class AiChatProvider extends ChangeNotifier {
  final AiChatService _chatService;
  final List<ChatMessage> _messages = [];
  bool _isLoading = false;
  String? _error;

  AiChatProvider(this._chatService);

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;

  void addMessage(ChatMessage message) {
    _messages.add(message);
    notifyListeners();
  }

  void clearHistory() {
    _messages.clear();
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String userId,
    required String query,
    required String role,
    required Map<String, dynamic> context,
  }) async {
    if (query.trim().isEmpty) return;

    _error = null;
    final userMessage = ChatMessage(
      content: query,
      isUser: true,
      timestamp: DateTime.now(),
    );
    addMessage(userMessage);

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _chatService.sendMessage(
        userId: userId,
        query: query,
        role: role,
        context: context,
        history: _messages.where((m) => m != userMessage).toList(),
      );

      // Check if response contains a <DRAFT> tag
      bool isDraft = false;
      String cleanResponse = response;
      if (response.contains('<DRAFT>') && response.contains('</DRAFT>')) {
        isDraft = true;
      }

      final aiMessage = ChatMessage(
        content: cleanResponse,
        isUser: false,
        timestamp: DateTime.now(),
        isDraft: isDraft,
      );
      addMessage(aiMessage);
    } catch (e) {
      _error = e.toString();
      final errorMessage = ChatMessage(
        content: "Sorry, I encountered an error. Please try again.\n\nError: $_error",
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> confirmTeacherMessageDraft({
    required String subject,
    required String message,
    required String teacherName,
    required String parentId,
    required String studentId,
    required String schoolId,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _chatService.sendTeacherMessageDraft(
        subject: subject,
        message: message,
        teacherName: teacherName,
        parentId: parentId,
        studentId: studentId,
        schoolId: schoolId,
      );

      final confirmMessage = ChatMessage(
        content: "Message successfully sent to $teacherName.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      addMessage(confirmMessage);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
