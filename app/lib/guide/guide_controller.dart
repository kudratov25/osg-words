import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Set when onboarding finishes on a fresh install; cleared when the guide
/// has been shown. Installs updated from an older version never get it.
const guidePendingPrefKey = 'guide_pending';

/// Real targets the coach-mark tour points at.
class GuideKeys {
  GuideKeys._();
  static final homeHeader = GlobalKey(debugLabel: 'guide-home-header');
  static final wordCard = GlobalKey(debugLabel: 'guide-word-card');
  static final navBar = GlobalKey(debugLabel: 'guide-nav-bar');
}

/// Starts/stops the first-run guide (coach marks on Home, then the
/// "add the widget" prompt). [enabled] is false in widget tests.
class GuideController extends ChangeNotifier {
  GuideController({this.enabled = true});

  final bool enabled;
  bool _active = false;
  bool get active => _active;

  /// Asks RootScaffold to switch to the Home tab before the tour starts.
  VoidCallback? onShowHome;

  static Future<void> markPending() async =>
      (await SharedPreferences.getInstance()).setBool(guidePendingPrefKey, true);

  /// After the first frames of the main screen: start if pending.
  Future<void> startIfPending() async {
    if (!enabled || _active) return;
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(guidePendingPrefKey) ?? false)) return;
    start();
  }

  /// Settings -> "Show the app guide again" too.
  void start() {
    if (_active) return;
    onShowHome?.call();
    _active = true;
    notifyListeners();
  }

  Future<void> finish() async {
    _active = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(guidePendingPrefKey);
  }
}
