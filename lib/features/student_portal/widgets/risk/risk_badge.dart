import 'package:flutter/material.dart';
import '../../models/risk_prediction_model.dart';

class RiskBadge extends StatelessWidget {
  final RiskLevel level;

  const RiskBadge({super.key, required this.level});

  @override
  Widget build(BuildContext context) {
    Color color;
    String text;
    IconData icon;

    switch (level) {
      case RiskLevel.low:
        color = Colors.greenAccent;
        text = 'LOW RISK';
        icon = Icons.check_circle_outline;
        break;
      case RiskLevel.medium:
        color = Colors.orangeAccent;
        text = 'MEDIUM RISK';
        icon = Icons.warning_amber_rounded;
        break;
      case RiskLevel.high:
        color = Colors.redAccent;
        text = 'HIGH RISK';
        icon = Icons.error_outline;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
