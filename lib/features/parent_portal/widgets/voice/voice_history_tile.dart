import 'package:flutter/material.dart';
import '../../ai_chat/models/chat_message.dart';

class VoiceHistoryTile extends StatelessWidget {
  final ChatMessage message;

  const VoiceHistoryTile({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isUser ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isUser ? Theme.of(context).colorScheme.primary.withOpacity(0.3) : Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isUser ? 'You' : 'Assistant',
            style: TextStyle(
              fontSize: 12,
              color: isUser ? Theme.of(context).colorScheme.primary : Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(message.content, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }
}
