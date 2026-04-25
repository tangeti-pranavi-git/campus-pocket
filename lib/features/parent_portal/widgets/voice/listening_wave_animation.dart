import 'package:flutter/material.dart';

class ListeningWaveAnimation extends StatefulWidget {
  final bool isListening;

  const ListeningWaveAnimation({super.key, required this.isListening});

  @override
  State<ListeningWaveAnimation> createState() => _ListeningWaveAnimationState();
}

class _ListeningWaveAnimationState extends State<ListeningWaveAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isListening) return const SizedBox.shrink();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            double value = (index * 0.2 + _controller.value) % 1.0;
            double height = 20 + 30 * (value > 0.5 ? 1 - value : value);
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 6,
              height: height,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(10),
              ),
            );
          },
        );
      }),
    );
  }
}
