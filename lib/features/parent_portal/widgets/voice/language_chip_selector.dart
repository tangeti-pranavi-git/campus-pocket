import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/voice_assistant_provider.dart';

class LanguageChipSelector extends StatelessWidget {
  const LanguageChipSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<VoiceAssistantProvider>();
    final languages = [
      {'code': 'en_US', 'label': 'EN'},
      {'code': 'te_IN', 'label': 'తెలుగు'},
      {'code': 'hi_IN', 'label': 'हिंदी'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: languages.map((lang) {
          final isSelected = provider.currentLanguageCode == lang['code'];
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: ChoiceChip(
              label: Text(lang['label']!, style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.black : Colors.white,
              )),
              selected: isSelected,
              selectedColor: Theme.of(context).colorScheme.primary,
              backgroundColor: Theme.of(context).colorScheme.surface,
              onSelected: (selected) {
                if (selected) {
                  provider.setLanguage(lang['code']!);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
