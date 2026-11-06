import 'dart:io';

import 'package:drift/drift.dart' show OpeningDetails, OrderingTerm, QueryExecutor, QueryExecutorUser;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/languages.dart';
import 'package:osg_app/data/repository.dart';

/// Exact DDL the v2 app (schemaVersion 2) created, dumped from a real v2
/// database. v1 is the same without word_plans.
const _v1Tables = [
  '''CREATE TABLE "reminders" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "title" TEXT NOT NULL, "description" TEXT NULL, "time_minutes" INTEGER NOT NULL, "repeat_type" TEXT NOT NULL DEFAULT 'daily', "on_date" INTEGER NULL, "day_of_week" INTEGER NULL, "day_of_month" INTEGER NULL, "enabled" INTEGER NOT NULL DEFAULT 1 CHECK ("enabled" IN (0, 1)), "next_occurrence" INTEGER NULL, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''',
  '''CREATE TABLE "words" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "external_id" TEXT NOT NULL UNIQUE, "german" TEXT NOT NULL, "article" TEXT NULL, "translation" TEXT NOT NULL, "example" TEXT NOT NULL, "pronunciation" TEXT NULL, "category" TEXT NOT NULL, "difficulty" TEXT NOT NULL DEFAULT 'beginner', "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)))''',
  '''CREATE TABLE "favorite_words" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "word_id" INTEGER NOT NULL REFERENCES words (id) ON DELETE CASCADE, "created_at" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), UNIQUE ("word_id"))''',
  '''CREATE TABLE "learned_words" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "word_id" INTEGER NOT NULL REFERENCES words (id) ON DELETE CASCADE, "first_seen_date" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "last_shown_date" INTEGER NOT NULL DEFAULT (CAST(strftime('%s', CURRENT_TIMESTAMP) AS INTEGER)), "times_shown" INTEGER NOT NULL DEFAULT 1, UNIQUE ("word_id"))''',
  '''CREATE TABLE "notification_logs" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "kind" TEXT NOT NULL, "reminder_id" INTEGER NULL REFERENCES reminders (id) ON DELETE SET NULL, "word_id" INTEGER NULL REFERENCES words (id) ON DELETE SET NULL, "scheduled_at" INTEGER NOT NULL, "delivered_at" INTEGER NULL)''',
];
const _wordPlansTable =
    '''CREATE TABLE "word_plans" ("id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, "day" INTEGER NOT NULL, "slot" INTEGER NOT NULL, "word_id" INTEGER NOT NULL REFERENCES words (id) ON DELETE CASCADE, "recorded" INTEGER NOT NULL DEFAULT 0 CHECK ("recorded" IN (0, 1)), UNIQUE ("day", "slot"))''';

int _epoch(DateTime d) => d.millisecondsSinceEpoch ~/ 1000;

