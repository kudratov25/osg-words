import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/main.dart';
import 'package:osg_app/services/auth_service.dart';

import 'fake_backend.dart';

/// Boots the whole app on an in-memory DB, no platform notifications.
/// With [backend] the app talks to that fake server; without it, offline.
Future<AppDatabase> pumpOsgApp(
  WidgetTester tester, {
  Map<String, Object> prefs = const {},
  FakeBackend? backend,
  String systemLanguage = 'en',
  TokenStore? tokenStore,
  Future<void> Function(AppDatabase db)? beforeStart,
  bool enableGuide = false,
  bool settle = true,
}) async {
  SharedPreferences.setMockInitialValues(prefs);
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  if (beforeStart != null) await beforeStart(db);
  await tester.pumpWidget(OsgApp(
    database: db,
    enableNotifications: false,
    enableNetwork: backend != null,
    httpClient: backend?.client,
    apiBaseUrl: backend == null ? null : 'http://test',
    tokenStore: tokenStore ?? MemoryTokenStore(),
    systemLanguage: systemLanguage,
    enableGuide: enableGuide,
  ));
  if (settle) await tester.pumpAndSettle();
  return db;
}

/// Prefs of an install that finished onboarding.
Map<String, Object> donePrefs({String source = 'en', String target = 'de'}) =>
    {'onboarding_done': true, 'lang_source': source, 'lang_target': target};

/// Taps a widget, scrolling it into view first.
Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Finder richTextContaining(String text) => find.textContaining(text, findRichText: true);

/// Unmounts the app so its database/timers are disposed inside the test.
Future<void> unmountApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pumpAndSettle();
}
