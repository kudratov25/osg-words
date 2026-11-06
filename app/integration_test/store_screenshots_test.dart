// Store screenshots: drives a fresh install through onboarding and the main
// screens against the live backend, taking a screenshot of each.
//
//   flutter drive --driver=test_driver/integration_test.dart \
//     --target=integration_test/store_screenshots_test.dart \
//     --dart-define=API_BASE_URL=https://osg.kudratov.uz \
//     --dart-define=SHOT_LANG=en -d <simulator>
//
// SHOT_LANG: en | ru | uz - the language picked in "I speak" (= interface).
// Set the simulator's language to the same one so step 1 matches too.
// Needs a fresh install (onboarding not done yet). Finders use keys and
// icons only, so the flow works in every interface language.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:osg_app/guide/guide_controller.dart' show GuideKeys;
import 'package:osg_app/main.dart' as app;

const shotLang = String.fromEnvironment('SHOT_LANG', defaultValue: 'en');

void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  /// Pumps until [finder] matches (network + animations), up to [timeout].
  Future<void> waitFor(WidgetTester tester, Finder finder, {Duration timeout = const Duration(seconds: 40)}) async {
    final end = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(end)) {
      await tester.pump(const Duration(milliseconds: 250));
      if (finder.evaluate().isNotEmpty) return;
    }
    throw StateError('Timed out waiting for $finder');
  }

  /// Lets animations finish without pumpAndSettle (spinners never settle).
  Future<void> settle(WidgetTester tester, [int ms = 1500]) async {
    for (var i = 0; i < ms ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> shot(WidgetTester tester, String name) async {
    await settle(tester);
    await binding.takeScreenshot('${shotLang}_$name');
  }

  testWidgets('store screenshots', (tester) async {
    app.main();
    await waitFor(tester, find.byKey(const Key('onb-continue')));
    await tester.tap(find.byKey(const Key('lang-$shotLang')));
    await shot(tester, '01_onboarding_speak');

    await tester.tap(find.byKey(const Key('onb-continue')));
    await waitFor(tester, find.byKey(const Key('lang-de')));
    await settle(tester, 800);

    await tester.tap(find.byKey(const Key('onb-continue')));
    await waitFor(tester, find.byKey(const Key('level-A2')));
    await tester.tap(find.byKey(const Key('level-A2')));
    await shot(tester, '02_onboarding_level');

    await tester.tap(find.byKey(const Key('onb-continue')));
    await waitFor(tester, find.byKey(const Key('topic-it')));
    await tester.tap(find.byKey(const Key('topic-it')));
    await settle(tester, 400);
    await tester.tap(find.byKey(const Key('topic-office')));
    await shot(tester, '03_onboarding_work');

    await tester.tap(find.byKey(const Key('onb-continue')));
    await waitFor(tester, find.byKey(const Key('onb-start')));
    await settle(tester, 5000); // word download + preview

    await tester.tap(find.byKey(const Key('onb-start')));
    // First-run guide: coach marks, then the widget prompt.
    await waitFor(tester, find.byKey(const Key('tour-next')));
    await tester.tap(find.byKey(const Key('tour-next'))); // -> word card
    await settle(tester, 1500);
    await shot(tester, '04_guide');
    await tester.tap(find.byKey(const Key('tour-skip')));
    await waitFor(tester, find.byKey(const Key('widget-later')));
    await settle(tester, 2600); // iOS guide: show its step 2
    await shot(tester, '07_add_widget');
    await tester.tap(find.byKey(const Key('widget-later')));
    await waitFor(tester, find.byKey(GuideKeys.wordCard));
    await shot(tester, '05_home');

    await tester.tap(find.byIcon(Icons.menu_book_rounded));
    await waitFor(tester, find.byType(TabBar));
    await shot(tester, '06_vocabulary');

    await tester.tap(find.byIcon(Icons.outlined_flag_rounded).first);
    await waitFor(tester, find.byType(TextField));
    await shot(tester, '08_report');
    await tester.tapAt(const Offset(20, 120)); // close the sheet
    await settle(tester);
  });
}
