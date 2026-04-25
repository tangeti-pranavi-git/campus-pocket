import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../contexts/auth_controller.dart';
import '../types/portal_user.dart';
import '../utils/validators.dart';
import '../../services/biometric_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  final _biometricService = BiometricService();
  bool _hidePassword = true;
  bool _biometricSupported = false;
  bool _biometricEnabled = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    _biometricSupported = await _biometricService.isBiometricSupported();
    _biometricEnabled = await _biometricService.isBiometricEnabled();
    if (mounted) setState(() {});

    if (_biometricEnabled) {
      _promptBiometricLogin();
    }
  }

  Future<void> _promptBiometricLogin() async {
    final success = await _biometricService.authenticate();
    if (success) {
      final credentials = await _biometricService.getCredentials();
      if (credentials != null && mounted) {
        _usernameController.text = credentials['email']!;
        _passwordController.text = credentials['password']!;
        _submit();
      }
    }
  }

  Future<void> _showEnableBiometricDialog(String email, String password) async {
    final enable = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1412),
        title: const Text('Enable Fingerprint Login', style: TextStyle(color: Colors.white)),
        content: const Text('Enable Fingerprint Login for faster future access?', style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Maybe Later', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF8A00)),
            child: const Text('Enable Now', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
    );

    if (enable == true) {
      final success = await _biometricService.authenticate();
      if (success) {
        await _biometricService.enableBiometric(email, password);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fingerprint Login Enabled')));
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthController>();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    await auth.login(
      username: _usernameController.text,
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (auth.currentUser?.role == UserRole.student) {
      context.go('/student/home');
      return;
    }

    if (auth.currentUser?.role == UserRole.parent) {
      if (_biometricSupported && !_biometricEnabled) {
        await _showEnableBiometricDialog(_usernameController.text, _passwordController.text);
      }
      if (mounted) context.go('/parent/home');
      return;
    }

    if (auth.errorMessage == null) {
      await auth.logout();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No role found. Contact support.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();

    return Scaffold(
      body: Stack(
        children: [
          // Ambient Glow 1
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33FF8A00), // Vibrant Orange Glow
              ),
            ),
          ),
          // Ambient Glow 2
          Positioned(
            bottom: -150,
            right: -50,
            child: Container(
              width: 400,
              height: 400,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Color(0x33E52E71), // Deep Pink Glow
              ),
            ),
          ),
          // Blur Layer
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: const SizedBox(),
            ),
          ),
          // Main Content
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0x801A1412), // Semi-transparent warm card
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 30,
                          offset: Offset(0, 15),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.school_rounded,
                                  size: 48,
                                  color: Color(0xFFFF8A00),
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'Campus Pocket',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.5,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Welcome back. Please sign in.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: Color(0xFF94A3B8),
                                  ),
                                ),
                                const SizedBox(height: 32),
                                TextFormField(
                                  controller: _usernameController,
                                  keyboardType: TextInputType.text,
                                  textInputAction: TextInputAction.next,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: const InputDecoration(
                                    labelText: 'Username',
                                    prefixIcon: Icon(Icons.person_outline, color: Color(0xFF64748B)),
                                  ),
                                  validator: (value) => validateUsername(value ?? ''),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _passwordController,
                                  obscureText: _hidePassword,
                                  textInputAction: TextInputAction.done,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF64748B)),
                                    suffixIcon: IconButton(
                                      onPressed: () => setState(() => _hidePassword = !_hidePassword),
                                      icon: Icon(
                                        _hidePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                  validator: (value) => validatePassword(value ?? ''),
                                ),
                                const SizedBox(height: 12),
                                Theme(
                                  data: Theme.of(context).copyWith(
                                    unselectedWidgetColor: const Color(0xFF64748B),
                                  ),
                                  child: CheckboxListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: const Text(
                                      'Remember me',
                                      style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 14),
                                    ),
                                    activeColor: const Color(0xFFFF8A00),
                                    checkColor: Colors.black,
                                    value: auth.rememberMe,
                                    controlAffinity: ListTileControlAffinity.leading,
                                    onChanged: auth.isBusy
                                        ? null
                                        : (value) {
                                            auth.setRememberMe(value ?? false);
                                          },
                                  ),
                                ),
                                if (auth.errorMessage != null) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0x1AFFFF3366),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: const Color(0x4DFFFF3366)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.error_outline, color: Color(0xFFFF3366), size: 20),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            auth.errorMessage!,
                                            style: const TextStyle(color: Color(0xFFFF3366), fontSize: 13),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                if (_biometricEnabled) ...[
                                  const SizedBox(height: 16),
                                  Center(
                                    child: IconButton(
                                      onPressed: _promptBiometricLogin,
                                      icon: const Icon(Icons.fingerprint, size: 48, color: Color(0xFFFF8A00)),
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 24),
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x4DFF8A00),
                                        blurRadius: 15,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: auth.isBusy ? null : _submit,
                                    style: ElevatedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                    ),
                                    child: auth.isBusy
                                        ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                            ),
                                          )
                                        : const Text(
                                            'Sign In',
                                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
