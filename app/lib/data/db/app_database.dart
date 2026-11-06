import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Reminders, Words, FavoriteWords, LearnedWords, NotificationLogs, WordPlans])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Opens a specific database file (migration tests).
  AppDatabase.file(File file) : super(NativeDatabase(file));

  /// Used by widget tests to run against an in-memory database instead of
  /// a real file, so tests don't depend on path_provider's platform channel.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          // v2: week-ahead word planning.
          if (from < 2) await m.createTable(wordPlans);
          // v3: language pairs - words get a target language, `german`
          // becomes the language-neutral `term`, plus the example's
          // translation. Existing words are all German.
          if (from < 3) {
            await m.addColumn(words, words.lang);
            await m.renameColumn(words, 'german', words.term);
            await m.addColumn(words, words.exampleTranslation);
          }
          // v4: CEFR level + job-area topics (filled by the next sync).
          if (from < 4) {
            await m.addColumn(words, words.level);
            await m.addColumn(words, words.topics);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'osg.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
