import 'package:flutter/material.dart';
import '../skeleton_loader.dart';

class RiskSkeletonLoader extends StatelessWidget {
  const RiskSkeletonLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 300,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const SkeletonBox(),
          ),
          const SizedBox(height: 24),
          Container(
            height: 100,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const SkeletonBox(),
          ),
          const SizedBox(height: 24),
          const SkeletonBox(height: 30, width: 150),
          const SizedBox(height: 12),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SkeletonBox(),
          ),
          const SizedBox(height: 12),
          Container(
            height: 70,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SkeletonBox(),
          ),
        ],
      ),
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double? height;

  const SkeletonBox({super.key, this.width, this.height});

  @override
  Widget build(BuildContext context) {
    return SkeletonLoader(
      child: Container(
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }
}
