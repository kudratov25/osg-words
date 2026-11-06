import 'package:drift/drift.dart' show Value;

import '../data/db/app_database.dart';
import '../data/db/tables.dart';
import '../data/languages.dart';
import '../data/repository.dart';
import '../l10n/l10n.dart';
import 'notification_service.dart';
import 'recurrence.dart';
import 'widget_sync.dart';

/// Fixed daily vocabulary notification times: 08:00 / 12:00 / 18:00.
const List<int> vocabSlotMinutes = [8 * 60, 12 * 60, 18 * 60];

/// A reminder within this many minutes of a vocab slot on the same day is
/// merged with it into one notification (at the reminder's time).
const int mergeWindowMinutes = 15;

/// How many days ahead everything is scheduled. Notifications keep coming
/// for this long even if the app is never opened; every app open extends
/// the window again.
const int scheduleHorizonDays = 7;

/// iOS keeps at most 64 pending local notifications per app (extra ones
/// are silently dropped). Stay safely below, leaving room for the nudge.
const int maxPendingNotifications = 60;

// Notification ids are derived from the date, so the same occurrence
// always gets the same id across refreshes and different days never
// collide (the old per-slot ids 100000+/800000+ get cancelled as stale):
//   vocab:              300_000_000 + dayNumber * 10 + slot
//   reminder/combined:  400_000_000 + (dayNumber % 100) * 100_000 + reminderId
//   "open the app" nudge: 299_999_999
const int _vocabIdBase = 300000000;
const int _reminderIdBase = 400000000;
const int nudgeNotificationId = 299999999;

/// Days since 1970-01-01 for a local calendar date.
int dayNumber(DateTime day) => DateTime.utc(day.year, day.month, day.day).millisecondsSinceEpoch ~/ 86400000;

int vocabNotificationId(DateTime day, int slot) => _vocabIdBase + dayNumber(day) * 10 + slot;

int reminderNotificationId(DateTime day, int reminderId) =>
    _reminderIdBase + (dayNumber(day) % 100) * 100000 + (reminderId % 100000);

/// One notification the schedule wants on the device.
class PlannedNotification {
  PlannedNotification({
    required this.id,
    required this.at,
    required this.title,
    required this.body,
    required this.kind,
    this.reminderId,
    this.word,
    this.slot,
  });

  final int id;
  final DateTime at;
  final String title;
  final String body;

  /// null for the "open the app" nudge (not logged in History).
  final NotificationKind? kind;
  final int? reminderId;
  final Word? word;

  /// Vocab slot index the word belongs to (vocab + combined only).
  final int? slot;
}

/// When each day's words appear (notification time - the reminder's time
/// for merged slots) - what the Home/Lock Screen widget switches on.
class WidgetSlot {
  WidgetSlot(this.at, this.word);
  final DateTime at;
  final Word word;
}

class Schedule {
  Schedule(this.notifications, this.widgetSlots);

  /// Sorted by time, already capped to [maxPendingNotifications] + nudge.
  final List<PlannedNotification> notifications;

  /// Every planned day's word slots (including ones already past today),
  /// sorted by time.
  final List<WidgetSlot> widgetSlots;
}

