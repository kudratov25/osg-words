import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/levels.dart';
import 'package:osg_app/data/repository.dart';
import 'package:osg_app/services/learning_prefs.dart';

Map<String, dynamic> w(String id, String level, [List<String> topics = const []]) => {
      'external_id': id,
      'lang': 'de',
      'term': id,
      'article': null,
      'translation': 'tr-$id',
      'example': '$id.',
      'category': 'Work',
      'difficulty': 'beginner',
      'level': level,
      'topics': topics,
    };

void main() {
  late AppDatabase db;
  late Repository repo;
  final day = DateTime(2026, 11, 10);

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  Future<void> bank() => repo.mergeContentPack([
        for (var i = 0; i < 10; i++) w('a1_$i', 'A1'),
        for (var i = 0; i < 10; i++) w('a2_$i', 'A2'),
        for (var i = 0; i < 10; i++) w('b1_$i', 'B1'),
        for (var i = 0; i < 10; i++) w('b2_$i', 'B2'),
        for (var i = 0; i < 5; i++) w('it_b1_$i', 'B1', ['it']),
        for (var i = 0; i < 5; i++) w('care_a2_$i', 'A2', ['care']),
      ]);

  String lvl(Word x) => x.level!;

  test('A2 user: two A2 words and one B1 word a day, never A1 while A2+ is left', () async {
    await bank();
    repo.level = 'A2';
    final week = await repo.planWords(from: day, days: 3);
    for (final words in week.values) {
      expect(words.map(lvl).toList(), ['A2', 'A2', 'B1']);
    }
  });

  test('topic words only for users who picked that topic; slot 1 prefers one', () async {
    await bank();
    repo.level = 'B1';
    repo.topics = {'it'};
    final week = await repo.planWords(from: day, days: 4);
    final all = week.values.expand((x) => x).toList();
    expect(all.where((x) => x.externalId.startsWith('care_')), isEmpty);
    for (final words in week.values) {
      expect(parseTopics(words[1].topics), {'it'});
      expect(parseTopics(words[0].topics), isEmpty);
      expect(words[0].level, 'B1');
      expect(words[2].level, 'B2');
    }
  });

  test('no topics picked: topic words are never planned', () async {
    await bank();
    repo.level = 'A1';
    final plan = await repo.planWords(from: day, days: 7);
    final all = plan.values.expand((x) => x);
    expect(all.where((x) => parseTopics(x.topics).isNotEmpty), isEmpty);
  });

  test('C1 user with no C1 words still gets the highest words available', () async {
    await bank();
    repo.level = 'C1';
    final words = (await repo.planWords(from: day, days: 1))[day]!;
    expect(words.length, 3);
    expect(words.every((x) => x.level == 'B2'), isTrue);
  });

  test('pool at/above level used up: falls back to lower levels instead of stopping', () async {
    await repo.mergeContentPack([w('b2_0', 'B2'), w('a1_0', 'A1'), w('a1_1', 'A1'), w('a1_2', 'A1')]);
    repo.level = 'B2';
    final words = (await repo.planWords(from: day, days: 1))[day]!;
    expect(words.length, 3);
    expect(words.first.externalId, 'b2_0');
  });

  test('words without a level (pre-2.1 download) rank by difficulty', () {
    expect(levelRank(null, 'beginner'), 0);
    expect(levelRank(null, 'intermediate'), 2);
    expect(levelRank(null, 'advanced'), 3);
    expect(levelRank('B2'), 3);
  });

  test('LearningPrefs: saved, mirrored into the planner, future days replanned', () async {
    await bank();
    var changed = 0;
    final prefs = LearningPrefs(repo, onChanged: () async => changed++);
    await prefs.load();
    expect(repo.level, 'A1');
    final before = await repo.planWords(from: day, days: 3);
    expect(before[day.add(const Duration(days: 2))]!.first.level, 'A1');

    await prefs.update(level: 'B1', topics: {'it', 'astronaut'});
    expect(changed, 1);
    expect(repo.level, 'B1');
    expect(repo.topics, {'it'});
    final stored = await SharedPreferences.getInstance();
    expect(stored.getString(levelPrefKey), 'B1');
    expect(stored.getStringList(topicsPrefKey), ['it']);

    // dropUnrecordedPlansFrom(now) uses the real clock: replanning from a
    // future day shows the new level.
    await repo.dropUnrecordedPlansFrom(day);
    final after = await repo.planWords(from: day.add(const Duration(days: 1)), days: 1);
    expect(after.values.single.first.level, 'B1');

    // Same values: nothing happens.
    await prefs.update(level: 'B1', topics: {'it'});
    expect(changed, 1);

    final reloaded = LearningPrefs(Repository(db));
    await reloaded.load();
    expect(reloaded.level, 'B1');
    expect(reloaded.topics, {'it'});
  });

  test("changing level replaces today's words right away", () async {
    await bank();
    repo.level = 'A1';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final before = (await repo.planWords(from: today, days: 1))[today]!;
    expect(before.every((x) => x.level == 'A1' || x.level == 'A2'), isTrue);
    final learnedBefore = await repo.totalWordsLearnedCount();

    final prefs = LearningPrefs(repo);
    await prefs.update(level: 'B2');
    final after = (await repo.planWords(from: today, days: 1))[today]!;
    expect(after.length, 3);
    expect(after.every((x) => levelRank(x.level) >= levelRank('B2')), isTrue);
    expect(after.map((x) => x.id).toSet().intersection(before.map((x) => x.id).toSet()), isEmpty);
    // Learned count: old words undone, new ones counted - not doubled.
    expect(await repo.totalWordsLearnedCount(), learnedBefore);
  });
}
