import 'package:flutter/material.dart';

import 'skeleton_loader.dart';

class StudentDashboardSkeleton extends StatelessWidget {
  const StudentDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Block(height: 160),
        SizedBox(height: 12),
        _Block(height: 100),
        SizedBox(height: 12),
        _Block(height: 220),
      ],
    );
  }
}

class StudentDetailSkeleton extends StatelessWidget {
  const StudentDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _Block(height: 130),
        SizedBox(height: 12),
        _Block(height: 180),
        SizedBox(height: 12),
        _Block(height: 220),
      ],
    );
  }
}

class _Block extends StatelessWidget {
  const _Block({required this.height});

  final double height;

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
        ),
      ),
    );
  }
}
