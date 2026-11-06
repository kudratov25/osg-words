import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/languages.dart';
import '../data/repository.dart';
import '../guide/guide_controller.dart';
import 'content_sync.dart';

const sourcePrefKey = 'lang_source';
const targetPrefKey = 'lang_target';
const onboardingDonePrefKey = 'onboarding_done';

/// Onboarding offline fell back to en-de although the user speaks another
/// language: that language, until its pair can be downloaded.
const wantedSourcePrefKey = 'lang_source_wanted';

/// The chosen language pair + onboarding state (shared_preferences), and
/// the one place that changes the pair, so Repository, content and the
/// interface language never disagree.
///
/// Listeners are notified when the pair (and so the interface language)
/// changes and when onboarding completes.
class LanguageSettings extends ChangeNotifier {
  LanguageSettings(this._repo, this._sync, {this.onPairApplied});

  final Repository _repo;
  final ContentSync _sync;

  /// Runs after a pair change from Settings (reschedule notifications and
  /// the widget with the new words/strings).
  Future<void> Function()? onPairApplied;

  LanguagePair _pair = builtInPair;
  bool _onboardingDone = false;
  String? _wantedSource;

  LanguagePair get pair => _pair;
  bool get onboardingDone => _onboardingDone;

  /// The language picked in onboarding whose words couldn't be downloaded
  /// yet (offline). Null once its pair is on the phone, or if none.
  String? get wantedSource => _wantedSource;

  /// Interface language: the source language - or, while the offline
  /// fallback is active, the language the user actually picked, so an
  /// Uzbek speaker never gets stuck with an English interface.
  String get uiLanguage => _wantedSource ?? _pair.source;
  Locale get locale => Locale(uiLanguage);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    var done = prefs.getBool(onboardingDonePrefKey) ?? false;
    if (!done && await _repo.hasLearningActivity()) {
      // Installed before language pairs existed: keep English -> German.
      await prefs.setString(sourcePrefKey, builtInPair.source);
      await prefs.setString(targetPrefKey, builtInPair.target);
      await prefs.setBool(onboardingDonePrefKey, true);
      done = true;
    }
    final source = prefs.getString(sourcePrefKey);
    final target = prefs.getString(targetPrefKey);
    _pair = source != null &&
            target != null &&
            source != target &&
            sourceLanguages.contains(source) &&
            targetLanguages.contains(target)
        ? LanguagePair(source, target)
        : builtInPair;
    _onboardingDone = done;
    final wanted = prefs.getString(wantedSourcePrefKey);
    _wantedSource = wanted != null && wanted != _pair.source && sourceLanguages.contains(wanted) ? wanted : null;
    _repo.pair = _pair;
    _repo.uiLanguage = uiLanguage;
  }

  /// Offline fallback from onboarding: try again to get the pair the user
  /// picked (called on app open/resume). True if it switched.
  Future<bool> retryWantedPair() async {
    final wanted = _wantedSource;
    if (wanted == null) return false;
    final p = LanguagePair(wanted, _pair.target);
    if (p.source == p.target) {
      await _setWanted(null);
      notifyListeners();
      return false;
    }
    return changePair(p);
  }

  Future<void> _setWanted(String? source) async {
    final prefs = await SharedPreferences.getInstance();
    if (source == null) {
      await prefs.remove(wantedSourcePrefKey);
    } else {
      await prefs.setString(wantedSourcePrefKey, source);
    }
    _wantedSource = source;
    _repo.uiLanguage = uiLanguage;
  }

  /// Built-in pair plus whatever the server offers (GET /content/pairs).
  /// `offline` is true when the server couldn't be asked.
  Future<({List<AvailablePair> pairs, bool offline})> availablePairs() async {
    final server = await _sync.fetchPairs();
    final builtInWords = await _repo.wordCount(builtInPair.target);
    final pairs = <AvailablePair>[
      AvailablePair(
        pair: builtInPair,
        words: server?.where((p) => p.pair.isBuiltIn).firstOrNull?.words ?? builtInWords,
      ),
      for (final p in server ?? const <AvailablePair>[])
        if (!p.pair.isBuiltIn &&
            p.pair.source != p.pair.target &&
            sourceLanguages.contains(p.pair.source) &&
            targetLanguages.contains(p.pair.target))
          p,
    ];
    return (pairs: pairs, offline: server == null);
  }

  /// Makes sure [p]'s words (with translations in its source) are on the
  /// phone. The built-in pair always succeeds (bundled words; the server's
  /// newer pack is fetched best-effort). Other pairs need a download.
  Future<bool> prepareWords(LanguagePair p, {void Function(SyncStage stage)? onStage}) async {
    if (p.isBuiltIn) {
      if (await ContentSync.localPackPair() != builtInPair.key) {
        await _repo.restoreBuiltInTranslations();
        await ContentSync.markBuiltInRestored();
      }
      await _sync.sync(pair: p, force: true, onStage: onStage);
      return true;
    }
    final result = await _sync.sync(pair: p, force: true, onStage: onStage);
    return result == SyncResult.merged || result == SyncResult.upToDate;
  }

  /// Settings -> Languages. Downloads the pair's words first; on failure
  /// nothing changes and false is returned. Progress is always kept.
  Future<bool> changePair(LanguagePair p, {void Function(SyncStage stage)? onStage}) async {
    if (p == _pair) return true;
    if (!await prepareWords(p, onStage: onStage)) return false;
    await _apply(p);
    await onPairApplied?.call();
    return true;
  }

  /// Last onboarding step: [p]'s words must already be prepared.
  /// [wantedSource]: the language picked in step 1 when [p] is the offline
  /// fallback - kept as the interface language until its pair downloads.
  Future<void> completeOnboarding(LanguagePair p, {String? wantedSource}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(onboardingDonePrefKey, true);
    // Fresh install: show the app guide once on the main screen.
    await GuideController.markPending();
    _onboardingDone = true;
    if (wantedSource != null && wantedSource != p.source && sourceLanguages.contains(wantedSource)) {
      await _setWanted(wantedSource);
    }
    await _apply(p, keepWanted: true);
  }

  Future<void> _apply(LanguagePair p, {bool keepWanted = false}) async {
    final targetChanged = p.target != _pair.target;
    // Any explicit pair change (Settings, or the retry succeeding) settles it.
    if (!keepWanted) await _setWanted(null);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(sourcePrefKey, p.source);
    await prefs.setString(targetPrefKey, p.target);
    _pair = p;
    _repo.pair = p;
    _repo.uiLanguage = uiLanguage;
    // New target: the rest of the week gets replanned with its words.
    if (targetChanged) await _repo.dropUnrecordedPlansFrom(DateTime.now());
    notifyListeners();
  }
}