final _today = DateTime(2026, 11, 4);

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('osg_migration'));
  tearDown(() => dir.deleteSync(recursive: true));

  for (final version in [1, 2]) {
    test('v$version database upgrades to v4 with all data kept', () async {
      final file = File('${dir.path}/osg.sqlite');
      await _seedOldFile(file, version: version);

      final db = AppDatabase.file(file);
      final repo = Repository(db);

      final words = await (db.select(db.words)..orderBy([(t) => OrderingTerm.asc(t.id)])).get();
      expect(words.map((w) => w.term), ['Schlüssel', 'Tür', 'laufen', 'Brot']);
      expect(words.every((w) => w.lang == 'de'), isTrue);
      expect(words.every((w) => w.exampleTranslation == null), isTrue);
      expect(words.first.article, 'der');
      expect(words.first.translation, 'key');

      final learned = await db.select(db.learnedWords).get();
      expect(learned.length, 2);
      expect(learned.firstWhere((l) => l.wordId == 1).timesShown, 3);
      expect(await repo.isFavorite(2), isTrue);
      expect((await repo.allReminders()).single.title, 'Gym');
      expect((await db.select(db.notificationLogs).get()).single.wordId, 1);

      final plans = await db.select(db.wordPlans).get();
      expect(plans.length, version >= 2 ? 4 : 0);

      // An upgraded install counts as existing (skips onboarding)...
      expect(await repo.hasLearningActivity(), isTrue);
      // ...and keeps planning German words, including the old plans.
      repo.pair = builtInPair;
      final week = await repo.planWords(from: _today);
      if (version >= 2) {
        expect(week[_today]!.first.term, 'laufen');
        expect(week[_today.add(const Duration(days: 1))]!.first.term, 'Brot');
      }
      expect(week[_today]!.length, 3);

      // New v3 columns are writable.
      await repo.mergeContentPack([
        {
          'external_id': 'der_schluessel',
          'lang': 'de',
          'term': 'Schlüssel',
          'article': 'der',
          'translation': 'kalit',
          'example': 'Wo ist mein Schlüssel?',
          'example_translation': 'Kalitim qayerda?',
          'category': 'Daily Life',
          'level': 'A2',
          'topics': ['retail', 'office'],
        },
      ]);
      final key = (await repo.allWords()).firstWhere((w) => w.externalId == 'der_schluessel');
      expect(key.id, 1);
      expect(key.translation, 'kalit');
      expect(key.exampleTranslation, 'Kalitim qayerda?');
      // v4 columns: level + topics.
      expect(key.level, 'A2');
      expect(key.topics, 'office,retail');
      final other = (await repo.allWords()).firstWhere((w) => w.externalId != 'der_schluessel');
      expect(other.level, isNull);
      expect(other.topics, '');
      await db.close();

      // Reopening the migrated file is a no-op upgrade.
      final again = AppDatabase.file(file);
      expect((await again.select(again.words).get()).length, 4);
      final userVersion = await again.customSelect('PRAGMA user_version').getSingle();
      expect(userVersion.data.values.single, 4);
      await again.close();
    });
  }
}

/// Writes an old-version database file with raw SQL (the old DDL above +
/// words, progress, favourites, reminders, history and, for v2, plans),
/// then closes it before the new app opens it.
Future<void> _seedOldFile(File file, {required int version}) async {
  final executor = NativeDatabase(file, setup: (db) {
    for (final ddl in [..._v1Tables, if (version >= 2) _wordPlansTable]) {
      db.execute(ddl);
    }
    db.execute("INSERT INTO words (external_id, german, article, translation, example, category, difficulty) VALUES "
        "('der_schluessel', 'Schlüssel', 'der', 'key', 'Wo ist mein Schlüssel?', 'Daily Life', 'beginner'), "
        "('die_tuer', 'Tür', 'die', 'door', 'Bitte mach die Tür zu.', 'Daily Life', 'beginner'), "
        "('laufen', 'laufen', NULL, 'to run', 'Ich laufe jeden Morgen.', 'Common Verbs', 'beginner'), "
        "('das_brot', 'Brot', 'das', 'bread', 'Das Brot ist frisch.', 'Food', 'beginner')");
    final yesterday = _epoch(_today.subtract(const Duration(days: 1)));
    db.execute('INSERT INTO learned_words (word_id, first_seen_date, last_shown_date, times_shown) VALUES '
        '(1, $yesterday, $yesterday, 3), (2, $yesterday, $yesterday, 1)');
    db.execute('INSERT INTO favorite_words (word_id) VALUES (2)');
    db.execute("INSERT INTO reminders (title, time_minutes, repeat_type) VALUES ('Gym', 1140, 'daily')");
    db.execute("INSERT INTO notification_logs (kind, word_id, scheduled_at, delivered_at) VALUES "
        "('vocab', 1, $yesterday, $yesterday)");
    if (version >= 2) {
      final t = _epoch(_today);
      final tomorrow = _epoch(_today.add(const Duration(days: 1)));
      db.execute('INSERT INTO word_plans (day, slot, word_id, recorded) VALUES '
          '($yesterday, 0, 1, 1), ($yesterday, 1, 2, 1), ($t, 0, 3, 0), ($tomorrow, 0, 4, 0)');
    }
    db.execute('PRAGMA user_version = $version');
  });
  // NativeDatabase opens lazily: open it once so `setup` runs. The user
  // reports the old version, so drift leaves user_version untouched.
  await executor.ensureOpen(_OldAppUser(version));
  await executor.close();
}

class _OldAppUser implements QueryExecutorUser {
  _OldAppUser(this.schemaVersion);
  @override
  final int schemaVersion;
  @override
  Future<void> beforeOpen(QueryExecutor executor, OpeningDetails details) async {}
}
