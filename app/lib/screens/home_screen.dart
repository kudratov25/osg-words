import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show DateFormat;
import 'package:provider/provider.dart';

import '../data/db/app_database.dart';
import '../data/db/tables.dart';
import '../data/repository.dart';
import '../notifications/recurrence.dart';
import '../services/content_sync.dart';
import '../notifications/scheduler.dart'
    show TodayWords, WidgetSlot, todayWords, wordTitle;
import '../l10n/l10n.dart';
import '../guide/guide_controller.dart' show GuideKeys;
import '../theme/glass_theme.dart';
import '../widgets/glass_container.dart';
import '../widgets/refresh_words.dart';
import '../widgets/reminder_tile.dart';
import '../widgets/stat_tile.dart';
import '../widgets/word_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<_HomeData> _future;

  /// Re-renders when the next word's time arrives while Home is open, so
  /// it switches together with the notification and the widget.
  Timer? _nextWordTimer;

  /// Reloads when fixed/new words arrive from the server.
  late final ContentSync _sync;

  @override
  void initState() {
    super.initState();
    _future = _load();
    _sync = context.read<ContentSync>()..addListener(_onWordsChanged);
  }

  @override
  void dispose() {
    _nextWordTimer?.cancel();
    _sync.removeListener(_onWordsChanged);
    super.dispose();
  }

  void _onWordsChanged() {
    if (mounted) _refresh();
  }

  void _scheduleNextWordRefresh(TodayWords words, DateTime now) {
    _nextWordTimer?.cancel();
    final next = words.nextAfter(now);
    if (next == null) return;
    _nextWordTimer = Timer(
      next.at.difference(now) + const Duration(seconds: 1),
      () {
        if (mounted) _refresh();
      },
    );
  }

  Future<_HomeData> _load() async {
    final repo = context.read<Repository>();
    final today = DateTime.now();

    final todaysWords = await repo.assignTodaysWords(today: today);
    final allReminders = await repo.allEnabledReminders();
    final words = todayWords(
      now: today,
      today: todaysWords,
      yesterday: await repo.yesterdaysWords(today: today),
      reminders: allReminders,
    );
    _scheduleNextWordRefresh(words, today);
    final todaysReminders =
        allReminders.where((r) => occursOn(r, today)).toList()
          ..sort((a, b) => a.timeMinutes.compareTo(b.timeMinutes));

    final nowMinutes = today.hour * 60 + today.minute;
    Reminder? upcoming;
    for (final r in todaysReminders) {
      if (r.timeMinutes >= nowMinutes) {
        upcoming = r;
        break;
      }
    }

    final wordsLearned = await repo.totalWordsLearnedCount();
    final streak = await repo.currentStreakDays();
    final history = await repo.historyForDay(today);
    final completedToday = history
        .where(
          (h) =>
              h.kind != NotificationKind.vocab &&
              h.deliveredAt != null &&
              h.deliveredAt!.isBefore(today),
        )
        .length;

    return _HomeData(
      words: words,
      todaysReminders: todaysReminders,
      upcoming: upcoming,
      wordsLearned: wordsLearned,
      streak: streak,
      completedToday: completedToday,
    );
  }

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_HomeData>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final data = snapshot.data!;
        final l = context.l10n;
        return RefreshIndicator(
          onRefresh: () async {
            await refreshWordsFromServer(context);
            if (mounted) _refresh();
          },
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              Column(
                key: GuideKeys.homeHeader,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    DateFormat.MMMMEEEEd(
                      Localizations.localeOf(context).toLanguageTag(),
                    ).format(DateTime.now()),
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    l.homeToday,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      StatTile(
                        label: l.statWordsLearned,
                        value: '${data.wordsLearned}',
                      ),
                      const SizedBox(width: 12),
                      StatTile(
                        label: l.statTodaysDone,
                        value: '${data.completedToday}',
                      ),
                      const SizedBox(width: 12),
                      StatTile(
                        label: l.statStreak,
                        value: l.streakValue(data.streak),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _SectionTitle(l.homeUpcomingReminder),
              const SizedBox(height: 10),
              if (data.upcoming != null)
                ReminderTile(reminder: data.upcoming!)
              else
                _EmptyNote(l.homeNothingLeft),
              const SizedBox(height: 24),
              _SectionTitle(l.homeTodaysSchedule),
              const SizedBox(height: 10),
              if (data.todaysReminders.isEmpty)
                _EmptyNote(l.homeNoRemindersToday)
              else
                ...data.todaysReminders.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: ReminderTile(reminder: r),
                  ),
                ),
              const SizedBox(height: 24),
              if (data.words.current == null) ...[
                _SectionTitle(l.homeWordRightNow),
                const SizedBox(height: 10),
                _EmptyNote(l.homeNoVocabulary),
              ] else ...[
                Row(
                  children: [
                    _SectionTitle(l.homeWordRightNow),
                    const Spacer(),
                    Text(
                      _currentLabel(l, data.words),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                KeyedSubtree(
                  key: GuideKeys.wordCard,
                  child: WordCard(word: data.words.current!.word),
                ),
                const SizedBox(height: 24),
                _SectionTitle(l.homeTodaysWords),
                const SizedBox(height: 10),
                _TodayWordsList(words: data.words, now: DateTime.now()),
              ],
            ],
          ),
        );
      },
    );
  }

  /// "since 12:00" / "from last night · next at 08:00".
  String _currentLabel(AppLocalizations l, TodayWords words) {
    if (!words.currentIsFromYesterday) {
      final at = words.current!.at;
      // First day (nothing from yesterday): before 08:00 the card already
      // shows today's first word - it hasn't arrived yet.
      return at.isAfter(DateTime.now())
          ? l.homeArrivesAt(_hhmm(at))
          : l.homeSince(_hhmm(at));
    }
    final next = words.nextAfter(DateTime.now());
    return next == null
        ? l.homeFromYesterday
        : l.homeFromLastNight(_hhmm(next.at));
  }
}

