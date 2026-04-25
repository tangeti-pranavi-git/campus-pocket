import 'package:flutter/material.dart';

import '../models/parent_portal_models.dart';

class AlertBanner extends StatelessWidget {
  const AlertBanner({
    required this.message,
    required this.status,
    super.key,
  });

  final String message;
  final FeeStatusType status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, icon) = _styleByStatus(status);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: fg.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _styleByStatus(FeeStatusType type) {
    switch (type) {
      case FeeStatusType.overdue:
        return (const Color(0xFFFEE2E2), const Color(0xFFB91C1C), Icons.warning_amber_rounded);
      case FeeStatusType.pending:
        return (const Color(0xFFFFEDD5), const Color(0xFFC2410C), Icons.schedule_rounded);
      case FeeStatusType.paid:
        return (const Color(0xFFDCFCE7), const Color(0xFF166534), Icons.verified_rounded);
      case FeeStatusType.none:
        return (const Color(0xFFE2E8F0), const Color(0xFF334155), Icons.info_outline_rounded);
    }
  }
}
