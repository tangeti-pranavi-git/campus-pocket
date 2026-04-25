String? validateUsername(String value) {
  if (value.trim().isEmpty) {
    return 'Username is required';
  }
  if (value.trim().length < 3) {
    return 'Username must be at least 3 characters';
  }
  return null;
}

String? validatePassword(String value) {
  if (value.isEmpty) {
    return 'Password is required';
  }
  if (value.length < 6) {
    return 'Password must be at least 6 characters';
  }
  return null;
}
