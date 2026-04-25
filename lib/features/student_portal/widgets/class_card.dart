import 'package:flutter/material.dart';

import '../models/student_portal_models.dart';
import 'attendance_ring.dart';

class ClassCard extends StatelessWidget {
  const ClassCard({
    required this.data,
    required this.onViewPerformance,
    super.key,
  });

  final ClassFeedItem data;
  final VoidCallback onViewPerformance;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1A0F172A),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              data.classroomName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(
              data.teacher,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                AttendanceRing(value: data.attendancePercentage),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _line(context, 'Recent Score Avg', data.recentScoreAverage == null
                          ? 'No marks'
                          : '${data.recentScoreAverage!.toStringAsFixed(1)}%'),
                      const SizedBox(height: 5),
                      _line(context, 'Next Session', data.nextSessionDate == null
                          ? 'No upcoming session'
                          : '${data.nextSessionDate!.day}/${data.nextSessionDate!.month}'),
                      const SizedBox(height: 5),
                      _line(context, 'Topic', data.nextSessionTopic ?? 'TBA'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: onViewPerformance,
                child: const Text('View Performance'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _line(BuildContext context, String key, String value) {
    return RichText(
      text: TextSpan(
        style: Theme.of(context).textTheme.bodySmall,
        children: [
          TextSpan(
            text: '$key: ',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          TextSpan(
            text: value,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}
