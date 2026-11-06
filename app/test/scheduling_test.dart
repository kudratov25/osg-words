import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/db/tables.dart';
import 'package:osg_app/data/repository.dart';
import 'package:osg_app/notifications/notification_service.dart';
import 'package:osg_app/notifications/recurrence.dart';
import 'package:osg_app/notifications/scheduler.dart';
import 'package:osg_app/notifications/widget_sync.dart';

// --- helpers -----------------------------------------------------------------

Reminder reminder({
  int id = 1,
  String title = 'Gym',
  String? description,
  int time = 19 * 60,
  RepeatType repeat = RepeatType.daily,
  DateTime? onDate,
  int? dayOfWeek,
  int? dayOfMonth,
  bool enabled = true,
}) =>
    Reminder(
      id: id,
      title: title,
      description: description,
      timeMinutes: time,
      repeatType: repeat,
      onDate: onDate,
      dayOfWeek: dayOfWeek,
      dayOfMonth: dayOfMonth,
      enabled: enabled,
      createdAt: DateTime(2026, 1, 1),
    );

Word word(int id) => Word(
      id: id,
      topics: '',
      externalId: 'w$id',
      lang: 'de',
      term: 'Wort$id',
      article: 'das',
      translation: 'word $id',
      example: 'Beispiel $id.',
      category: 'test',
      difficulty: 'beginner',
      createdAt: DateTime(2026, 1, 1),
    );

/// day -> 3 distinct words, for [days] days from [start].
Map<DateTime, List<Word>> plan(DateTime start, {int days = 7}) => {
      for (var i = 0; i < days; i++)
        DateTime(start.year, start.month, start.day + i): [word(i * 3 + 1), word(i * 3 + 2), word(i * 3 + 3)],
    };

class FakeNotifications implements NotificationService {
  final pending = <int, ({String title, String body, DateTime at})>{};
  final cancelled = <int>[];

  @override
  Future<Set<int>> pendingIds() async => pending.keys.toSet();

  @override
  Future<void> cancel(int id) async {
    cancelled.add(id);
    pending.remove(id);
  }

  @override
  Future<void> scheduleOneOff({required int id, required String title, required String body, required DateTime at}) async {
    pending[id] = (title: title, body: body, at: at);
  }