class _HomeData {
  _HomeData({
    required this.words,
    required this.todaysReminders,
    required this.upcoming,
    required this.wordsLearned,
    required this.streak,
    required this.completedToday,
  });

  final TodayWords words;
  final List<Reminder> todaysReminders;
  final Reminder? upcoming;
  final int wordsLearned;
  final int streak;
  final int completedToday;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.textSecondary,
        letterSpacing: 0.5,
      ),
    );
  }
}

class _EmptyNote extends StatelessWidget {
  const _EmptyNote(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.all(16),
      child: Text(text, style: const TextStyle(color: AppColors.textSecondary)),
    );
  }
}

String _hhmm(DateTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Today's three words by time. Arrived words show word + translation (the
/// current one marked "now") and open their full card when tapped; words
/// still to come only show their time, so Home never spoils a word before
/// its notification.
class _TodayWordsList extends StatelessWidget {
  const _TodayWordsList({required this.words, required this.now});
  final TodayWords words;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final current = words.currentIsFromYesterday ? null : words.current;
    return GlassContainer(
      borderRadius: 18,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: [
          for (var i = 0; i < words.slots.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.glassBorder),
            _row(
              context,
              words.slots[i],
              isCurrent: identical(words.slots[i], current),
            ),
          ],
        ],
      ),
    );
  }

  void _open(BuildContext context, WidgetSlot slot) {
    if (slot.at.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(context.l10n.homeNoPeeking(_hhmm(slot.at))),
            duration: const Duration(seconds: 2),
          ),
        );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      // A solid panel behind the handle + label, so they never sit
      // directly on top of the list underneath.
      backgroundColor: AppColors.backgroundGradientEnd,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textSecondary.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.only(left: 4, bottom: 10),
                child: Text(
                  context.l10n.homeSlotWord(_hhmm(slot.at)),
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              WordCard(word: slot.word),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(
    BuildContext context,
    WidgetSlot slot, {
    required bool isCurrent,
  }) {
    final arrived = !slot.at.isAfter(now);
    final l = context.l10n;
    return Semantics(
      button: true,
      label: arrived
          ? l.homeOpenWord(wordTitle(slot.word))
          : l.homeWordArriving(_hhmm(slot.at)),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _open(context, slot),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 52,
                child: Text(
                  _hhmm(slot.at),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isCurrent
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Expanded(
                child: arrived
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          WordTitle(
                            word: slot.word,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: isCurrent
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slot.word.translation,
                            style: TextStyle(
                              fontSize: 13,
                              color: isCurrent
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        l.homeArrivesAt(_hhmm(slot.at)),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
              ),
              if (isCurrent)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    l.homeNow,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.accent,
                    ),
                  ),
                )
              else if (!arrived)
                const Icon(
                  Icons.lock_clock_outlined,
                  size: 18,
                  color: AppColors.textSecondary,
                ),
              if (arrived)
                const Padding(
                  padding: EdgeInsets.only(left: 6),
                  child: Icon(
                    Icons.chevron_right,
                    size: 20,
                    color: AppColors.textSecondary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
