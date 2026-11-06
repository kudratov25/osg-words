import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/levels.dart';
import '../data/repository.dart';

const levelPrefKey = 'learn_level';
const topicsPrefKey = 'learn_topics';

/// The user's CEFR level and job areas (shared_preferences), mirrored into
/// [Repository] for the planner. Picked in onboarding, changed in Settings.
class LearningPrefs extends ChangeNotifier {
  LearningPrefs(this._repo, {this.onChanged});

  final Repository _repo;

  /// Runs after a change (reschedule notifications + widget).
  Future<void> Function()? onChanged;

  String _level = defaultLevel;
  Set<String> _topics = const {};

  String get level => _level;
  Set<String> get topics => _topics;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final level = prefs.getString(levelPrefKey);
    _level = cefrLevels.contains(level) ? level! : defaultLevel;
    _topics = {...?prefs.getStringList(topicsPrefKey)}.where(jobTopics.contains).toSet();
    _repo.level = _level;
    _repo.topics = _topics;
  }

  /// Saves both and replaces today's words right away, so the change is
  /// visible immediately (not tomorrow).
  Future<void> update({String? level, Set<String>? topics}) async {
    final newLevel = level != null && cefrLevels.contains(level) ? level : _level;
    final newTopics = topics?.where(jobTopics.contains).toSet() ?? _topics;
    if (newLevel == _level && setEquals(newTopics, _topics)) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(levelPrefKey, newLevel);
    await prefs.setStringList(topicsPrefKey, (newTopics.toList()..sort()));
    _level = newLevel;
    _topics = newTopics;
    _repo.level = newLevel;
    _repo.topics = newTopics;
    await _repo.replanToday(DateTime.now());
    notifyListeners();
    await onChanged?.call();
  }
}
