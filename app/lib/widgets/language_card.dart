import 'package:flutter/material.dart';

import '../data/languages.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// Big glass card with a flag and the language's name written in that
/// language - readable before the user can read the app's language.
/// Used by onboarding and Settings -> Languages.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    required this.language,
    required this.selected,
    required this.onTap,
    this.subtitle,
    super.key,
  });

  final Language language;
  final bool selected;
  final VoidCallback onTap;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: language.nativeName,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: selected ? AppColors.accent : Colors.transparent, width: 2),
            boxShadow: selected
                ? [BoxShadow(color: AppColors.accent.withValues(alpha: 0.25), blurRadius: 18)]
                : const [],
          ),
          child: GlassContainer(
            borderRadius: 22,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Row(
              children: [
                Text(language.flag, style: const TextStyle(fontSize: 34)),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        language.nativeName,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(subtitle!, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      ],
                    ],
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 180),
                  opacity: selected ? 1 : 0,
                  child: const Icon(Icons.check_circle_rounded, color: AppColors.accent, size: 26),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
