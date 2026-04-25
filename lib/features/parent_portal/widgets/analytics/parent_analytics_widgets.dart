import 'package:flutter/material.dart';
import '../../models/parent_portal_models.dart';

class ChildSelectorCard extends StatelessWidget {
  final List<ChildSummary> children;
  final int selectedId;
  final Function(ChildSummary) onSelected;

  const ChildSelectorCard({
    super.key,
    required this.children,
    required this.selectedId,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: children.length,
        itemBuilder: (context, index) {
          final child = children[index];
          final isSelected = child.childId == selectedId;
          return GestureDetector(
            onTap: () => onSelected(child),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).colorScheme.primary : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(color: isSelected ? Colors.transparent : Colors.white10),
              ),
              child: Center(
                child: Text(
                  child.childName,
                  style: TextStyle(
                    color: isSelected ? Colors.black : Colors.white70,
                    fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class InsightAlertCard extends StatelessWidget {
  final String title;
  final String message;
  final Color color;
  final String insight;

  const InsightAlertCard({
    super.key,
    required this.title,
    required this.message,
    required this.color,
    required this.insight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1412),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        boxShadow: [
          BoxShadow(color: color.withOpacity(0.05), blurRadius: 20, spreadRadius: 5),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(Icons.priority_high_rounded, color: color, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w900, letterSpacing: 0.5)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(message, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.03), borderRadius: BorderRadius.circular(16)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber, size: 16),
                const SizedBox(width: 10),
                Expanded(child: Text(insight, style: const TextStyle(color: Colors.white60, fontSize: 13, height: 1.4))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class WeeklyActionCard extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;

  const WeeklyActionCard({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1412),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 4),
                Text(description, style: const TextStyle(color: Colors.white38, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ParentTipCard extends StatelessWidget {
  final List<String> tips;
  final String title;
  final Color accentColor;

  const ParentTipCard({
    super.key,
    required this.tips,
    required this.title,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor.withOpacity(0.1), Colors.transparent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: accentColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: accentColor, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.5)),
          const SizedBox(height: 20),
          ...tips.map((tip) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.check_circle_outline, color: accentColor, size: 16),
                const SizedBox(width: 12),
                Expanded(child: Text(tip, style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.4))),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }
}
