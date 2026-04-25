import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get supabaseUrl {
    final value = dotenv.env['SUPABASE_URL'] ?? dotenv.env['EXPO_PUBLIC_SUPABASE_URL'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing SUPABASE_URL in .env');
    }
    return value;
  }

  static String get supabaseAnonKey {
    final value = dotenv.env['SUPABASE_ANON_KEY'] ?? dotenv.env['EXPO_PUBLIC_SUPABASE_ANON_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing SUPABASE_ANON_KEY in .env');
    }
    return value;
  }

  static String get openAiApiKey {
    final value = dotenv.env['OPENAI_API_KEY'];
    if (value == null || value.isEmpty) {
      throw StateError('Missing OPENAI_API_KEY in .env');
    }
    return value;
  }
}
