import 'package:flutter/material.dart';

class GradeBar extends StatelessWidget {
  const GradeBar({required this.value, super.key});

  final double? value;

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text(
        'No grades yet',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
      );
    }

    final v = value!.clamp(0, 100);
    Color color;
    if (v >= 85) {
      color = const Color(0xFF16A34A);
    } else if (v >= 70) {
      color = const Color(0xFFF97316);
    } else {
      color = const Color(0xFFDC2626);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: v / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${v.toStringAsFixed(1)}%',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }
}
