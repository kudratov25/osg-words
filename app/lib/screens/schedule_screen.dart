import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import '../notifications/scheduler.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/reminder_tile.dart';
import 'reminder_form_screen.dart';

class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final repo = context.read<Repository>();
    final scheduler = context.read<NotificationScheduler>();
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.accent,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ReminderFormScreen()),
        ),
        child: const Icon(Icons.add, color: AppColors.background),
      ),
      body: StreamBuilder<List<Reminder>>(
        stream: repo.watchReminders(),
        builder: (context, snapshot) {
          final reminders = snapshot.data ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Text(
                context.l10n.scheduleTitle,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              if (reminders.isEmpty)
                GlassContainer(
                  child: Text(
                    context.l10n.scheduleEmpty,
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                )
              else
                ...reminders.map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: ReminderTile(
                        reminder: r,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => ReminderFormScreen(existing: r)),
                        ),
                        onToggle: (enabled) async {
                          await repo.setReminderEnabled(r.id, enabled);
                          await scheduler.refreshAll();
                        },
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }
}
