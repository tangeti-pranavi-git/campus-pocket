import 'package:flutter/material.dart';

class TrendMiniChart extends StatelessWidget {
  final double trendDelta;
  final List<double> scores;

  const TrendMiniChart({super.key, required this.trendDelta, required this.scores});

  @override
  Widget build(BuildContext context) {
    final isPositive = trendDelta >= 0;
    final color = isPositive ? Colors.greenAccent : Colors.redAccent;
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Performance Trend',
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    '${isPositive ? '+' : ''}${trendDelta.toStringAsFixed(1)}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isPositive ? 'Improving' : 'Declining',
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
