import 'package:flutter/material.dart';

class AttendanceProgressRing extends StatelessWidget {
  const AttendanceProgressRing({required this.value, super.key});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final display = value == null ? '--' : '${value!.toStringAsFixed(1)}%';
    final ratio = ((value ?? 0) / 100).clamp(0, 1).toDouble();

    Color ringColor;
    if ((value ?? 0) >= 85) {
      ringColor = const Color(0xFF16A34A);
    } else if ((value ?? 0) >= 70) {
      ringColor = const Color(0xFFF97316);
    } else {
      ringColor = const Color(0xFFDC2626);
    }

    return SizedBox(
      height: 70,
      width: 70,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 8,
            backgroundColor: ringColor.withOpacity(0.2),
            color: ringColor,
          ),
          Center(
            child: Text(
              display,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
