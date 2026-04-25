import 'package:flutter/material.dart';

import '../models/parent_portal_models.dart';

class ChildSelectorCard extends StatelessWidget {
  const ChildSelectorCard({
    super.key,
    required this.children,
    required this.selectedChildId,
    required this.onChanged,
  });

  final List<ChildSummary> children;
  final int? selectedChildId;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1AFFFFFF)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: selectedChildId,
          isExpanded: true,
          dropdownColor: Theme.of(context).colorScheme.surface,
          icon: const Icon(Icons.keyboard_arrow_down, color: Color(0xFFFF8A00)),
          items: children
              .map(
                (child) => DropdownMenuItem<int>(
                  value: child.childId,
                  child: Text(
                    child.childName,
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              )
              .toList(growable: false),
          onChanged: (val) {
            if (val != null) {
              onChanged(val);
            }
          },
        ),
      ),
    );
  }
}
