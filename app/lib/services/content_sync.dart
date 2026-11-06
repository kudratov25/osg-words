import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../data/languages.dart';
import '../data/repository.dart';
import 'api_config.dart';

/// `<epoch ms>|source-target` of the last fully successful check.
const _lastSyncKey = 'content_last_sync_at';

/// Pre-2.1 key (`YYYY-MM-DD|pair`); removed when the pack is reset.
const _legacyLastSyncDayKey = 'content_last_sync_day';

/// Automatic checks (app open / resume) run at most this often per pair.
/// The check is a tiny `/content/meta` request, so a fix made in the admin
/// panel reaches phones within this time. Pull-to-refresh ignores it.
const Duration syncInterval = Duration(minutes: 30);
const _packVersionKey = 'content_pack_version';

/// Which pair the words on the phone were last merged from. Installs from
/// before language pairs have no value: they hold the en-de pack.
const _packPairKey = 'content_pack_pair';

/// Shape of the merged pack: 2 = with levels + job-area words (2.1). A pack
/// merged by an older app version is downloaded again once.
const _packFormatKey = 'content_pack_format';
const _packFormat = 2;

enum SyncResult {
  /// New/updated words were merged.
  merged,

  /// The phone already has this pair's latest pack.
  upToDate,

  /// Checked less than [syncInterval] ago; nothing was requested.
  skipped,

  /// Offline, timeout, server error, or the pair isn't available (404).
  failed,
}

/// Progress of a [ContentSync.sync] run, for the onboarding progress line.
enum SyncStage { checking, downloading, saving }

/// Downloads new/updated words for the current language pair, at most once
/// per [syncInterval] (or right away with `force`: pull-to-refresh, a pair
/// change). Notifies listeners after words were merged, so open screens,
/// notifications and the widget can pick up the new text.
///
/// Flow: GET /content/meta?source&target -> if the server's pack version is
/// newer than the one we last merged, or the phone's words come from a
/// different pair, GET /content/words?source&target and merge into the
/// local DB (in place - progress is kept). Any failure (offline, timeout,
/// bad response) is reported as [SyncResult.failed], never thrown: the app
/// keeps working with what it has and simply tries again later.
class ContentSync extends ChangeNotifier {
  ContentSync(this._repository, {http.Client? client, this.baseUrl = apiBaseUrl})
      : _client = client ?? http.Client();

  final Repository _repository;
  final http.Client _client;
  final String baseUrl;

  /// Returns true if new content was merged.
  Future<bool> syncIfDue({DateTime? now, bool force = false}) async =>
      await sync(now: now, force: force) == SyncResult.merged;

  Future<SyncResult> sync({
    LanguagePair? pair,
    DateTime? now,
    bool force = false,
    void Function(SyncStage stage)? onStage,
  }) async {
    if (baseUrl.isEmpty) return SyncResult.failed;
    final p = pair ?? _repository.pair;
    final query = {'source': p.source, 'target': p.target};
    final wordsQuery = {...query, 'topics': 'true'};
    try {
      final prefs = await SharedPreferences.getInstance();
      final at = now ?? DateTime.now();
      if (!force && _checkedRecently(prefs.getString(_lastSyncKey), p.key, at)) return SyncResult.skipped;

      onStage?.call(SyncStage.checking);
      final metaRes = await _client.get(apiUri(baseUrl, '/content/meta', query)).timeout(apiTimeout);
      if (metaRes.statusCode != 200) return SyncResult.failed;
      final serverVersion = (jsonDecode(metaRes.body) as Map<String, dynamic>)['version'] as int;
      final localVersion =
          prefs.getInt(_packFormatKey) == _packFormat ? (prefs.getInt(_packVersionKey) ?? 0) : 0;
      final localPair = prefs.getString(_packPairKey) ?? builtInPair.key;

      var result = SyncResult.upToDate;
      if (serverVersion > localVersion || localPair != p.key) {
        onStage?.call(SyncStage.downloading);
        final wordsRes = await _client.get(apiUri(baseUrl, '/content/words', wordsQuery)).timeout(contentDownloadTimeout);
        if (wordsRes.statusCode != 200) return SyncResult.failed;
        final pack = jsonDecode(utf8.decode(wordsRes.bodyBytes)) as Map<String, dynamic>;
        final words = (pack['words'] as List).cast<Map<String, dynamic>>();
        onStage?.call(SyncStage.saving);
        await _repository.mergeContentPack(words, defaultLang: pack['target'] as String? ?? p.target);
        await prefs.setInt(_packVersionKey, pack['version'] as int);
        await prefs.setString(_packPairKey, p.key);
        await prefs.setInt(_packFormatKey, _packFormat);
        result = SyncResult.merged;
      }
      // Only remember the check once it fully succeeded.
      await prefs.setString(_lastSyncKey, '${at.millisecondsSinceEpoch}|${p.key}');
      if (result == SyncResult.merged) notifyListeners();
      return result;
    } catch (e) {
      debugPrint('ContentSync failed (will retry later): $e');
      return SyncResult.failed;
    }
  }

  /// Pair the phone's word translations come from (`en-de` by default).
  static Future<String> localPackPair() async =>
      (await SharedPreferences.getInstance()).getString(_packPairKey) ?? builtInPair.key;

  /// The bundled en-de words were put back (offline switch to English):
  /// the next check must download the server's en-de pack again.
  static Future<void> markBuiltInRestored() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_packPairKey, builtInPair.key);
    await prefs.remove(_packVersionKey);
    await prefs.remove(_lastSyncKey);
    await prefs.remove(_legacyLastSyncDayKey);
  }

  /// Pairs the server can deliver (GET /content/pairs). Null when offline,
  /// unconfigured or on any error - callers then offer the built-in pair only.
  Future<List<AvailablePair>?> fetchPairs({Duration timeout = const Duration(seconds: 5)}) async {
    if (baseUrl.isEmpty) return null;
    try {
      final res = await _client.get(apiUri(baseUrl, '/content/pairs', {'topics': 'true'})).timeout(timeout);
      if (res.statusCode != 200) return null;
      final list = (jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>)['pairs'] as List;
      return [
        for (final item in list.cast<Map<String, dynamic>>())
          AvailablePair(
            pair: LanguagePair(item['source'] as String, item['target'] as String),
            words: (item['words'] as num?)?.toInt() ?? 0,
            version: (item['version'] as num?)?.toInt() ?? 0,
          ),
      ];
    } catch (e) {
      debugPrint('Fetching pairs failed: $e');
      return null;
    }
  }

  static bool _checkedRecently(String? stored, String pairKey, DateTime now) {
    if (stored == null) return false;
    final sep = stored.indexOf('|');
    if (sep < 0 || stored.substring(sep + 1) != pairKey) return false;
    final ms = int.tryParse(stored.substring(0, sep));
    if (ms == null) return false;
    final elapsed = now.difference(DateTime.fromMillisecondsSinceEpoch(ms));
    // A clock moved backwards counts as "not recent" so it can't block syncs.
    return !elapsed.isNegative && elapsed < syncInterval;
  }
}
