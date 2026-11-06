import 'package:flutter/widgets.dart';

import '../data/db/tables.dart' show RepeatType;
import '../data/languages.dart';
import 'app_localizations.dart';

export 'app_localizations.dart';

/// Interface languages (= source languages). Anything else falls back to English.
const supportedUiLocales = [Locale('en'), Locale('uz'), Locale('ru')];

/// Strings for code that has no BuildContext (notifications scheduled
/// from Dart): same ARB strings as the UI, picked by the source language.
AppLocalizations stringsFor(String sourceLanguage) =>
    lookupAppLocalizations(Locale(sourceLanguages.contains(sourceLanguage) ? sourceLanguage : 'en'));

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

/// Translated label for a fixed category key (SPEC section 2); unknown
/// keys are shown as stored.
String categoryLabel(AppLocalizations l, String key) => switch (key) {
      'Daily Life' => l.catDailyLife,
      'Work' => l.catWork,
      'Food' => l.catFood,
      'Common Verbs' => l.catCommonVerbs,
      'Travel' => l.catTravel,
      'Emotions' => l.catEmotions,
      'Adjectives' => l.catAdjectives,
      'Time' => l.catTime,
      'Money' => l.catMoney,
      'Health' => l.catHealth,
      'Weather' => l.catWeather,
      'Social' => l.catSocial,
      'Home' => l.catHome,
      'Family' => l.catFamily,
      'Education' => l.catEducation,
      'Shopping' => l.catShopping,
      'Nature' => l.catNature,
      _ => key,
    };

String repeatLabel(AppLocalizations l, RepeatType type) => switch (type) {
      RepeatType.once => l.repeatOnce,
      RepeatType.daily => l.repeatDaily,
      RepeatType.weekdays => l.repeatWeekdays,
      RepeatType.weekly => l.repeatWeekly,
      RepeatType.monthly => l.repeatMonthly,
    };
