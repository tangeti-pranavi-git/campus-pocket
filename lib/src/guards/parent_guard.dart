import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../contexts/auth_controller.dart';
import '../screens/unauthorized_screen.dart';

class ParentGuard extends StatelessWidget {
  const ParentGuard({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    if (!auth.isParent) {
      return const UnauthorizedScreen();
    }
    return child;
  }
}
