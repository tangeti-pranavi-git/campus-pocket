import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onConfirmDraft;

  const ChatBubble({
    super.key,
    required this.message,
    this.onConfirmDraft,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    
    // Extract draft content if exists
    String displayContent = message.content;
    String? draftContent;
    
    if (message.isDraft) {
      final startIdx = message.content.indexOf('<DRAFT>');
      final endIdx = message.content.indexOf('</DRAFT>');
      if (startIdx != -1 && endIdx != -1) {
        draftContent = message.content.substring(startIdx + 7, endIdx).trim();
        displayContent = message.content.substring(0, startIdx).trim();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (!isUser) ...[
                _buildAvatar(theme),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: isUser 
                      ? LinearGradient(
                          colors: [theme.colorScheme.primary, const Color(0xFFFFB400)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : LinearGradient(
                          colors: [const Color(0xFF261D1A), const Color(0xFF1A1412)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(24),
                      topRight: const Radius.circular(24),
                      bottomLeft: Radius.circular(isUser ? 24 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (isUser ? theme.colorScheme.primary : Colors.black).withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.05), width: 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (displayContent.isNotEmpty)
                        MarkdownBody(
                          data: displayContent,
                          styleSheet: MarkdownStyleSheet(
                            p: TextStyle(
                              color: isUser ? Colors.black : Colors.white.withOpacity(0.9),
                              fontSize: 15,
                              height: 1.5,
                            ),
                            code: const TextStyle(
                              backgroundColor: Colors.black26,
                              fontFamily: 'monospace',
                              fontSize: 14,
                            ),
                          ),
                        ),
                      if (draftContent != null) _buildDraftAction(context, draftContent),
                    ],
                  ),
                ),
              ),
              if (isUser) ...[
                const SizedBox(width: 8),
                _buildUserAvatar(theme),
              ],
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 44, right: 44),
            child: Text(
              _formatTimestamp(message.timestamp),
              style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatar(ThemeData theme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(color: theme.colorScheme.primary.withOpacity(0.3), blurRadius: 8, spreadRadius: 1),
        ],
      ),
      child: const Center(
        child: Icon(Icons.auto_awesome, size: 18, color: Colors.black),
      ),
    );
  }

  Widget _buildUserAvatar(ThemeData theme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.1),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: const Center(
        child: Icon(Icons.person, size: 18, color: Colors.white70),
      ),
    );
  }

  Widget _buildDraftAction(BuildContext context, String content) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.secondary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: theme.colorScheme.secondary, size: 20),
              const SizedBox(width: 8),
              Text('DRAFTED MESSAGE', 
                style: TextStyle(color: theme.colorScheme.secondary, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 1),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(content, style: const TextStyle(color: Colors.white70, fontSize: 14, fontStyle: FontStyle.italic)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConfirmDraft,
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.secondary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text('CONFIRM & SEND', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime ts) {
    return "${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}";
  }
}
