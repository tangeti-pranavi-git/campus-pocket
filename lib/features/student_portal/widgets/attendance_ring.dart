import 'package:flutter/material.dart';

class AttendanceRing extends StatelessWidget {
  const AttendanceRing({required this.value, super.key});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final pct = (value ?? 0).clamp(0, 100).toDouble();
    final ratio = pct / 100;

    Color color;
    if (pct >= 85) {
      color = const Color(0xFF16A34A);
    } else if (pct >= 70) {
      color = const Color(0xFFF97316);
    } else {
      color = const Color(0xFFDC2626);
    }

    return SizedBox(
      height: 74,
      width: 74,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: ratio,
            strokeWidth: 8,
            backgroundColor: color.withOpacity(0.2),
            color: color,
          ),
          Center(
            child: Text(
              value == null ? '--' : '${pct.toStringAsFixed(1)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
