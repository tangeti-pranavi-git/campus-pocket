import 'package:flutter/material.dart';

class InsightReasonTile extends StatelessWidget {
  final String reason;

  const InsightReasonTile({super.key, required this.reason});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.arrow_downward_rounded, color: Colors.redAccent, size: 16),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                reason,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