  /// What the phone would show by [until], in order.
  List<({String title, String body, DateTime at})> firedBetween(DateTime from, DateTime until) =>
      pending.values.where((n) => n.at.isAfter(from) && !n.at.isAfter(until)).toList()
        ..sort((a, b) => a.at.compareTo(b.at));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeWidgetSync extends WidgetSync {
  List<WidgetSlot> slots = [];
  @override
  Future<void> sync(List<WidgetSlot> slots) async => this.slots = slots;
}

Future<void> addWords(AppDatabase db, int count) async {
  for (var i = 1; i <= count; i++) {
    await db.into(db.words).insert(WordsCompanion.insert(
          externalId: 'w$i',
          term: 'Wort$i',
          article: const Value('das'),
          translation: 'word $i',
          example: 'Beispiel $i.',
          category: 'test',
        ));
  }
}

Future<int> addReminder(AppDatabase db, {int time = 19 * 60, RepeatType repeat = RepeatType.daily, String title = 'Gym'}) =>
    db.into(db.reminders).insert(RemindersCompanion.insert(title: title, timeMinutes: time, repeatType: Value(repeat)));

void main() {
  // Wed 4 Nov 2026, 07:00
  final wed = DateTime(2026, 11, 4, 7);

  // --- recurrence ---------------------------------------------------------------

  group('recurrence', () {
    test('daily: every day, strictly after from', () {
      final r = reminder(time: 7 * 60); // 07:00 - exactly "now" is excluded
      final occ = occurrencesBetween(r, wed, DateTime(2026, 11, 7));
      expect(occ, [DateTime(2026, 11, 5, 7), DateTime(2026, 11, 6, 7)]);
    });

    test('weekdays skips Saturday and Sunday', () {
      final r = reminder(repeat: RepeatType.weekdays);
      final occ = occurrencesBetween(r, wed, DateTime(2026, 11, 11));
      expect(occ.map((d) => d.weekday), [3, 4, 5, 1, 2]); // Wed Thu Fri Mon Tue
    });

    test('weekly on the given weekday', () {
      final r = reminder(repeat: RepeatType.weekly, dayOfWeek: DateTime.sunday);
      // until is exclusive (Nov 22 00:00), so Nov 22 19:00 is not included
      expect(occurrencesBetween(r, wed, DateTime(2026, 11, 22)), [DateTime(2026, 11, 8, 19), DateTime(2026, 11, 15, 19)]);
    });

    test('monthly on the 31st falls on the last day of shorter months', () {
      final r = reminder(repeat: RepeatType.monthly, dayOfMonth: 31, time: 9 * 60);
      final occ = occurrencesBetween(r, DateTime(2027, 1, 1), DateTime(2027, 5, 1));
      expect(occ, [DateTime(2027, 1, 31, 9), DateTime(2027, 2, 28, 9), DateTime(2027, 3, 31, 9), DateTime(2027, 4, 30, 9)]);
    });

    test('monthly on the 30th falls on Feb 29 in a leap year', () {
      final r = reminder(repeat: RepeatType.monthly, dayOfMonth: 30);
      expect(occursOn(r, DateTime(2028, 2, 29)), isTrue);
      expect(occursOn(r, DateTime(2028, 2, 28)), isFalse);
    });

    test('once: only on its date, nothing after it passed', () {
      final r = reminder(repeat: RepeatType.once, onDate: DateTime(2026, 11, 6), time: 10 * 60);
      expect(computeNextOccurrence(r, wed), DateTime(2026, 11, 6, 10));
      expect(computeNextOccurrence(r, DateTime(2026, 11, 6, 11)), isNull);
    });

    test('next occurrence agrees with occursOn', () {
      final r = reminder(repeat: RepeatType.weekly, dayOfWeek: DateTime.monday, time: 8 * 60);
      final next = computeNextOccurrence(r, wed)!;
      expect(next, DateTime(2026, 11, 9, 8));
      expect(occursOn(r, next), isTrue);
    });
  });

  // --- buildSchedule (pure) ------------------------------------------------------

  group('buildSchedule', () {
    test('7 days of words: 21 vocab notifications + nudge, no app open needed', () {
      final s = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: []);
      final vocab = s.notifications.where((n) => n.kind == NotificationKind.vocab).toList();
      expect(vocab.length, 21);
      expect(vocab.first.at, DateTime(2026, 11, 4, 8));
      expect(vocab.last.at, DateTime(2026, 11, 10, 18));
      final nudge = s.notifications.last;
      expect(nudge.id, nudgeNotificationId);
      expect(nudge.at, DateTime(2026, 11, 11, 9));
    });

    test('daily reminder fires every day of the week', () {
      final s = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: [reminder(time: 19 * 60 + 30)]);
      final gym = s.notifications.where((n) => n.kind == NotificationKind.reminder).toList();
      expect(gym.map((n) => n.at.day), [4, 5, 6, 7, 8, 9, 10]);
      expect(gym.every((n) => n.at.hour == 19 && n.at.minute == 30), isTrue);
    });

    test('past items today are skipped', () {
      final s = buildSchedule(now: DateTime(2026, 11, 4, 12, 30), wordsByDay: plan(wed), reminders: []);
      final today = s.notifications.where((n) => n.at.day == 4).toList();
      expect(today.map((n) => n.at.hour), [18]);
    });

    test('reminder near a slot merges into one combined notification at the reminder time', () {
      final s = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: [reminder(time: 12 * 60 + 10, description: 'Lunch walk')]);
      final day1 = s.notifications.where((n) => n.at.day == 4).toList();
      expect(day1.map((n) => n.kind), [NotificationKind.vocab, NotificationKind.combined, NotificationKind.vocab]);
      final combined = day1[1];
      expect(combined.at, DateTime(2026, 11, 4, 12, 10));
      expect(combined.word!.id, 2); // the 12:00 slot's word
      expect(combined.body, contains('Lunch walk'));
      expect(combined.body, contains('das Wort2'));
    });

