import 'package:supabase_flutter/supabase_flutter.dart';

import '../services/supabase_service.dart';
import '../types/portal_user.dart';
import '../utils/app_error.dart';

class AuthRepository {
  AuthRepository({SupabaseClient? client}) : _client = client ?? SupabaseService.client;

  final SupabaseClient _client;

  Future<PortalUser> loginWithUsernamePassword({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _client.rpc(
        'authenticate_portal_user',
        params: {
          'p_username': username.trim(),
          'p_password': password,
        },
      );

      if (response == null || response is! List || response.isEmpty) {
        throw const AppError('Invalid credentials');
      }

      final row = response.first as Map<String, dynamic>;
      final role = parseUserRole((row['role'] as String?) ?? '');
      if (role == null) {
        throw const AppError('No role found for user');
      }

      return PortalUser(
        id: (row['user_id'] as num).toInt(),
        username: row['username'] as String,
        role: role,
        fullName: row['full_name'] as String,
        schoolId: (row['school_id'] as num).toInt(),
      );
    } on PostgrestException catch (error) {
      throw AppError(error.message);
    } on AppError {
      rethrow;
    } catch (_) {
      throw const AppError('Network issue. Please try again.');
    }
  }
}
