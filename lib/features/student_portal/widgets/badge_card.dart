import 'package:flutter/material.dart';
import '../models/student_portal_models.dart';

class BadgeCard extends StatelessWidget {
  const BadgeCard({super.key, required this.badge});

  final StudentBadgeItem badge;

  @override
  Widget build(BuildContext context) {
    Color badgeColor;
    switch (badge.rarity.toLowerCase()) {
      case 'epic':
        badgeColor = const Color(0xFF9D4EDD); // Purple
        break;
      case 'rare':
        badgeColor = const Color(0xFF00B4D8); // Blue
        break;
      default:
        badgeColor = const Color(0xFFFF8A00); // Orange
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x331A1412),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: badgeColor.withOpacity(0.5), width: 1.5),
        boxShadow: [
          BoxShadow(color: badgeColor.withOpacity(0.1), blurRadius: 10, spreadRadius: 2),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Icon(Icons.star, color: badgeColor.withOpacity(0.1), size: 100),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  badge.icon,
                  style: const TextStyle(fontSize: 42),
                ),
                const SizedBox(height: 12),
                Text(
                  badge.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  badge.category,
                  style: TextStyle(fontSize: 10, color: badgeColor, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
