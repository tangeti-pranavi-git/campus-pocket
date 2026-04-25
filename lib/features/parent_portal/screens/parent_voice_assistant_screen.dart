import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:math' as math;

import '../../../src/contexts/auth_controller.dart';
import '../../ai_chat/services/ai_chat_service.dart';
import '../providers/voice_assistant_provider.dart';
import '../widgets/voice/language_chip_selector.dart';
import '../widgets/voice/transcript_card.dart';
import '../widgets/voice/ai_response_card.dart';
import '../widgets/voice/action_confirm_sheet.dart';
import '../../ai_chat/widgets/ai_particle_background.dart';

class ParentVoiceAssistantScreen extends StatefulWidget {
  final Map<String, dynamic> contextData;
  final String? studentId;
  final String? parentId;
  final String? schoolId;

  const ParentVoiceAssistantScreen({
    super.key,
    required this.contextData,
    this.studentId,
    this.parentId,
    this.schoolId,
  });

  @override
  State<ParentVoiceAssistantScreen> createState() => _ParentVoiceAssistantScreenState();
}

class _ParentVoiceAssistantScreenState extends State<ParentVoiceAssistantScreen> {
  late VoiceAssistantProvider _voiceProvider;

  @override
  void initState() {
    super.initState();
    _voiceProvider = VoiceAssistantProvider(AiChatService(Supabase.instance.client));
    _voiceProvider.updateContext(widget.contextData);
    _voiceProvider.setUserId(widget.parentId ?? '');
  }

  @override
  void dispose() {
    _voiceProvider.stop();
    _voiceProvider.dispose();
    super.dispose();
  }

  void _showActionConfirmSheet(ActionDraft action) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ActionConfirmSheet(
        action: action,
        onConfirm: () async {
          Navigator.pop(context);
          final service = AiChatService(Supabase.instance.client);
          try {
            await service.sendTeacherMessageDraft(
              subject: action.subject,
              message: action.message,
              teacherName: action.teacherName,
              parentId: widget.parentId ?? '',
              studentId: widget.studentId ?? '',
              schoolId: widget.schoolId ?? '',
            );
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Message sent successfully')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Failed to send message: $e')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider<VoiceAssistantProvider>.value(
      value: _voiceProvider,
      child: Consumer<VoiceAssistantProvider>(
        builder: (context, provider, child) {
          
          if (provider.pendingAction != null && provider.state == VoiceState.speaking) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                 final action = provider.pendingAction!;
                 provider.clearPendingAction();
                 _showActionConfirmSheet(action);
              }
            });
          }

          return Scaffold(
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text('Voice AI Assistant', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white)),
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: AiParticleBackground(
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      const LanguageChipSelector(),
                      const SizedBox(height: 32),
                      if (provider.errorMessage != null)
                        _buildErrorDisplay(provider.errorMessage!),
                      
                      Expanded(
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (provider.state == VoiceState.initial)
                                const Text('Tap the mic to start speaking', 
                                  style: TextStyle(color: Colors.white54, fontSize: 16)),
                              
                              if (provider.transcript.isNotEmpty)
                                TranscriptDisplay(text: provider.transcript),
                              
                              const SizedBox(height: 20),
                              
                              // ── Answer Query Button ──────────────────
                              if (provider.transcript.isNotEmpty &&
                                  provider.state != VoiceState.processing &&
                                  provider.state != VoiceState.speaking &&
                                  provider.aiResponse.isEmpty)
                                Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF8A00),
                                      foregroundColor: Colors.black,
                                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                                      elevation: 8,
                                      shadowColor: const Color(0xFFFF8A00).withOpacity(0.4),
                                    ),
                                    icon: const Icon(Icons.auto_awesome, size: 20),
                                    label: const Text('Answer Query', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    onPressed: () => provider.submitTranscript(),
                                  ),
                                ),

                              if (provider.state == VoiceState.processing)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF8A00))),
                                      SizedBox(width: 12),
                                      Text('Analyzing your data...', style: TextStyle(color: Color(0xFFFF8A00), fontSize: 14)),
                                    ],
                                  ),
                                ),

                              if (provider.aiResponse.isNotEmpty)
                                AiResponseDisplay(text: provider.aiResponse),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                      VoiceVisualizer(state: provider.state),
                      const SizedBox(height: 40),
                      
                      PremiumMicButton(
                        state: provider.state,
                        onTap: () {
                          if (provider.state == VoiceState.listening) {
                            provider.stop();
                          } else {
                            provider.startListening();
                          }
                        },
                      ),
                      const SizedBox(height: 50),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorDisplay(String msg) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.redAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent),
          const SizedBox(width: 12),
          Expanded(child: Text(msg, style: const TextStyle(color: Colors.redAccent, fontSize: 14))),
        ],
      ),
    );
  }
}

class TranscriptDisplay extends StatelessWidget {
  final String text;
  const TranscriptDisplay({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500, height: 1.4),
      ),
    );
  }
}

class AiResponseDisplay extends StatelessWidget {
  final String text;
  const AiResponseDisplay({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Theme.of(context).colorScheme.primary.withOpacity(0.2), Colors.transparent],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class VoiceVisualizer extends StatefulWidget {
  final VoiceState state;
  const VoiceVisualizer({super.key, required this.state});

  @override
  State<VoiceVisualizer> createState() => _VoiceVisualizerState();
}

class _VoiceVisualizerState extends State<VoiceVisualizer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.state == VoiceState.initial || widget.state == VoiceState.error) {
      return const SizedBox(height: 60);
    }

    return SizedBox(
      height: 60,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(15, (index) {
              double height = 5 + (math.sin(_controller.value * 2 * math.pi + index) + 1) * 20;
              if (widget.state == VoiceState.processing) {
                height = 20 + (math.sin(_controller.value * 4 * math.pi + index) + 1) * 5;
              }
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                width: 4,
                height: height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Theme.of(context).colorScheme.primary, Theme.of(context).colorScheme.secondary],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
              );
            }),
          );
        },
      ),
    );
  }
}

class PremiumMicButton extends StatefulWidget {
  final VoiceState state;
  final VoidCallback onTap;

  const PremiumMicButton({super.key, required this.state, required this.onTap});

  @override
  State<PremiumMicButton> createState() => _PremiumMicButtonState();
}

class _PremiumMicButtonState extends State<PremiumMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isListening = widget.state == VoiceState.listening;
    final isSpeaking = widget.state == VoiceState.speaking;
    final isProcessing = widget.state == VoiceState.processing;

    Color color = theme.colorScheme.primary;
    if (isSpeaking) color = theme.colorScheme.secondary;
    if (isProcessing) color = Colors.blueAccent;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          if (isListening || isSpeaking || isProcessing)
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Container(
                  width: 100 + (_controller.value * 40),
                  height: 100 + (_controller.value * 40),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: color.withOpacity(1 - _controller.value), width: 2),
                  ),
                );
              },
            ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, color.withOpacity(0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(color: color.withOpacity(0.4), blurRadius: 20, spreadRadius: 5),
              ],
            ),
            child: Icon(
              isListening ? Icons.stop_rounded : (isProcessing ? Icons.sync : Icons.mic_rounded),
              size: 40,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
