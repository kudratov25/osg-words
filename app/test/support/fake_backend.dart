import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// A word in the v2 API shape (SPEC section 5, GET /content/words).
Map<String, dynamic> v2Word(
  String id,
  String term,
  String translation, {
  String lang = 'de',
  String? article = 'das',
  String? example,
  String? exampleTranslation,
  String category = 'Daily Life',
}) =>
    {
      'external_id': id,
      'lang': lang,
      'term': term,
      'german': term,
      'article': article,
      'translation': translation,
      'example': example ?? 'Beispiel mit $term.',
      'example_translation': exampleTranslation,
      'pronunciation': null,
      'category': category,
      'difficulty': 'beginner',
      'created_at': '2026-11-04T00:00:00',
    };

/// The bundled en-de words, re-translated into [source] ("uz:key"), as
/// the server would deliver that pair.
List<Map<String, dynamic>> seedWordsTranslated(String source) {
  final seed = jsonDecode(File('assets/words_seed.json').readAsStringSync()) as Map<String, dynamic>;
  return [
    for (final w in (seed['words'] as List).cast<Map<String, dynamic>>())
      v2Word(
        w['external_id'] as String,
        (w['term'] ?? w['german']) as String,
        '$source:${w['translation']}',
        article: w['article'] as String?,
        example: w['example'] as String,
        exampleTranslation: '$source example',
        category: w['category'] as String,
      ),
  ];
}

class FakePack {
  FakePack(this.version, this.words);
  int version;
  List<Map<String, dynamic>> words;
}

/// In-memory OSG backend for tests: content per pair, word reports,
/// telemetry and email-code auth. Built on package:http's MockClient.
class FakeBackend {
  /// `source-target` -> pack.
  final packs = <String, FakePack>{};
  bool online = true;
  bool authEnabled = true;
  String code = '123456';

  /// Paths that answer 500 (e.g. '/content/words').
  final failing = <String>{};

  final requests = <http.Request>[];
  final reports = <Map<String, dynamic>>[];
  final pings = <Map<String, dynamic>>[];
  final verifyBodies = <Map<String, dynamic>>[];
  int reportLimit = 20;
  bool deleted = false;
  bool loggedOut = false;
  final _tokens = <String>{};

  int hits(String path) => requests.where((r) => r.url.path == path).length;

  late final http.Client client = MockClient((req) async {
    requests.add(req);
    if (!online) throw http.ClientException('offline');
    final path = req.url.path;
    if (failing.contains(path)) return http.Response('error', 500);
    final pairKey = '${req.url.queryParameters['source'] ?? 'en'}-${req.url.queryParameters['target'] ?? 'de'}';

    Map<String, dynamic> body() => req.body.isEmpty ? {} : jsonDecode(req.body) as Map<String, dynamic>;
    http.Response json(Object o, [int status = 200]) =>
        http.Response.bytes(utf8.encode(jsonEncode(o)), status, headers: {'content-type': 'application/json'});

    switch ((req.method, path)) {
      case ('GET', '/content/pairs'):
        return json({
          'pairs': [
            for (final e in packs.entries)
              {
                'source': e.key.split('-')[0],
                'target': e.key.split('-')[1],
                'words': e.value.words.length,
                'version': e.value.version,
              },
          ],
        });
      case ('GET', '/content/meta'):
        final pack = packs[pairKey];
        if (pack == null) return json({'detail': 'Unknown pair'}, 404);
        final parts = pairKey.split('-');
        return json({'version': pack.version, 'updated_at': '2026-11-04T00:00:00', 'source': parts[0], 'target': parts[1]});
      case ('GET', '/content/words'):
        final pack = packs[pairKey];
        if (pack == null) return json({'detail': 'Unknown pair'}, 404);
        final parts = pairKey.split('-');
        return json({'version': pack.version, 'source': parts[0], 'target': parts[1], 'words': pack.words});
      case ('POST', '/telemetry/ping'):
        pings.add(body());
        return http.Response('', 204);
      case ('POST', '/feedback/word-issue'):
        if (reports.length >= reportLimit) return json({'detail': 'Too many reports from this device today'}, 429);
        reports.add(body());
        return http.Response('', 204);
      case ('GET', '/auth/config'):
        return json({'enabled': authEnabled, 'methods': authEnabled ? ['email_code'] : []});
      case ('POST', '/auth/email/start'):
        if (!authEnabled) return json({'detail': 'disabled'}, 503);
        return http.Response('', 204);
      case ('POST', '/auth/email/verify'):
        final b = body();
        verifyBodies.add(b);
        if (b['code'] != code) return json({'detail': 'Wrong code. 4 attempt(s) left.'}, 400);
        final token = 'osgu_test${_tokens.length + 1}';
        _tokens.add(token);
        return json({
          'token': token,
          'user': {'id': 1, 'email': b['email'], 'created_at': '2026-11-04T00:00:00'},
        });
      case ('POST', '/auth/logout'):
        loggedOut = _tokens.remove(_bearer(req));
        return http.Response('', 204);
      case ('DELETE', '/me'):
        if (!_tokens.contains(_bearer(req))) return json({'detail': 'Unauthorized'}, 401);
        deleted = true;
        _tokens.clear();
        return http.Response('', 204);
    }
    return http.Response('not found', 404);
  });

  String? _bearer(http.Request req) => req.headers['Authorization']?.replaceFirst('Bearer ', '');
}
