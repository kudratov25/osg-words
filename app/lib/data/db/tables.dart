import 'package:drift/drift.dart';

/// Reminder repeat types. Stored as their [name] string in the DB.
enum RepeatType { once, daily, weekdays, weekly, monthly }

/// Notification delivery type, used by [NotificationLogs] for History.
enum NotificationKind { reminder, vocab, combined }

class Reminders extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();

  /// Time of day the reminder fires, stored as total minutes since midnight
  /// (0-1439). Kept separate from date fields so recurrence rules apply
  /// against "today at this time" regardless of repeat type.
  IntColumn get timeMinutes => integer()();

  TextColumn get repeatType =>
      textEnum<RepeatType>().withDefault(const Constant('daily'))();

  /// Only used when repeatType == once: the specific calendar date.
  DateTimeColumn get onDate => dateTime().nullable()();

  /// Only used when repeatType == weekly: 1 (Monday) - 7 (Sunday).
  IntColumn get dayOfWeek => integer().nullable()();

  /// Only used when repeatType == monthly: 1-31.
  IntColumn get dayOfMonth => integer().nullable()();

  BoolColumn get enabled => boolean().withDefault(const Constant(true))();

  /// Cached next fire time, recomputed by the recurrence engine whenever
  /// the app opens or a reminder is created/edited. Avoids recomputing
  /// recurrence math every time we just need "what's due next".
  DateTimeColumn get nextOccurrence => dateTime().nullable()();

  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class Words extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Stable id from the backend content pack, used to dedupe on sync.
  TextColumn get externalId => text().unique()();

  /// Target language of the word (`de`, `en`) - see lib/data/languages.dart.
  TextColumn get lang => text().withDefault(const Constant('de'))();

  /// The word itself in the target language (was `german` before v3).
  TextColumn get term => text()();
  TextColumn get article => text().nullable()();

  /// Translation into the current source language. Replaced in place when
  /// the source language changes (the row id - and so progress - is kept).
  TextColumn get translation => text()();
  TextColumn get example => text()();
  TextColumn get exampleTranslation => text().nullable()();
  TextColumn get pronunciation => text().nullable()();
  TextColumn get category => text()();
  TextColumn get difficulty => text().withDefault(const Constant('beginner'))();

  /// CEFR level A1..C1 (v4). Null for words downloaded before 2.1.
  TextColumn get level => text().nullable()();

  /// Job-area keys, comma-separated (v4); empty = general word.
  TextColumn get topics => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
}

class FavoriteWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId}
      ];
}

class LearnedWords extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();
  DateTimeColumn get firstSeenDate =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get lastShownDate =>
      dateTime().withDefault(currentDateAndTime)();
  IntColumn get timesShown => integer().withDefault(const Constant(1))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {wordId}
      ];
}

/// Delivery log for both reminder and vocab notifications, used to drive
/// the History screen and to debug missed/merged notifications. Kept
/// separate from LearnedWords, which tracks learning state, not delivery.
class NotificationLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get kind => textEnum<NotificationKind>()();

  /// Reminder id when kind is reminder/combined.
  IntColumn get reminderId =>
      integer().nullable().references(Reminders, #id, onDelete: KeyAction.setNull)();

  /// Word id when kind is vocab/combined.
  IntColumn get wordId =>
      integer().nullable().references(Words, #id, onDelete: KeyAction.setNull)();

  DateTimeColumn get scheduledAt => dateTime()();
  DateTimeColumn get deliveredAt => dateTime().nullable()();
}

/// The words planned for each day's vocab slots, decided up to a week in
/// advance so notifications, the widget and the app all show the same
/// word for the same slot. A day's plan never changes once made.
///
/// [recorded] flips to true once that day has arrived and its words were
/// counted into [LearnedWords] - future plans don't count as "learned".
class WordPlans extends Table {
  IntColumn get id => integer().autoIncrement()();

  /// Local calendar date (midnight).
  DateTimeColumn get day => dateTime()();

  /// Index into the vocab slot times (0 = 08:00, 1 = 12:00, 2 = 18:00).
  IntColumn get slot => integer()();

  IntColumn get wordId =>
      integer().references(Words, #id, onDelete: KeyAction.cascade)();

  BoolColumn get recorded => boolean().withDefault(const Constant(false))();

  @override
  List<Set<Column>> get uniqueKeys => [
        {day, slot}
      ];
}
