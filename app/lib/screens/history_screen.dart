import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/db/tables.dart';
import '../data/repository.dart';
import '../data/languages.dart';
import '../l10n/l10n.dart';
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/stat_tile.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late Future<_HistoryData> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_HistoryData> _load() async {
    final repo = context.read<Repository>();
    final logs = await repo.recentHistory();
    final words = {for (final w in await repo.allWords()) w.id: w};
    final reminders = {for (final r in await repo.allReminders()) r.id: r};
    final streak = await repo.currentStreakDays();

    final byDay = <DateTime, List<NotificationLog>>{};
    for (final log in logs) {
      final day = DateTime(log.scheduledAt.year, log.scheduledAt.month, log.scheduledAt.day);
      byDay.putIfAbsent(day, () => []).add(log);
    }
    final days = byDay.keys.toList()..sort((a, b) => b.compareTo(a));

    return _HistoryData(streak: streak, byDay: byDay, days: days, words: words, reminders: reminders);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HistoryData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final l = context.l10n;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          children: [
            Text(
              l.historyTitle,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(children: [StatTile(label: l.historyCurrentStreak, value: l.streakValue(data.streak))]),
            const SizedBox(height: 24),
            if (data.days.isEmpty)
              GlassContainer(
                child: Text(
                  l.historyEmpty,
                  style: const TextStyle(color: AppColors.textSecondary),
                ),
              )
            else
              ...data.days.map((day) => _DayGroup(
                    day: day,
                    logs: data.byDay[day]!,
                    words: data.words,
                    reminders: data.reminders,
                  )),
          ],
        );
      },
    );
  }
}

class _HistoryData {
  _HistoryData({
    required this.streak,
    required this.byDay,
    required this.days,
    required this.words,
    required this.reminders,
  });
  final int streak;
  final Map<DateTime, List<NotificationLog>> byDay;
  final List<DateTime> days;
  final Map<int, Word> words;
  final Map<int, Reminder> reminders;
}

class _DayGroup extends StatelessWidget {
  const _DayGroup({required this.day, required this.logs, required this.words, required this.reminders});

  final DateTime day;
  final List<NotificationLog> logs;
  final Map<int, Word> words;
  final Map<int, Reminder> reminders;

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GlassContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _label(context, day),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 10),
            ...logs.map((log) {
              final word = log.wordId != null ? words[log.wordId] : null;
              final reminder = log.reminderId != null ? reminders[log.reminderId] : null;
              final label = switch (log.kind) {
                NotificationKind.vocab =>
                  word != null ? '${flagOf(word.lang)} ${word.term} — ${word.translation}' : l.historyVocabulary,
                NotificationKind.reminder => reminder?.title ?? l.historyReminder,
                NotificationKind.combined =>
                  '${reminder?.title ?? l.historyReminder} + ${word?.term ?? l.historyWord}',
              };
              final isDone = log.deliveredAt != null && log.deliveredAt!.isBefore(DateTime.now());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(
                      isDone ? Icons.check_circle_rounded : Icons.schedule_rounded,
                      size: 16,
                      color: isDone ? AppColors.accent : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _label(BuildContext context, DateTime day) {
    final l = context.l10n;
    final today = DateTime.now();
    final t = DateTime(today.year, today.month, today.day);
    final diff = t.difference(day).inDays;
    if (diff == 0) return l.dayToday;
    if (diff == 1) return l.dayYesterday;
    return DateFormat.MMMEd(Localizations.localeOf(context).toLanguageTag()).format(day);
  }
}
