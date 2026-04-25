import 'package:flutter/material.dart';

class ConsistencyMeter extends StatelessWidget {
  const ConsistencyMeter({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0, 100).toDouble();
    final color = clamped >= 80
        ? const Color(0xFF16A34A)
        : clamped >= 60
            ? const Color(0xFFF97316)
            : const Color(0xFFDC2626);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: clamped / 100,
            minHeight: 10,
            backgroundColor: color.withOpacity(0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${clamped.toStringAsFixed(1)}% consistency',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
