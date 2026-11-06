import 'package:flutter/material.dart';

import '../data/db/app_database.dart';
import '../l10n/l10n.dart';
import '../theme/glass_theme.dart';
import 'glass_container.dart';

/// "08:00" / "8:00 AM", following the interface language's convention.
String formatMinutes(BuildContext context, int minutes) =>
    MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60));

class ReminderTile extends StatelessWidget {
  const ReminderTile({
    required this.reminder,
    this.onTap,
    this.onToggle,
    super.key,
  });

  final Reminder reminder;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassContainer(
        borderRadius: 18,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            SizedBox(
              width: 76,
              child: Text(
                formatMinutes(context, reminder.timeMinutes),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.accent,
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(reminder.title,
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary)),
                  Text(repeatLabel(context.l10n, reminder.repeatType),
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
            if (onToggle != null)
              Switch(
                value: reminder.enabled,
                onChanged: onToggle,
                activeThumbColor: AppColors.accent,
              ),
          ],
        ),
      ),
    );
  }
}
