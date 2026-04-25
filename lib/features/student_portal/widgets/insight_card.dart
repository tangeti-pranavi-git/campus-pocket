import 'package:flutter/material.dart';

import '../models/student_portal_models.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({
    required this.insight,
    required this.onTap,
    super.key,
  });

  final StudentInsight insight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [Color(0xFF0F172A), Color(0xFF1E3A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x260F172A),
              blurRadius: 14,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline_rounded, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'AI Insights',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
                Icon(
                  insight.generatedByAi ? Icons.auto_awesome_rounded : Icons.psychology_alt_rounded,
                  color: Colors.white70,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              insight.summary,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 10),
            Text(
              'Tap to view strengths, weaknesses, and recommendations',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
