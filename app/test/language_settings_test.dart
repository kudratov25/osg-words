import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/languages.dart';
import 'package:osg_app/data/repository.dart';
import 'package:osg_app/services/content_sync.dart';
import 'package:osg_app/services/language_settings.dart';

import 'support/fake_backend.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase db;
  late Repository repo;
  late FakeBackend backend;
  late LanguageSettings settings;
  late int applied;

  final today = DateTime.now();
  final day = DateTime(today.year, today.month, today.day);

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
    backend = FakeBackend()
      ..packs['en-de'] = FakePack(1, seedWordsTranslated('en'))
      ..packs['uz-de'] = FakePack(1, seedWordsTranslated('uz'))
      ..packs['ru-de'] = FakePack(1, seedWordsTranslated('ru'))
      ..packs['uz-en'] = FakePack(1, [
        for (var i = 0; i < 6; i++) v2Word('en.word$i', 'word$i', 'so\'z$i', lang: 'en', article: null),
      ]);
    applied = 0;
    settings = LanguageSettings(repo, ContentSync(repo, client: backend.client, baseUrl: 'http://test'),
        onPairApplied: () async => applied++);
    await settings.load();
    await repo.seedWordsIfEmpty();
  });
  tearDown(() => db.close());

  test('fresh install: onboarding pending, built-in pair', () async {
    expect(settings.onboardingDone, isFalse);
    expect(settings.pair, builtInPair);
    expect(await repo.wordCount('de'), greaterThan(0));
  });

  test('bundled seed: v2 fields, en-de, original ids first', () async {
    final words = await repo.allWords();
    expect(words.length, await repo.wordCount('de'));
    final key = words.firstWhere((w) => w.externalId == 'der_schluessel');
    expect(key.id, 1);
    expect(key.term, 'Schlüssel');
    expect(key.lang, 'de');
    expect(key.translation, 'key');
    expect(key.exampleTranslation, isNotEmpty);
    // Running it again (every launch) adds nothing.
    await repo.seedWordsIfEmpty();
    expect((await repo.allWords()).length, words.length);
  });

  test('existing install (already learned a word) skips onboarding with en/de', () async {
    await db.into(db.learnedWords).insert(LearnedWordsCompanion.insert(wordId: 1));
    final again = LanguageSettings(repo, ContentSync(repo, baseUrl: ''));
    await again.load();
    expect(again.onboardingDone, isTrue);
    expect(again.pair, builtInPair);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang_source'), 'en');
    expect(prefs.getString('lang_target'), 'de');
    expect(prefs.getBool('onboarding_done'), isTrue);
  });

  test('existing install with only planned words also skips onboarding', () async {
    await repo.planWords(from: day);
    await db.delete(db.learnedWords).go();
    final again = LanguageSettings(repo, ContentSync(repo, baseUrl: ''));
    await again.load();
    expect(again.onboardingDone, isTrue);
  });

  test('switching source re-downloads translations in place and keeps progress', () async {
    final week = await repo.planWords(from: day);
    final todayIds = week[day]!.map((w) => w.id).toList();
    await repo.toggleFavorite(todayIds.first);
    final learnedBefore = await repo.totalWordsLearnedCount();

    expect(await settings.changePair(const LanguagePair('ru', 'de')), isTrue);
    expect(settings.pair.key, 'ru-de');
    expect(settings.locale.languageCode, 'ru');
    expect(applied, 1);

    final words = await repo.allWords();
    expect(words.every((w) => w.translation.startsWith('ru:')), isTrue);
    expect(await repo.totalWordsLearnedCount(), learnedBefore);
    expect(await repo.isFavorite(todayIds.first), isTrue);
    // Same target: the week's plan is untouched.
    final after = await repo.planWords(from: day);
    expect(after[day]!.map((w) => w.id), todayIds);
    expect(after[day]!.first.translation, startsWith('ru:'));
  });

  test('switching target replans with the new target and keeps progress', () async {
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isTrue);
    final week = await repo.planWords(from: day);
    final favorite = week[day]!.first;
    await repo.toggleFavorite(favorite.id);
    final learnedBefore = await repo.totalWordsLearnedCount();
    expect(learnedBefore, 3);

    expect(await settings.changePair(const LanguagePair('uz', 'en')), isTrue);
    final unrecordedLeft = await (db.select(db.wordPlans)..where((t) => t.recorded.equals(false))).get();
    expect(unrecordedLeft, isEmpty, reason: 'future German plans are dropped');

    final replanned = await repo.planWords(from: day);
    expect(replanned.values.expand((w) => w).every((w) => w.lang == 'en'), isTrue);
    expect(replanned[day]!.length, 3);
    expect(await repo.totalWordsLearnedCount(), greaterThanOrEqualTo(learnedBefore));
    expect(await repo.isFavorite(favorite.id), isTrue);
    expect(await repo.wordCount('de'), greaterThan(0), reason: 'German words stay on the phone');

    // And back: German words come back, progress still there.
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isTrue);
    final back = await repo.planWords(from: day);
    expect(back.values.expand((w) => w).every((w) => w.lang == 'de'), isTrue);
    final learned = await (db.select(db.learnedWords)..where((t) => t.wordId.equals(favorite.id))).getSingleOrNull();
    expect(learned, isNotNull);
  });

  test('switching target mid-day does not inflate words learned', () async {
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isTrue);
    await repo.planWords(from: day);
    final before = await repo.totalWordsLearnedCount();
    expect(before, 3);

    // Back and forth several times on the same day.
    for (final target in ['en', 'de', 'en', 'de', 'en']) {
      expect(await settings.changePair(LanguagePair('uz', target)), isTrue);
      final plan = await repo.planWords(from: day);
      expect(plan[day]!.every((w) => w.lang == target), isTrue);
      expect(await repo.totalWordsLearnedCount(), before, reason: 'after switching to $target');
    }
  });

  test('offline onboarding keeps the picked interface language, then switches once online', () async {
    backend.online = false;
    await settings.completeOnboarding(builtInPair, wantedSource: 'uz');
    expect(settings.pair, builtInPair, reason: 'words: bundled en-de');
    expect(settings.uiLanguage, 'uz');
    expect(settings.locale.languageCode, 'uz');
    expect(repo.uiLanguage, 'uz', reason: 'notification texts follow the interface');

    // Survives a restart.
    final reloaded = LanguageSettings(repo, ContentSync(repo, client: backend.client, baseUrl: 'http://test'));
    await reloaded.load();
    expect(reloaded.wantedSource, 'uz');
    expect(reloaded.uiLanguage, 'uz');

    // Still offline: nothing changes.
    expect(await settings.retryWantedPair(), isFalse);
    expect(settings.wantedSource, 'uz');

    // Online: switches to uz-de, translations in Uzbek, fallback cleared.
    backend.online = true;
    expect(await settings.retryWantedPair(), isTrue);
    expect(settings.pair, const LanguagePair('uz', 'de'));
    expect(settings.wantedSource, isNull);
    expect(settings.uiLanguage, 'uz');
    final key = (await repo.allWords()).firstWhere((w) => w.externalId == 'der_schluessel');
    expect(key.translation, isNot('key'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(wantedSourcePrefKey), isNull);
  });

  test('choosing a pair in Settings clears the offline fallback', () async {
    backend.online = false;
    await settings.completeOnboarding(builtInPair, wantedSource: 'ru');
    backend.online = true;
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isTrue);
    expect(settings.wantedSource, isNull);
    expect(settings.uiLanguage, 'uz');
  });

  test('failed download leaves the pair unchanged', () async {
    backend.online = false;
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isFalse);
    expect(settings.pair, builtInPair);
    expect(applied, 0);
    expect((await SharedPreferences.getInstance()).getString('lang_source'), isNull);
  });

  test('back to English offline restores the bundled translations', () async {
    expect(await settings.changePair(const LanguagePair('uz', 'de')), isTrue);
    expect((await repo.allWords()).first.translation, startsWith('uz:'));
    backend.online = false;
    expect(await settings.changePair(builtInPair), isTrue);
    final first = (await repo.allWords()).first;
    expect(first.translation, 'key');
    expect(await ContentSync.localPackPair(), 'en-de');
  });

  test('available pairs: built-in always, server pairs when online', () async {
    final online = await settings.availablePairs();
    expect(online.offline, isFalse);
    expect(online.pairs.map((p) => p.pair.key), containsAll(['en-de', 'uz-de', 'ru-de', 'uz-en']));
    expect(online.pairs.where((p) => p.pair.isBuiltIn).length, 1);

    backend.online = false;
    final offline = await settings.availablePairs();
    expect(offline.offline, isTrue);
    expect(offline.pairs.map((p) => p.pair.key), ['en-de']);
    expect(offline.pairs.single.words, await repo.wordCount('de'));
  });

  test('completing onboarding saves everything', () async {
    await settings.completeOnboarding(const LanguagePair('uz', 'de'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isTrue);
    expect(prefs.getString('lang_source'), 'uz');
    expect(repo.pair.key, 'uz-de');
  });

  test('planner ignores words of other targets', () async {
    await db.into(db.words).insert(WordsCompanion.insert(
          externalId: 'en.cat',
          lang: const Value('en'),
          term: 'cat',
          translation: 'mushuk',
          example: 'The cat sleeps.',
          category: 'Nature',
        ));
    final week = await repo.planWords(from: day);
    expect(week.values.expand((w) => w).any((w) => w.lang == 'en'), isFalse);
  });
}
