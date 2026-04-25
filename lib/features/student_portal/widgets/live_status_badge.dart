import 'package:flutter/material.dart';

class LiveStatusBadge extends StatelessWidget {
  const LiveStatusBadge({required this.isConnected, super.key});

  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final color = isConnected ? const Color(0xFF16A34A) : const Color(0xFFDC2626);
    final label = isConnected ? 'Live' : 'Offline';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fiber_manual_record_rounded, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}
