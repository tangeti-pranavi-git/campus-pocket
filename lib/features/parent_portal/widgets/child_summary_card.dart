import 'package:flutter/material.dart';

import '../models/parent_portal_models.dart';
import 'attendance_progress_ring.dart';
import 'grade_bar.dart';

class ChildSummaryCard extends StatelessWidget {
  const ChildSummaryCard({
    required this.child,
    required this.onViewDetails,
    super.key,
  });

  final ChildSummary child;
  final VoidCallback onViewDetails;

  @override
  Widget build(BuildContext context) {
    final fee = _feeUi(child.feeStatus);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0x80131B2F), // Glassmorphic dark card
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0x1AFFFFFF), width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child.childName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        child.classLabel,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: fee.bg,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    fee.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: fee.fg,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                AttendanceProgressRing(value: child.attendancePercentage),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Average Grade',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      GradeBar(value: child.averageGradePercentage),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonalIcon(
                onPressed: onViewDetails,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('View Details'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  _FeeUi _feeUi(FeeStatusType status) {
    switch (status) {
      case FeeStatusType.paid:
        return const _FeeUi('PAID', Color(0xFF064E3B), Color(0xFF34D399));
      case FeeStatusType.pending:
        return const _FeeUi('PENDING', Color(0xFF78350F), Color(0xFFFBBF24));
      case FeeStatusType.overdue:
        return const _FeeUi('OVERDUE', Color(0xFF7F1D1D), Color(0xFFF87171));
      case FeeStatusType.none:
        return const _FeeUi('NO FEES', Color(0xFF1E293B), Color(0xFF94A3B8));
    }
  }
}

class _FeeUi {
  const _FeeUi(this.label, this.bg, this.fg);

  final String label;
  final Color bg;
  final Color fg;
}