    test('merge decision does not depend on whether the slot time has passed', () {
      final r = [reminder(time: 8 * 60 + 10)];
      final before = buildSchedule(now: DateTime(2026, 11, 4, 7), wordsByDay: plan(wed), reminders: r);
      final after = buildSchedule(now: DateTime(2026, 11, 4, 8, 5), wordsByDay: plan(wed), reminders: r);
      final b = before.notifications.firstWhere((n) => n.kind == NotificationKind.combined);
      final a = after.notifications.firstWhere((n) => n.kind == NotificationKind.combined);
      expect(a.id, b.id);
      expect(a.word!.id, b.word!.id);
    });

    test('disabled reminders and other weekdays are not scheduled', () {
      final s = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: [
        reminder(id: 1, enabled: false),
        reminder(id: 2, repeat: RepeatType.weekly, dayOfWeek: DateTime.saturday, time: 10 * 60),
      ]);
      final rem = s.notifications.where((n) => n.reminderId != null).toList();
      expect(rem.length, 1);
      expect(rem.single.at, DateTime(2026, 11, 7, 10));
    });

    test('ids are unique and stable across refreshes', () {
      final r = [reminder(id: 1), reminder(id: 2, time: 8 * 60 + 5), reminder(id: 3, repeat: RepeatType.weekdays, time: 21 * 60)];
      final s1 = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: r);
      final s2 = buildSchedule(now: wed.add(const Duration(minutes: 30)), wordsByDay: plan(wed), reminders: r);
      final ids = s1.notifications.map((n) => n.id).toList();
      expect(ids.toSet().length, ids.length);
      expect(s2.notifications.map((n) => n.id).toSet(), s1.notifications.map((n) => n.id).toSet());
      expect(ids.every((id) => id > 0 && id < 0x7FFFFFFF), isTrue);
    });

    test('caps at the iOS limit, earliest first, and the nudge comes after', () {
      final many = [for (var i = 1; i <= 15; i++) reminder(id: i, time: 6 * 60 + i)];
      final s = buildSchedule(now: wed.subtract(const Duration(hours: 2)), wordsByDay: plan(wed), reminders: many);
      expect(s.notifications.length, maxPendingNotifications + 1);
      final real = s.notifications.where((n) => n.id != nudgeNotificationId).toList();
      for (var i = 1; i < real.length; i++) {
        expect(real[i].at.isBefore(real[i - 1].at), isFalse);
      }
      expect(s.notifications.last.id, nudgeNotificationId);
      expect(s.notifications.last.at.isAfter(real.last.at), isTrue);
    });

    test('widget slots match notification times, including merged ones', () {
      final s = buildSchedule(now: wed, wordsByDay: plan(wed), reminders: [reminder(time: 18 * 60 - 10)]);
      final day1 = s.widgetSlots.where((w) => w.at.day == 4).toList();
      expect(day1.map((w) => w.at), [DateTime(2026, 11, 4, 8), DateTime(2026, 11, 4, 12), DateTime(2026, 11, 4, 17, 50)]);
      expect(day1.map((w) => w.word.id), [1, 2, 3]);
      expect(s.widgetSlots.length, 21);
    });
  });

  // --- Home screen "word right now" (same rule as the widget) ------------------

  group('todayWords', () {
    final today = [word(1), word(2), word(3)];
    final yesterday = [word(7), word(8), word(9)];
    TodayWords at(int h, int m, {List<Reminder> reminders = const []}) =>
        todayWords(now: DateTime(2026, 11, 4, h, m), today: today, yesterday: yesterday, reminders: reminders);

    test('before 08:00 it is yesterday\'s last word', () {
      final w = at(7, 30);
      expect(w.current!.word.id, 9);
      expect(w.currentIsFromYesterday, isTrue);
      expect(w.nextAfter(DateTime(2026, 11, 4, 7, 30))!.at, DateTime(2026, 11, 4, 8));
    });

    test('after each slot time it is that slot\'s word', () {
      expect(at(8, 0).current!.word.id, 1);
      expect(at(11, 59).current!.word.id, 1);
      expect(at(12, 0).current!.word.id, 2);
      expect(at(19, 43).current!.word.id, 3); // the bug: Home showed word 1 here
      expect(at(19, 43).currentIsFromYesterday, isFalse);
      expect(at(19, 43).nextAfter(DateTime(2026, 11, 4, 19, 43)), isNull);
    });

    test('merged reminder: word switches at the reminder time, like the notification', () {
      final r = [reminder(time: 12 * 60 + 10)];
      expect(at(12, 5, reminders: r).current!.word.id, 1);
      expect(at(12, 10, reminders: r).current!.word.id, 2);
      expect(at(12, 10, reminders: r).slots.map((s) => s.at.minute), [0, 10, 0]);
    });

    test('Home and widget agree at every minute of the day', () {
      final r = [reminder(time: 17 * 60 + 50)];
      final day = DateTime(2026, 11, 4);
      final widgetSlots = [
        yesterdaySlot(day, yesterday)!,
        ...buildSchedule(now: day, wordsByDay: {day: today}, reminders: r, horizonDays: 1).widgetSlots,
      ];
      for (var m = 0; m < 24 * 60; m += 7) {
        final now = day.add(Duration(minutes: m));
        final widgetWord = widgetSlots.lastWhere((s) => !s.at.isAfter(now)).word.id;
        final home = todayWords(now: now, today: today, yesterday: yesterday, reminders: r);
        expect(home.current!.word.id, widgetWord, reason: 'at $now');
      }
    });

    test('first day ever (no yesterday): before 08:00 shows the first word', () {
      final w = todayWords(now: DateTime(2026, 11, 4, 6), today: today, yesterday: const [], reminders: const []);
      expect(w.current!.word.id, 1);
      expect(w.currentIsFromYesterday, isFalse);
    });
  });

  // --- word planning (DB) -----------------------------------------------------

  group('planWords', () {
    late AppDatabase db;
    late Repository repo;
    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
      await addWords(db, 30);
    });
    tearDown(() => db.close());

    final today = DateTime(2026, 11, 4);

    test('plans 7 days x 3 distinct words, new words first', () async {
      final p = await repo.planWords(from: today);
      expect(p.length, 7);
      final ids = p.values.expand((w) => w.map((x) => x.id)).toList();
      expect(ids, List.generate(21, (i) => i + 1));
      for (final day in p.values) {
        expect(day.map((w) => w.id).toSet().length, 3);
      }
    });

    test('plans are stable: a later call returns the same words', () async {
      final a = await repo.planWords(from: today);
      final b = await repo.planWords(from: today.add(const Duration(days: 2)));
      for (final day in b.keys.where(a.containsKey)) {
        expect(b[day]!.map((w) => w.id), a[day]!.map((w) => w.id));
      }
    });

    test('only arrived days count as learned', () async {
      await repo.planWords(from: today);
      expect(await repo.totalWordsLearnedCount(), 3);
      await repo.planWords(from: today.add(const Duration(days: 3)));
      expect(await repo.totalWordsLearnedCount(), 12); // 4 days x 3
    });

    test('keeps today\'s words from the previous app version', () async {
      for (final id in [7, 9, 11]) {
        await db.into(db.learnedWords).insert(
              LearnedWordsCompanion.insert(wordId: id, firstSeenDate: Value(today), lastShownDate: Value(today)),
            );
      }
      final p = await repo.planWords(from: today);
      expect(p[today]!.map((w) => w.id), [7, 9, 11]);
    });

    test('small word bank: cycles least recently used, never twice a day', () async {
      final small = AppDatabase.forTesting(NativeDatabase.memory());
      await addWords(small, 4);
      final p = await Repository(small).planWords(from: today);
      for (final day in p.values) {
        expect(day.map((w) => w.id).toSet().length, 3);
      }
      await small.close();
    });
  });

  // --- full refresh with fake phone ------------------------------------------

  group('NotificationScheduler.refreshAll', () {
    late AppDatabase db;
    late Repository repo;
    late FakeNotifications phone;
    late FakeWidgetSync widget;
    late NotificationScheduler scheduler;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = Repository(db);
      phone = FakeNotifications();
      widget = FakeWidgetSync();
      scheduler = NotificationScheduler(repo, phone, widget);
      await addWords(db, 60);
    });
    tearDown(() => db.close());

    test('THE BUG: daily reminder keeps firing for a week without opening the app', () async {
      await addReminder(db, time: 21 * 60);
      await scheduler.refreshAll(now: wed); // opened once, Wednesday morning
      final fired = phone.firedBetween(wed, DateTime(2026, 11, 11)).where((n) => n.title == 'Gym').toList();
      expect(fired.map((n) => n.at.day), [4, 5, 6, 7, 8, 9, 10]);
    });

    test('word notifications come every day of the week too', () async {
      await scheduler.refreshAll(now: wed);
      final words = phone.firedBetween(wed, DateTime(2026, 11, 11)).where((n) => n.title.startsWith('🇩🇪 das')).toList();
      expect(words.length, 21);
    });

    test('widget shows the same word as each notification', () async {
      await scheduler.refreshAll(now: wed);
      final vocab = phone.pending.values.where((n) => n.title.startsWith('🇩🇪 das')).toList();
      for (final n in vocab) {
        final slot = widget.slots.lastWhere((w) => !w.at.isAfter(n.at));
        expect(n.title, '🇩🇪 ${wordTitle(slot.word)}', reason: 'at ${n.at}');
        expect(slot.at, n.at);
      }
    });

    test('cancels stale notifications, including ids from the old app version', () async {
      phone.pending[100001] = (title: 'old reminder', body: '', at: wed);
      phone.pending[800000] = (title: 'old vocab', body: '', at: wed);
      await scheduler.refreshAll(now: wed);
      expect(phone.cancelled, containsAll([100001, 800000]));
    });

    test('deleting a reminder removes all its notifications and future history', () async {
      final id = await addReminder(db, time: 21 * 60);
      await scheduler.refreshAll(now: wed);
      expect(phone.pending.values.where((n) => n.title == 'Gym'), isNotEmpty);

      await repo.deleteReminder(id);
      await scheduler.refreshAll(now: wed);
      expect(phone.pending.values.where((n) => n.title == 'Gym'), isEmpty);
      final logs = await db.select(db.notificationLogs).get();
      expect(logs.where((l) => l.kind == NotificationKind.reminder), isEmpty);
    });

    test('editing a reminder time moves every occurrence', () async {
      final id = await addReminder(db, time: 21 * 60);
      await scheduler.refreshAll(now: wed);
      await repo.upsertReminder(const RemindersCompanion(timeMinutes: Value(20 * 60)), id: id);
      await scheduler.refreshAll(now: wed);
      final gym = phone.pending.values.where((n) => n.title == 'Gym').toList();
      expect(gym.length, 7);
      expect(gym.every((n) => n.at.hour == 20), isTrue);
    });

    test('history does not show future notifications', () async {
      await addReminder(db, time: 21 * 60);
      await scheduler.refreshAll(now: wed);
      final history = await repo.recentHistory();
      expect(history.every((h) => !h.scheduledAt.isAfter(DateTime.now())), isTrue);
    });

    test('concurrent refreshes do not conflict', () async {
      await addReminder(db, time: 21 * 60);
      await Future.wait([scheduler.refreshAll(now: wed), scheduler.refreshAll(now: wed), scheduler.refreshAll(now: wed)]);
      final logs = await db.select(db.notificationLogs).get();
      final reminderLogs = logs.where((l) => l.kind == NotificationKind.reminder).toList();
      expect(reminderLogs.length, 7);
    });

    test('widget payload is valid JSON with times', () async {
      await scheduler.refreshAll(now: wed);
      final decoded = jsonDecode(WidgetSync.encodePayload(widget.slots)) as Map<String, dynamic>;
      final slots = decoded['slots'] as List;
      expect(slots.length, 21);
      expect((slots.first as Map)['at'], DateTime(2026, 11, 4, 8).millisecondsSinceEpoch);
    });
  });
}
