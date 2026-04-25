import 'package:flutter/material.dart';

import '../models/parent_portal_models.dart';

class NotificationsAlertsSheet extends StatelessWidget {
  const NotificationsAlertsSheet({required this.children, super.key});

  final List<ChildSummary> children;

  @override
  Widget build(BuildContext context) {
    final alerts = <_AlertItem>[];

    for (final child in children) {
      if (child.feeStatus == FeeStatusType.overdue) {
        alerts.add(_AlertItem('OVERDUE FEE', '${child.childName} has an overdue fee.', const Color(0xFFB91C1C)));
      } else if (child.feeStatus == FeeStatusType.pending) {
        alerts.add(_AlertItem('PENDING FEE', '${child.childName} has pending fees.', const Color(0xFFC2410C)));
      }

      if ((child.attendancePercentage ?? 100) < 75) {
        alerts.add(_AlertItem(
          'LOW ATTENDANCE',
          '${child.childName} attendance is ${child.attendancePercentage?.toStringAsFixed(1) ?? '--'}%.',
          const Color(0xFFB91C1C),
        ));
      }
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: SizedBox(
                height: 4,
                width: 40,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.all(Radius.circular(99)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Notifications & Alerts',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (alerts.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('No critical alerts. All clear.'),
              )
            else
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: alerts.length,
                  itemBuilder: (_, i) {
                    final alert = alerts[i];
                    return Card(
                      child: ListTile(
                        leading: Icon(Icons.notifications_active_rounded, color: alert.color),
                        title: Text(alert.title),
                        subtitle: Text(alert.message),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem(this.title, this.message, this.color);

  final String title;
  final String message;
  final Color color;
}
