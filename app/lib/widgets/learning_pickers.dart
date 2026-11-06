import 'package:flutter/material.dart';

import '../data/levels.dart';
import '../l10n/l10n.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

String levelName(AppLocalizations l, String level) => switch (level) {
      'A2' => l.levelA2,
      'B1' => l.levelB1,
      'B2' => l.levelB2,
      'C1' => l.levelC1,
      _ => l.levelA1,
    };

String levelDescription(AppLocalizations l, String level) => switch (level) {
      'A2' => l.levelA2Desc,
      'B1' => l.levelB1Desc,
      'B2' => l.levelB2Desc,
      'C1' => l.levelC1Desc,
      _ => l.levelA1Desc,
    };

String topicName(AppLocalizations l, String topic) => switch (topic) {
      'retail' => l.topicRetail,
      'it' => l.topicIt,
      'medicine' => l.topicMedicine,
      'hospitality' => l.topicHospitality,
      'construction' => l.topicConstruction,
      'logistics' => l.topicLogistics,
      'office' => l.topicOffice,
      'care' => l.topicCare,
      _ => topic,
    };

const Map<String, String> topicEmoji = {
  'retail': '🛒', 'it': '💻', 'medicine': '🩺', 'hospitality': '🏨',
  'construction': '🏗️', 'logistics': '🚚', 'office': '💼', 'care': '🤝',
};

/// One card per CEFR level (code, name, "what that means").
class LevelPicker extends StatelessWidget {
  const LevelPicker({required this.selected, required this.onChanged, super.key});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final level in cefrLevels)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SelectCard(
              key: Key('level-$level'),
              selected: level == selected,
              onTap: () => onChanged(level),
              leading: Text(level,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accent)),
              title: levelName(l, level),
              subtitle: levelDescription(l, level),
            ),
          ),
      ],
    );
  }
}

/// Multi-select chips for the job areas.
class TopicPicker extends StatelessWidget {
  const TopicPicker({required this.selected, required this.onChanged, super.key});

  final Set<String> selected;
  final ValueChanged<Set<String>> onChanged;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final t in jobTopics)
          FilterChip(
            key: Key('topic-$t'),
            selected: selected.contains(t),
            showCheckmark: false,
            avatar: Text(topicEmoji[t] ?? '', style: const TextStyle(fontSize: 18)),
            label: Text(topicName(l, t)),
            labelStyle: TextStyle(
              color: selected.contains(t) ? AppColors.background : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
            selectedColor: AppColors.accent,
            backgroundColor: AppColors.glassFill,
            side: BorderSide(color: selected.contains(t) ? AppColors.accent : AppColors.glassBorder),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            onSelected: (on) => onChanged(on ? {...selected, t} : ({...selected}..remove(t))),
          ),
      ],
    );
  }
}

class _SelectCard extends StatelessWidget {
  const _SelectCard({
    required this.selected,
    required this.onTap,
    required this.leading,
    required this.title,
    required this.subtitle,
    super.key,
  });

  final bool selected;
  final VoidCallback onTap;
  final Widget leading;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: title,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accent : Colors.transparent, width: 2),
          ),
          child: GlassContainer(
            borderRadius: 18,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                SizedBox(width: 44, child: leading),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 24),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
