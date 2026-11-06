import 'dart:convert';

import 'package:home_widget/home_widget.dart';

import 'scheduler.dart' show WidgetSlot, flaggedTitle;

/// App Group shared between the Runner app and the iOS WidgetKit extension
/// (must match the group id in both targets' entitlements), and the
/// SharedPreferences bridge home_widget uses on Android.
const String widgetGroupId = 'group.uz.kudratov.osg';

/// Must match the WidgetKit `kind:` in OsgWidget.swift and the Android
/// provider class name.
const String widgetKind = 'OsgWidget';

/// Full class name of the Android provider. Must be given explicitly:
/// home_widget otherwise looks for `<applicationId>.OsgWidget`, which doesn't
/// exist (the class lives in the Kotlin package com.osg.osg_app, while the
/// app ID is uz.kudratov.osg) - every "redraw now" from the app then failed
/// silently and the widget only changed at its own slot alarms.
const String androidWidgetProvider = 'com.osg.osg_app.OsgWidgetProvider';

/// Storage key read by OsgWidget.swift and OsgWidgetProvider.kt.
const String widgetDataKey = 'todays_words';

/// Pushes the week's word slots to the native Home/Lock Screen widget.
///
/// Payload (`todays_words`, JSON):
///   {"version": 2, "slots": [{"at": EPOCH_MS, "title": "🇩🇪 der Schlüssel",
///     "translation": "key", "example": "..."}]}
/// sorted by `at`. `title` already carries the target language's flag -
/// the native widgets show it as is. `at` is exactly when that word's notification fires
/// (the reminder's time for merged slots), so the widget switches in step
/// with the notifications. The native side shows the latest slot whose
/// time has passed and switches at the next one by itself (WidgetKit
/// timeline on iOS, an exact alarm on Android) - no app open needed for
/// the whole planned week.
class WidgetSync {
  /// Call once at app startup, before the first [sync].
  static Future<void> init() => HomeWidget.setAppGroupId(widgetGroupId);

  /// Best-effort: errors (no widget placed, App Group not provisioned, no
  /// plugin in tests...) are swallowed so they never break scheduling.
  Future<void> sync(List<WidgetSlot> slots) async {
    try {
      await HomeWidget.saveWidgetData<String>(widgetDataKey, encodePayload(slots));
      await HomeWidget.updateWidget(name: widgetKind, iOSName: widgetKind, qualifiedAndroidName: androidWidgetProvider);
    } catch (_) {
      // Best-effort - see doc comment above.
    }
  }

  static String encodePayload(List<WidgetSlot> slots) => jsonEncode({
        'version': 2,
        'slots': [
          for (final s in slots)
            {
              'at': s.at.millisecondsSinceEpoch,
              'title': flaggedTitle(s.word),
              'translation': s.word.translation,
              'example': s.word.example,
            },
        ],
      });
}
