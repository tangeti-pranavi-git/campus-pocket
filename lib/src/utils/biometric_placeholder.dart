class BiometricPlaceholder {
  Future<bool> canUseBiometrics() async {
    return false;
  }

  Future<bool> authenticate() async {
    return false;
  }
}
