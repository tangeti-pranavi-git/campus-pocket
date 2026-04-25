import 'package:flutter/material.dart';
import '../../providers/voice_assistant_provider.dart';

class VoiceMicButton extends StatefulWidget {
  final VoiceState state;
  final VoidCallback onTap;

  const VoiceMicButton({super.key, required this.state, required this.onTap});

  @override
  State<VoiceMicButton> createState() => _VoiceMicButtonState();
}

class _VoiceMicButtonState extends State<VoiceMicButton> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = widget.state == VoiceState.listening;
    final isProcessing = widget.state == VoiceState.processing;
    final isSpeaking = widget.state == VoiceState.speaking;

    Color micColor = Theme.of(context).colorScheme.primary;
    if (isListening) micColor = Colors.redAccent;
    if (isProcessing) micColor = Colors.orangeAccent;
    if (isSpeaking) micColor = Colors.blueAccent;

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: micColor.withOpacity(0.2),
              border: Border.all(color: micColor.withOpacity(0.5), width: 2),
              boxShadow: isListening || isSpeaking
                  ? [BoxShadow(color: micColor.withOpacity(0.5), blurRadius: 20 * _scaleAnimation.value, spreadRadius: 5 * _scaleAnimation.value)]
                  : [],
            ),
            child: Transform.scale(
              scale: isListening || isSpeaking ? _scaleAnimation.value : 1.0,
              child: Icon(
                isProcessing ? Icons.hourglass_bottom_rounded : (isSpeaking ? Icons.volume_up_rounded : Icons.mic_rounded),
                size: 40,
                color: micColor,
              ),
            ),
          );
        },
      ),
    );
  }
}
