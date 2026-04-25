import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../repositories/auth_repository.dart';
import '../types/portal_user.dart';
import '../utils/app_error.dart';

enum AuthStatus { loadingSession, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  static const _sessionKey = 'campus_pocket_session';

  final AuthRepository _repository;

  AuthStatus _status = AuthStatus.loadingSession;
  PortalUser? _currentUser;
  String? _errorMessage;
  bool _isBusy = false;
  bool _rememberMe = true;
  StreamSubscription<AuthState>? _authSubscription;

  AuthStatus get status => _status;
  PortalUser? get currentUser => _currentUser;
  String? get errorMessage => _errorMessage;
  bool get isBusy => _isBusy;
  bool get rememberMe => _rememberMe;

  bool get isStudent => _currentUser?.role == UserRole.student;
  bool get isParent => _currentUser?.role == UserRole.parent;

  Future<void> initialize() async {
    _status = AuthStatus.loadingSession;
    notifyListeners();

    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((event) async {
      if (event.event == AuthChangeEvent.signedOut) {
        await clearSession();
      }
    });

    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool('remember_me') ?? true;
    final rawSession = prefs.getString(_sessionKey);

    if (rawSession == null || rawSession.isEmpty) {
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }

    try {
      final decoded = jsonDecode(rawSession) as Map<String, dynamic>;
      _currentUser = PortalUser.fromJson(decoded);
      _status = AuthStatus.authenticated;
    } catch (_) {
      await clearSession();
      _status = AuthStatus.unauthenticated;
    }

    notifyListeners();
  }

  Future<void> login({required String username, required String password}) async {
    _setBusy(true);
    _setError(null);

    try {
      final user = await _repository.loginWithUsernamePassword(
        username: username,
        password: password,
      );

      _currentUser = user;
      _status = AuthStatus.authenticated;
      await _persistSession();
    } on AppError catch (error) {
      _setError(error.message);
      _status = AuthStatus.unauthenticated;
    } catch (_) {
      _setError('Unexpected error during login');
      _status = AuthStatus.unauthenticated;
    } finally {
      _setBusy(false);
      notifyListeners();
    }
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', value);
    notifyListeners();
  }

  Future<void> logout() async {
    await clearSession();
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _currentUser = null;
  }

  Future<void> _persistSession() async {
    final prefs = await SharedPreferences.getInstance();
    if (!_rememberMe || _currentUser == null) {
      await prefs.remove(_sessionKey);
      return;
    }

    await prefs.setString(_sessionKey, jsonEncode(_currentUser!.toJson()));
  }

  void _setError(String? message) {
    _errorMessage = message;
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
