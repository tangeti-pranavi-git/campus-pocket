import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/chat_message.dart';
import '../../../src/config/env.dart';

class AiChatService {
  final SupabaseClient _supabase;

  AiChatService(this._supabase);

  Future<String> sendMessage({
    required String userId,
    required String query,
    required String role,
    required Map<String, dynamic> context,
    required List<ChatMessage> history,
  }) async {
    // Use the explicitly provided userId instead of relying on Supabase Auth which might be using custom RBAC
    final String targetUserId = userId;

    // Call OpenRouter directly since FastAPI backend is unavailable
    try {
      final systemMessage = context['system_instruction'] ?? "You are a helpful AI assistant for Campus Pocket.";
      
      final messages = [
        {"role": "system", "content": "$systemMessage\n\nContext Data:\n${jsonEncode(context)}"},
      ];
      
      for (final msg in history) {
        messages.add({"role": msg.isUser ? "user" : "assistant", "content": msg.content});
      }
      messages.add({"role": "user", "content": query});

      final response = await http.post(
        Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.openAiApiKey}',
          'HTTP-Referer': 'https://campuspocket.com',
          'X-Title': 'Campus Pocket App',
        },
        body: jsonEncode({
          'model': 'google/gemini-2.5-flash',
          'messages': messages,
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final answer = data['choices'][0]['message']['content'];

        // Optionally log to ai_chat_logs
        try {
          await _supabase.from('ai_chat_logs').insert({
            'user_id': targetUserId,
            'role': role,
            'query': query,
            'response': answer,
          });
        } catch (e) {
          // Ignore log errors
        }

        return answer;
      } else {
        throw Exception('Failed to get AI response: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Network error or AI API failure: $e');
    }
  }

  Future<void> sendTeacherMessageDraft({
    required String subject,
    required String message,
    required String teacherName,
    required String parentId,
    required String studentId,
    required String schoolId,
  }) async {
    await _supabase.from('messages').insert({
      'school_id': schoolId,
      'parent_id': parentId,
      'student_id': studentId,
      'teacher_name': teacherName,
      'subject': subject,
      'message': message,
      'status': 'sent'
    });
  }
}
