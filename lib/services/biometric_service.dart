import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class BiometricService {
  final LocalAuthentication _auth = LocalAuthentication();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyBiometricEnabled = 'biometric_enabled';
  static const String _keyUserEmail = 'biometric_email';
  static const String _keyUserPassword = 'biometric_password';

  Future<bool> isBiometricSupported() async {
    try {
      final bool canAuthenticateWithBiometrics = await _auth.canCheckBiometrics;
      final bool canAuthenticate = canAuthenticateWithBiometrics || await _auth.isDeviceSupported();
      return canAuthenticate;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan your fingerprint (or face) to login to Parent Portal',
        persistAcrossBackgrounding: true,
        biometricOnly: true,
      );
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isBiometricEnabled() async {
    final String? enabled = await _storage.read(key: _keyBiometricEnabled);
    return enabled == 'true';
  }

  Future<void> enableBiometric(String email, String password) async {
    await _storage.write(key: _keyBiometricEnabled, value: 'true');
    await _storage.write(key: _keyUserEmail, value: email);
    await _storage.write(key: _keyUserPassword, value: password);
  }

  Future<void> disableBiometric() async {
    await _storage.delete(key: _keyBiometricEnabled);
    await _storage.delete(key: _keyUserEmail);
    await _storage.delete(key: _keyUserPassword);
  }

  Future<Map<String, String>?> getCredentials() async {
    final email = await _storage.read(key: _keyUserEmail);
    final password = await _storage.read(key: _keyUserPassword);
    
    if (email != null && password != null) {
      return {'email': email, 'password': password};
    }
    return null;
  }
}