/// Builds the complete schedule from [now] for the planned days in
/// [wordsByDay] (day -> words in slot order). Pure: no I/O, so it's fully
/// unit-tested. Texts come from [strings] (the source language's ARB
/// strings, English by default); the nudge carries [target]'s flag.
Schedule buildSchedule({
  required DateTime now,
  required Map<DateTime, List<Word>> wordsByDay,
  required List<Reminder> reminders,
  int horizonDays = scheduleHorizonDays,
  int maxPending = maxPendingNotifications,
  AppLocalizations? strings,
  String target = 'de',
}) {
  final l = strings ?? stringsFor('en');
  final today = DateTime(now.year, now.month, now.day);
  final all = <PlannedNotification>[];
  final widgetSlots = <WidgetSlot>[];

  for (var i = 0; i < horizonDays; i++) {
    final day = DateTime(today.year, today.month, today.day + i);
    final words = wordsByDay[day] ?? const <Word>[];
    final enabled = reminders.where((r) => r.enabled && occursOn(r, day)).toList()
      ..sort((a, b) => a.timeMinutes != b.timeMinutes ? a.timeMinutes.compareTo(b.timeMinutes) : a.id.compareTo(b.id));

    // Merge: each slot takes the first not-yet-merged reminder within the
    // window. Decided independently of `now`, so a merge stays the same
    // whether the app is opened before or after the slot time.
    final mergedSlotOf = <int, int>{}; // reminderId -> slot
    for (var slot = 0; slot < vocabSlotMinutes.length && slot < words.length; slot++) {
      for (final r in enabled) {
        if (mergedSlotOf.containsKey(r.id)) continue;
        if ((r.timeMinutes - vocabSlotMinutes[slot]).abs() <= mergeWindowMinutes) {
          mergedSlotOf[r.id] = slot;
          break;
        }
      }
    }
    final mergedSlots = mergedSlotOf.values.toSet();

    for (final r in enabled) {
      final at = fireTimeOn(r, day);
      final slot = mergedSlotOf[r.id];
      if (slot != null) {
        final word = words[slot];
        widgetSlots.add(WidgetSlot(at, word));
        all.add(PlannedNotification(
          id: reminderNotificationId(day, r.id),
          at: at,
          title: r.title,
          body: _combinedBody(l, r, word),
          kind: NotificationKind.combined,
          reminderId: r.id,
          word: word,
          slot: slot,
        ));
      } else {
        all.add(PlannedNotification(
          id: reminderNotificationId(day, r.id),
          at: at,
          title: r.title,
          body: _reminderBody(l, r),
          kind: NotificationKind.reminder,
          reminderId: r.id,
        ));
      }
    }

    for (var slot = 0; slot < vocabSlotMinutes.length && slot < words.length; slot++) {
      if (mergedSlots.contains(slot)) continue;
      final word = words[slot];
      final at = DateTime(day.year, day.month, day.day).add(Duration(minutes: vocabSlotMinutes[slot]));
      widgetSlots.add(WidgetSlot(at, word));
      all.add(PlannedNotification(
        id: vocabNotificationId(day, slot),
        at: at,
        title: flaggedTitle(word),
        // " — " rather than only a line break: a collapsed Android
        // notification joins the lines with a plain space ("doctor Ich habe
        // morgen…"), so the translation and the example ran together.
        body: '${word.translation} — ${word.example}',
        kind: NotificationKind.vocab,
        word: word,
        slot: slot,
      ));
    }
  }

  final upcoming = all.where((n) => n.at.isAfter(now)).toList()..sort((a, b) => a.at.compareTo(b.at));
  final kept = upcoming.take(maxPending).toList();

  // Last notification: if the app isn't opened before the schedule runs
  // out, ask the user to open it (which extends the schedule again).
  final lastDay = kept.isEmpty ? today : DateTime(kept.last.at.year, kept.last.at.month, kept.last.at.day);
  var nudgeAt = DateTime(lastDay.year, lastDay.month, lastDay.day + 1, 9);
  if (kept.isNotEmpty && !nudgeAt.isAfter(kept.last.at)) {
    nudgeAt = kept.last.at.add(const Duration(minutes: 30));
  }
  kept.add(PlannedNotification(
    id: nudgeNotificationId,
    at: nudgeAt,
    title: '${flagOf(target)} ${l.notifNudgeTitle}',
    body: l.notifNudgeBody,
    kind: null,
  ));

  widgetSlots.sort((a, b) => a.at.compareTo(b.at));
  return Schedule(kept, widgetSlots);
}

/// Yesterday's last word, placed at its slot time - what the widget (and
/// the Home screen) show before today's first word arrives.
WidgetSlot? yesterdaySlot(DateTime today, List<Word> yesterday) {
  if (yesterday.isEmpty) return null;
  final slot = (yesterday.length - 1).clamp(0, vocabSlotMinutes.length - 1);
  return WidgetSlot(
    DateTime(today.year, today.month, today.day - 1).add(Duration(minutes: vocabSlotMinutes[slot])),
    yesterday.last,
  );
}

/// Today's words as the user experiences them, for the Home screen.
class TodayWords {
  TodayWords({required this.slots, required this.current, required this.currentIsFromYesterday});

  /// Today's word slots in order; `at` is when each one's notification
  /// fires (a merged reminder's time, if merged) - same times the widget
  /// switches on.
  final List<WidgetSlot> slots;

  /// The word showing right now on the widget: the latest slot whose time
  /// has passed; before today's first slot, yesterday's last word.
  final WidgetSlot? current;
  final bool currentIsFromYesterday;

  /// The next of today's slots still to come, if any.
  WidgetSlot? nextAfter(DateTime now) {
    for (final s in slots) {
      if (s.at.isAfter(now)) return s;
    }
    return null;
  }
}

