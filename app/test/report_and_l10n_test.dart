import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/db/tables.dart';
import 'package:osg_app/data/languages.dart';
import 'package:osg_app/l10n/l10n.dart';
import 'package:osg_app/notifications/scheduler.dart';
import 'package:osg_app/notifications/widget_sync.dart';
import 'package:osg_app/services/feedback_api.dart';

import 'support/app_harness.dart';
import 'support/fake_backend.dart';

Word _word({String lang = 'de', String? article = 'der', String term = 'Schlüssel'}) => Word(
      id: 1,
      topics: '',
      externalId: 'der_schluessel',
      lang: lang,
      term: term,
      article: article,
      translation: 'kalit',
      example: 'Wo ist mein Schlüssel?',
      exampleTranslation: 'Kalitim qayerda?',
      category: 'Daily Life',
      difficulty: 'beginner',
      createdAt: DateTime(2026, 1, 1),
    );

void main() {
  group('FeedbackApi', () {
    setUp(() => SharedPreferences.setMockInitialValues({'telemetry_device_id': 'dev-1'}));

    test('posts device id, pair, kind and trimmed note', () async {
      final backend = FakeBackend();
      final api = FeedbackApi(client: backend.client, baseUrl: 'http://test');
      final result = await api.reportWordIssue(
        externalId: 'der_schluessel',
        pair: const LanguagePair('uz', 'de'),
        kind: WordIssueKind.wrongArticle,
        note: '  should be die  ',
      );
      expect(result, ReportResult.sent);
      expect(backend.reports.single, {
        'device_id': 'dev-1',
        'external_id': 'der_schluessel',
        'source': 'uz',
        'target': 'de',
        'kind': 'wrong_article',
        'note': 'should be die',
      });
    });

    test('empty note is left out; 429 / offline / unconfigured are reported', () async {
      final backend = FakeBackend()..reportLimit = 1;
      final api = FeedbackApi(client: backend.client, baseUrl: 'http://test');
      Future<ReportResult> send() => api.reportWordIssue(
          externalId: 'x', pair: builtInPair, kind: WordIssueKind.other, note: '   ');
      expect(await send(), ReportResult.sent);
      expect(backend.reports.single.containsKey('note'), isFalse);
      expect(await send(), ReportResult.tooMany);
      backend.online = false;
      expect(await send(), ReportResult.offline);
      expect(
          await FeedbackApi(baseUrl: '').reportWordIssue(externalId: 'x', pair: builtInPair, kind: WordIssueKind.other),
          ReportResult.offline);
    });
  });

  testWidgets('word card: report a mistake -> bottom sheet -> sent', (tester) async {
    final backend = FakeBackend()..packs['en-de'] = FakePack(1, seedWordsTranslated('en'));
    await pumpOsgApp(tester, backend: backend, prefs: donePrefs());

    final flag = find.byIcon(Icons.outlined_flag_rounded).first;
    await tapAndSettle(tester, flag);
    expect(find.text('Report a mistake'), findsWidgets);
    await tapAndSettle(tester, find.text('Wrong article'));
    await tester.enterText(find.byType(TextField), 'typo');
    await tapAndSettle(tester, find.text('Send'));

    expect(find.text("Thanks! We'll check this word."), findsOneWidget);
    expect(backend.reports.single['kind'], 'wrong_article');
    expect(backend.reports.single['source'], 'en');
    expect(backend.reports.single['target'], 'de');
    expect(backend.reports.single['note'], 'typo');
    await unmountApp(tester);
  });

  testWidgets('word card: report while offline says so', (tester) async {
    await pumpOsgApp(tester, prefs: donePrefs());
    await tapAndSettle(tester, find.byIcon(Icons.outlined_flag_rounded).first);
    await tapAndSettle(tester, find.text('Wrong translation'));
    await tapAndSettle(tester, find.text('Send'));
    expect(find.text("You're offline — please try again later."), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('word card shows the example translation and coloured German article', (tester) async {
    await pumpOsgApp(tester, prefs: donePrefs(), beforeStart: (db) async {
      await db.into(db.words).insert(WordsCompanion.insert(
            externalId: 'der_schluessel',
            term: 'Schlüssel',
            article: const Value('der'),
            translation: 'key',
            example: 'Wo ist mein Schlüssel?',
            exampleTranslation: const Value('Where is my key?'),
            category: 'Daily Life',
          ));
    });
    await tapAndSettle(tester, find.text('Vocabulary'));
    expect(find.text('Where is my key?'), findsOneWidget);
    expect(richTextContaining('🇩🇪 der Schlüssel'), findsOneWidget);
    await unmountApp(tester);
  });

  group('localization', () {
    for (final (source, home, nav, settings) in [
      ('uz', 'Bugun', 'Asosiy', 'Sozlamalar'),
      ('ru', 'Сегодня', 'Главная', 'Настройки'),
    ]) {
      testWidgets('$source interface renders', (tester) async {
        await pumpOsgApp(tester, prefs: donePrefs(source: source));
        expect(find.text(home), findsOneWidget);
        expect(find.text(nav), findsOneWidget);
        await tapAndSettle(tester, find.text(settings));
        expect(find.text(stringsFor(source).settingsLanguages), findsOneWidget);
        expect(find.text(stringsFor(source).settingsTelemetryTitle), findsOneWidget);
        await unmountApp(tester);
      });
    }

    test('non-widget lookup + category labels', () {
      expect(stringsFor('uz').notifTodaysGoal, 'Bugungi maqsad:');
      expect(stringsFor('ru').notifReminder, 'Напоминание');
      expect(stringsFor('de').notifReminder, 'Reminder'); // unsupported -> English
      expect(categoryLabel(stringsFor('uz'), 'Common Verbs'), "Asosiy fe'llar");
      expect(categoryLabel(stringsFor('ru'), 'Weather'), 'Погода');
      expect(categoryLabel(stringsFor('en'), 'Nature'), 'Nature');
      expect(categoryLabel(stringsFor('ru'), 'Unknown'), 'Unknown');
      for (final key in categoryKeys) {
        expect(categoryLabel(stringsFor('uz'), key), isNot(key), reason: key);
      }
    });

    test('notifications use the source language and the target flag', () {
      final now = DateTime(2026, 11, 4, 7);
      final day = DateTime(2026, 11, 4);
      final reminder = Reminder(
        id: 1,
        title: 'Gym',
        description: 'Leg day',
        timeMinutes: 8 * 60 + 5,
        repeatType: RepeatType.daily,
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final plain = Reminder(
        id: 2,
        title: 'Read',
        timeMinutes: 21 * 60,
        repeatType: RepeatType.daily,
        enabled: true,
        createdAt: DateTime(2026, 1, 1),
      );
      final words = [_word(), _word(term: 'Tür', article: 'die'), _word(term: 'Brot', article: 'das')];
      final s = buildSchedule(
        now: now,
        wordsByDay: {day: words},
        reminders: [reminder, plain],
        horizonDays: 1,
        strings: stringsFor('ru'),
        target: 'de',
      );
      final combined = s.notifications.firstWhere((n) => n.title == 'Gym');
      expect(combined.body, startsWith('Цель на сегодня:\nLeg day'));
      expect(combined.body, contains('Слово дня:'));
      expect(s.notifications.firstWhere((n) => n.title == 'Read').body, 'Напоминание');
      expect(s.notifications.firstWhere((n) => n.kind == NotificationKind.vocab).title, '🇩🇪 die Tür');
      expect(s.notifications.last.title, '🇩🇪 Новые слова уже ждут');

      final english = buildSchedule(
        now: now,
        wordsByDay: {day: [_word(lang: 'en', article: null, term: 'apple')]},
        reminders: const [],
        horizonDays: 1,
        strings: stringsFor('uz'),
        target: 'en',
      );
      expect(english.notifications.first.title, '🇬🇧 apple');
      expect(english.notifications.last.title, "🇬🇧 Keyingi so'zlaringiz kutmoqda");
      expect(WidgetSync.encodePayload(english.widgetSlots), contains('"title":"🇬🇧 apple"'));
    });
  });

  testWidgets('Settings -> Languages: switch source, interface follows', (tester) async {
    final backend = FakeBackend()
      ..packs['en-de'] = FakePack(1, seedWordsTranslated('en'))
      ..packs['ru-de'] = FakePack(1, seedWordsTranslated('ru'));
    await pumpOsgApp(tester, backend: backend, prefs: donePrefs());
    await tapAndSettle(tester, find.text('Settings'));
    await tapAndSettle(tester, find.byKey(const Key('settings-source')));
    await tapAndSettle(tester, find.byKey(const Key('pick-ru')));

    expect(find.text('Языки обновлены.'), findsOneWidget);
    expect(find.text('Настройки'), findsWidgets);
    expect((await SharedPreferences.getInstance()).getString('lang_source'), 'ru');
    await tapAndSettle(tester, find.text('Главная'));
    expect(find.textContaining('ru:'), findsWidgets);
    await unmountApp(tester);
  });
}
