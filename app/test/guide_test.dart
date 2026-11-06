import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/app_harness.dart';

/// The tour loops animations, so pump in steps instead of pumpAndSettle.
Future<void> pumpFor(WidgetTester tester, [int ms = 1200]) async {
  for (var i = 0; i < ms ~/ 100; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> tapAndPump(WidgetTester tester, Finder f) async {
  await tester.tap(f);
  await pumpFor(tester, 800);
}

void main() {
  testWidgets('fresh install: coach marks, then the add-widget prompt, shown once', (tester) async {
    await pumpOsgApp(tester,
        prefs: {...donePrefs(), 'guide_pending': true}, enableGuide: true, settle: false);
    await pumpFor(tester, 3000);

    expect(find.text('Pull down to update'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('tour-next')));
    expect(find.text('Your word right now'), findsOneWidget);
    // Tapping anywhere on the dim also goes on.
    await tester.tapAt(const Offset(10, 10));
    await pumpFor(tester, 800);
    expect(find.text('All your words'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('tour-next')));
    expect(find.text('Your reminders'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('tour-next')));
    expect(find.text('Make it yours'), findsOneWidget);
    expect(find.text('Got it'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('tour-next')));

    // Tour done -> widget prompt (test host isn't Android: animated iOS guide).
    expect(find.text('Add the OSG widget'), findsOneWidget);
    expect(find.text('Tap + in the top corner'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('widget-later')));
    expect(find.text('Add the OSG widget'), findsNothing);
    expect(find.byKey(const Key('tour-overlay')), findsNothing);

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool('guide_pending'), isNull);
    await tester.pumpWidget(const SizedBox());
    await pumpFor(tester, 500);
  });

  testWidgets('existing install (no pending guide): no tour; Settings can start it', (tester) async {
    await pumpOsgApp(tester, prefs: donePrefs(), enableGuide: true, settle: false);
    await pumpFor(tester, 2000);
    expect(find.byKey(const Key('tour-overlay')), findsNothing);

    await tapAndPump(tester, find.text('Settings').last);
    await tester.scrollUntilVisible(find.byKey(const Key('settings-guide')), 200);
    await pumpFor(tester, 400);
    await tapAndPump(tester, find.byKey(const Key('settings-guide')));
    await pumpFor(tester, 1000);
    // Back on Home with the tour running.
    expect(find.text('Pull down to update'), findsOneWidget);
    await tapAndPump(tester, find.byKey(const Key('tour-skip')));
    await tapAndPump(tester, find.byKey(const Key('widget-later')));
    expect(find.byKey(const Key('tour-overlay')), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await pumpFor(tester, 500);
  });
}
