import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';

import 'support/app_harness.dart';
import 'support/fake_backend.dart';

/// Steps 3 + 4 with the defaults (A1, no work areas).
Future<void> passLevelAndWork(WidgetTester tester) async {
  await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
  await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
}

void main() {
  testWidgets('fresh install, offline: 5 steps -> Home shows a word', (tester) async {
    await pumpOsgApp(tester);

    // Step 1: I speak - native names, system language (en) preselected.
    expect(find.text('I speak'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    expect(find.text("O'zbekcha"), findsOneWidget);
    expect(find.text('Русский'), findsOneWidget);
    expect(find.byKey(const Key('onb-back')), findsNothing);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));

    // Step 2: I want to learn - only the built-in pair, with an offline note.
    expect(find.text('I want to learn'), findsOneWidget);
    expect(find.text('Deutsch'), findsOneWidget);
    expect(find.text('500 words'), findsOneWidget);
    expect(find.textContaining("You're offline"), findsOneWidget);

    // Back works, then forward again.
    await tapAndSettle(tester, find.byKey(const Key('onb-back')));
    expect(find.text('I speak'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));

    // Step 3: level. Step 4: work areas (optional: "Skip" until one is picked).
    expect(find.text('Your level'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('level-B1')));
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    expect(find.text('Your work'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('topic-it')));
    expect(find.text('Skip'), findsNothing);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));

    // Step 5: preview with a real bundled word + permission + Start.
    expect(find.text("Here's how it works"), findsOneWidget);
    expect(find.text('🇩🇪 der Schlüssel'), findsNWidgets(2)); // notification + widget
    expect(find.text('500 words ready'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-allow')));
    expect(find.text('Notifications allowed'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-start')));

    // Home with today's word.
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Word right now'), findsOneWidget);
    expect(richTextContaining('🇩🇪 der'), findsWidgets);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('onboarding_done'), isTrue);
    expect(prefs.getString('lang_source'), 'en');
    expect(prefs.getString('lang_target'), 'de');
    expect(prefs.getString('learn_level'), 'B1');
    expect(prefs.getStringList('learn_topics'), ['it']);
    await unmountApp(tester);
  });

  testWidgets('offline, Uzbek phone: Home stays in Uzbek (words en-de until online)', (tester) async {
    await pumpOsgApp(tester, systemLanguage: 'uz');
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    await passLevelAndWork(tester);
    await tapAndSettle(tester, find.byKey(const Key('onb-start')));

    expect(find.text('Bugun'), findsOneWidget);
    expect(find.text('Today'), findsNothing);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang_source'), 'en');
    expect(prefs.getString('lang_source_wanted'), 'uz');
    await unmountApp(tester);
  });

  testWidgets('online: Uzbek phone -> uz-de downloads, interface turns Uzbek', (tester) async {
    final backend = FakeBackend()
      ..packs['en-de'] = FakePack(1, seedWordsTranslated('en'))
      ..packs['uz-de'] = FakePack(2, seedWordsTranslated('uz'));
    await pumpOsgApp(tester, backend: backend, systemLanguage: 'uz');

    // System language preselected and already used for the interface.
    expect(find.text('Men gapiraman'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    expect(find.text("Men o'rganmoqchiman"), findsOneWidget);
    expect(find.text("500 ta so'z"), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    expect(find.text('Darajangiz'), findsOneWidget);
    await passLevelAndWork(tester);

    expect(find.text('Bu qanday ishlaydi'), findsOneWidget);
    expect(find.text("500 ta so'z tayyor"), findsOneWidget);
    expect(find.text('uz:key'), findsNWidgets(2)); // real downloaded word in the preview
    expect(backend.requests.any((r) => r.url.path == '/content/words' && r.url.query == 'source=uz&target=de&topics=true'), isTrue);
    await tapAndSettle(tester, find.byKey(const Key('onb-start')));

    expect(find.text('Bugun'), findsOneWidget);
    expect(find.text('Asosiy'), findsOneWidget); // nav: Home
    expect(find.textContaining('uz:'), findsWidgets); // today's word, Uzbek translation
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang_source'), 'uz');
    await unmountApp(tester);
  });

  testWidgets('download fails -> falls back to en-de and says so', (tester) async {
    final backend = FakeBackend()
      ..packs['ru-de'] = FakePack(1, seedWordsTranslated('ru'))
      ..failing.add('/content/words');
    await pumpOsgApp(tester, backend: backend);

    await tapAndSettle(tester, find.byKey(const Key('lang-ru')));
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    expect(find.text('Я хочу учить'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-continue')));
    await passLevelAndWork(tester);

    expect(find.textContaining('Не удалось загрузить этот язык'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('onb-start')));

    // Words fall back to en-de, but the interface stays in the picked language.
    expect(find.text('Сегодня'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('lang_source'), 'en');
    expect(prefs.getString('lang_target'), 'de');
    expect(prefs.getString('lang_source_wanted'), 'ru');
    await unmountApp(tester);
  });

  testWidgets('existing install skips onboarding', (tester) async {
    await pumpOsgApp(tester, beforeStart: (db) async {
      await db.into(db.words).insert(WordsCompanion.insert(
            externalId: 'der_schluessel',
            term: 'Schlüssel',
            article: const Value('der'),
            translation: 'key',
            example: 'Wo ist mein Schlüssel?',
            category: 'Daily Life',
          ));
      await db.into(db.learnedWords).insert(LearnedWordsCompanion.insert(wordId: 1));
    });
    expect(find.text('I speak'), findsNothing);
    expect(find.text('Today'), findsOneWidget);
    await unmountApp(tester);
  });
}
