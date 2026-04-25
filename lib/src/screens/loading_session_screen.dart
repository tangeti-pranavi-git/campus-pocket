import 'package:flutter/material.dart';

class LoadingSessionScreen extends StatelessWidget {
  const LoadingSessionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 12),
            Text('Restoring session...'),
          ],
        ),
      ),
    );
  }
}