/// Same rule as the widgets (OsgWidgetProvider.kt / OsgWidget.swift), built
/// from the same [buildSchedule] times, so the app and the widget always
/// show the same word.
TodayWords todayWords({
  required DateTime now,
  required List<Word> today,
  required List<Word> yesterday,
  required List<Reminder> reminders,
}) {
  final day = DateTime(now.year, now.month, now.day);
  final slots = buildSchedule(now: now, wordsByDay: {day: today}, reminders: reminders, horizonDays: 1).widgetSlots;
  WidgetSlot? current;
  for (final s in slots) {
    if (!s.at.isAfter(now)) current = s;
  }
  if (current != null) return TodayWords(slots: slots, current: current, currentIsFromYesterday: false);
  final prev = yesterdaySlot(day, yesterday);
  return TodayWords(
    slots: slots,
    current: prev ?? (slots.isEmpty ? null : slots.first),
    currentIsFromYesterday: prev != null,
  );
}

String wordTitle(Word word) => word.article != null && word.article!.isNotEmpty ? '${word.article} ${word.term}' : word.term;

/// "🇩🇪 der Schlüssel" - the word with its language's flag, as shown in
/// notifications, the widget and the word card.
String flaggedTitle(Word word) {
  final flag = flagOf(word.lang);
  return flag.isEmpty ? wordTitle(word) : '$flag ${wordTitle(word)}';
}

String _reminderBody(AppLocalizations l, Reminder r) =>
    r.description == null || r.description!.isEmpty ? l.notifReminder : '${l.notifTodaysGoal}\n${r.description}';

String _combinedBody(AppLocalizations l, Reminder r, Word word) {
  final goal = r.description == null || r.description!.isEmpty ? '' : '${l.notifTodaysGoal}\n${r.description}\n\n';
  return '$goal'
      '${l.notifTodaysWord}\n'
      '${wordTitle(word)} - ${word.translation}\n'
      '${word.example}';
}

/// Applies [buildSchedule] to the device: plans the week's words, cancels
/// notifications that are no longer wanted (incl. ones from older app
/// versions), schedules the rest, refreshes History's future entries and
/// the widget.
///
/// Call on every app open/resume and after any reminder change. Safe to
/// call concurrently - runs are serialized.
class NotificationScheduler {
  NotificationScheduler(this._repo, this._notifications, [WidgetSync? widgetSync])
      : _widgetSync = widgetSync ?? WidgetSync();

  final Repository _repo;
  final NotificationService _notifications;
  final WidgetSync _widgetSync;

  Future<void> _running = Future.value();

  Future<void> refreshAll({DateTime? now}) {
    final run = _running.then((_) => _refresh(now ?? DateTime.now()));
    _running = run.catchError((_) {});
    return run;
  }

  /// A reminder was disabled or deleted: rebuilding drops its notifications.
  Future<void> cancelReminder(int reminderId) => refreshAll();

  Future<void> _refresh(DateTime now) async {
    final today = DateTime(now.year, now.month, now.day);
    final wordsByDay = await _repo.planWords(from: today, days: scheduleHorizonDays);
    final reminders = await _repo.allEnabledReminders();
    final schedule = buildSchedule(
      now: now,
      wordsByDay: wordsByDay,
      reminders: reminders,
      strings: stringsFor(_repo.uiLanguage),
      target: _repo.pair.target,
    );

    // Before today's first slot the widget keeps showing yesterday's last
    // word rather than revealing today's first one early.
    final prev = yesterdaySlot(today, await _repo.yesterdaysWords(today: today));
    final widgetSlots = [
      ?prev,
      ...schedule.widgetSlots,
    ];
    // Widget first: it's what the user sees most, and needs no permission.
    await _widgetSync.sync(widgetSlots);

    final wanted = {for (final n in schedule.notifications) n.id};
    for (final id in await _notifications.pendingIds()) {
      if (!wanted.contains(id)) await _notifications.cancel(id);
    }
    for (final n in schedule.notifications) {
      await _notifications.scheduleOneOff(id: n.id, title: n.title, body: n.body, at: n.at);
    }

    await _repo.replaceFutureLogs(now, [
      for (final n in schedule.notifications)
        if (n.kind != null)
          NotificationLogsCompanion.insert(
            kind: n.kind!,
            reminderId: Value(n.reminderId),
            wordId: Value(n.word?.id),
            scheduledAt: n.at,
            deliveredAt: Value(n.at),
          ),
    ]);
  }
}
