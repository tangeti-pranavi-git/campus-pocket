class ChatMessage {
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isDraft;

  ChatMessage({
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isDraft = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'role': isUser ? 'user' : 'assistant',
      'content': content,
    };
  }
}
