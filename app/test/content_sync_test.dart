import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/data/languages.dart';
import 'package:osg_app/data/repository.dart';
import 'package:osg_app/services/content_sync.dart';
import 'package:osg_app/services/telemetry.dart';

import 'support/fake_backend.dart';

Map<String, dynamic> word(String id, String german, String translation) => {
      'external_id': id,
      'german': german,
      'article': 'das',
      'translation': translation,
      'example': 'Beispiel mit $german.',
      'pronunciation': null,
      'category': 'test',
      'difficulty': 'beginner',
      'created_at': '2026-11-04T00:00:00',
    };

/// Fake backend: serves [version] + [words], counts requests per path.
class FakeServer {
  FakeServer(this.version, this.words);
  int version;
  List<Map<String, dynamic>> words;
  final hits = <String, int>{};
  int statusCode = 200;
  final pings = <Map<String, dynamic>>[];

  late final client = MockClient((req) async {
    hits[req.url.path] = (hits[req.url.path] ?? 0) + 1;
    if (statusCode != 200) return http.Response('error', statusCode);
    switch (req.url.path) {
      case '/content/meta':
        return http.Response(jsonEncode({'version': version, 'updated_at': '2026-11-04T00:00:00'}), 200);
      case '/content/words':
        return http.Response.bytes(utf8.encode(jsonEncode({'version': version, 'words': words})), 200,
            headers: {'content-type': 'application/json'});
      case '/telemetry/ping':
        pings.add(jsonDecode(req.body) as Map<String, dynamic>);
        return http.Response('', 204);
    }
    return http.Response('not found', 404);
  });
}

void main() {
  late AppDatabase db;
  late Repository repo;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = Repository(db);
  });
  tearDown(() => db.close());

  final day1 = DateTime(2026, 11, 4, 9);
  final day2 = DateTime(2026, 11, 5, 9);

  test('downloads and merges words when server version is newer', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house'), word('w2', 'Baum', 'tree')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');

    expect(await sync.syncIfDue(now: day1), isTrue);
    final words = await repo.allWords();
    expect(words.map((w) => w.term), containsAll(['Haus', 'Baum']));
  });

  test('handles German umlauts (UTF-8) correctly', () async {
    final server = FakeServer(1, [word('w1', 'Brötchen', 'bread roll')]);
    await ContentSync(repo, client: server.client, baseUrl: 'http://test').syncIfDue(now: day1);
    expect((await repo.allWords()).single.term, 'Brötchen');
  });

  test('checks at most once per sync interval', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');

    await sync.syncIfDue(now: day1);
    await sync.syncIfDue(now: day1.add(syncInterval - const Duration(minutes: 1)));
    expect(server.hits['/content/meta'], 1);

    await sync.syncIfDue(now: day1.add(syncInterval));
    expect(server.hits['/content/meta'], 2);

    await sync.syncIfDue(now: day2);
    expect(server.hits['/content/meta'], 3);
  });

  test('a clock set backwards does not block syncing', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');
    await sync.syncIfDue(now: day2);
    await sync.syncIfDue(now: day1);
    expect(server.hits['/content/meta'], 2);
  });

  test('notifies listeners only when words were merged', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');
    var notified = 0;
    sync.addListener(() => notified++);

    expect(await sync.sync(now: day1), SyncResult.merged);
    expect(notified, 1);
    expect(await sync.sync(now: day1, force: true), SyncResult.upToDate);
    expect(notified, 1);

    // Fixed in the admin panel: the pack version is bumped.
    server.version = 2;
    server.words = [word('w1', 'Haus', 'home')];
    expect(await sync.sync(now: day1, force: true), SyncResult.merged);
    expect(notified, 2);
    final w = (await db.select(db.words).get()).single;
    expect(w.translation, 'home');
  });

  test('skips download when version unchanged', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');

    await sync.syncIfDue(now: day1);
    expect(await sync.syncIfDue(now: day2), isFalse);
    expect(server.hits['/content/words'], 1);
  });

  test('updates edited words but keeps their local id (progress safe)', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'hous')]);
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');
    await sync.syncIfDue(now: day1);
    final before = (await repo.allWords()).single;
    await repo.toggleFavorite(before.id);

    server
      ..version = 2
      ..words = [word('w1', 'Haus', 'house'), word('w2', 'Baum', 'tree')];
    await sync.syncIfDue(now: day2);

    final after = await repo.allWords();
    final haus = after.firstWhere((w) => w.externalId == 'w1');
    expect(haus.id, before.id);
    expect(haus.translation, 'house');
    expect(await repo.isFavorite(haus.id), isTrue);
    expect(after.length, 2);
  });

  test('does not delete local words missing from the pack', () async {
    await db.into(db.words).insert(WordsCompanion.insert(
          externalId: 'local-only',
          term: 'Katze',
          article: const Value('die'),
          translation: 'cat',
          example: 'Die Katze schläft.',
          category: 'animals',
        ));
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    await ContentSync(repo, client: server.client, baseUrl: 'http://test').syncIfDue(now: day1);
    expect((await repo.allWords()).length, 2);
  });

  test('server error: no crash, not marked synced, retries same day', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')])..statusCode = 500;
    final sync = ContentSync(repo, client: server.client, baseUrl: 'http://test');

    expect(await sync.syncIfDue(now: day1), isFalse);
    server.statusCode = 200;
    expect(await sync.syncIfDue(now: day1), isTrue);
  });

  test('offline (exception): no crash', () async {
    final client = MockClient((_) async => throw http.ClientException('no network'));
    expect(await ContentSync(repo, client: client, baseUrl: 'http://test').syncIfDue(now: day1), isFalse);
  });

  test('no base URL configured: does nothing', () async {
    final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
    expect(await ContentSync(repo, client: server.client, baseUrl: '').syncIfDue(now: day1), isFalse);
    expect(server.hits, isEmpty);
  });

  group('telemetry', () {
    test('sends ping with a stable device id', () async {
      final server = FakeServer(1, []);
      final t = Telemetry(client: server.client, baseUrl: 'http://test');
      await t.send(TelemetryEvent.appOpen);
      await t.send(TelemetryEvent.notifTapped);

      expect(server.pings.map((p) => p['event_type']), ['app_open', 'notif_tapped']);
      expect(server.pings[0]['device_id'], server.pings[1]['device_id']);
      expect((server.pings[0]['device_id'] as String).length, 36);
    });

    test('respects the Settings opt-out switch', () async {
      SharedPreferences.setMockInitialValues({'telemetry_enabled': false});
      final server = FakeServer(1, []);
      await Telemetry(client: server.client, baseUrl: 'http://test').send(TelemetryEvent.appOpen);
      expect(server.pings, isEmpty);
    });
  });

  group('language pairs', () {
    test('sends source/target and parses v2 fields', () async {
      final backend = FakeBackend()
        ..packs['uz-de'] = FakePack(3, [
          v2Word('der_schluessel', 'Schlüssel', 'kalit', article: 'der', exampleTranslation: 'Kalitim qayerda?'),
        ]);
      repo.pair = const LanguagePair('uz', 'de');
      final sync = ContentSync(repo, client: backend.client, baseUrl: 'http://test');

      expect(await sync.sync(now: day1), SyncResult.merged);
      final meta = backend.requests.firstWhere((r) => r.url.path == '/content/meta');
      expect(meta.url.queryParameters, {'source': 'uz', 'target': 'de'});
      final words = backend.requests.firstWhere((r) => r.url.path == '/content/words');
      expect(words.url.queryParameters, {'source': 'uz', 'target': 'de', 'topics': 'true'});

      final w = (await repo.allWords()).single;
      expect(w.term, 'Schlüssel');
      expect(w.lang, 'de');
      expect(w.translation, 'kalit');
      expect(w.exampleTranslation, 'Kalitim qayerda?');
    });

    test('English target words get lang en', () async {
      final backend = FakeBackend()
        ..packs['ru-en'] = FakePack(1, [v2Word('en.apple', 'apple', 'яблоко', lang: 'en', article: null)]);
      repo.pair = const LanguagePair('ru', 'en');
      await ContentSync(repo, client: backend.client, baseUrl: 'http://test').sync(now: day1);
      final w = (await repo.allWords()).single;
      expect(w.lang, 'en');
      expect(w.article, isNull);
    });

    test('still accepts the old `german` field (no term/lang)', () async {
      final server = FakeServer(1, [word('w1', 'Haus', 'house')]);
      await ContentSync(repo, client: server.client, baseUrl: 'http://test').syncIfDue(now: day1);
      final w = (await repo.allWords()).single;
      expect(w.term, 'Haus');
      expect(w.lang, 'de');
      expect(w.exampleTranslation, isNull);
    });

    test('pair change re-downloads even with the same version, translations update in place', () async {
      final backend = FakeBackend()
        ..packs['en-de'] = FakePack(2, [v2Word('w1', 'Haus', 'house')])
        ..packs['ru-de'] = FakePack(2, [v2Word('w1', 'Haus', 'дом')]);
      final sync = ContentSync(repo, client: backend.client, baseUrl: 'http://test');
      await sync.sync(now: day1);
      final before = (await repo.allWords()).single;
      await repo.toggleFavorite(before.id);

      repo.pair = const LanguagePair('ru', 'de');
      // Same day, same version - still downloads because the pair differs.
      expect(await sync.sync(now: day1, force: true), SyncResult.merged);
      final after = (await repo.allWords()).single;
      expect(after.id, before.id);
      expect(after.translation, 'дом');
      expect(await repo.isFavorite(after.id), isTrue);
    });

    test('throttled per pair; force skips the throttle', () async {
      final backend = FakeBackend()..packs['en-de'] = FakePack(1, [v2Word('w1', 'Haus', 'house')]);
      final sync = ContentSync(repo, client: backend.client, baseUrl: 'http://test');
      expect(await sync.sync(now: day1), SyncResult.merged);
      expect(await sync.sync(now: day1), SyncResult.skipped);
      expect(await sync.sync(now: day1, force: true), SyncResult.upToDate);
      expect(backend.hits('/content/meta'), 2);
    });

    test('unavailable pair (404) fails without touching words', () async {
      final backend = FakeBackend();
      repo.pair = const LanguagePair('uz', 'en');
      expect(await ContentSync(repo, client: backend.client, baseUrl: 'http://test').sync(now: day1), SyncResult.failed);
      expect(await repo.allWords(), isEmpty);
    });

    test('GET /content/pairs helper; null when offline', () async {
      final backend = FakeBackend()
        ..packs['en-de'] = FakePack(1, [v2Word('w1', 'Haus', 'house')])
        ..packs['uz-de'] = FakePack(4, [v2Word('w1', 'Haus', 'uy'), v2Word('w2', 'Baum', 'daraxt')]);
      final sync = ContentSync(repo, client: backend.client, baseUrl: 'http://test');
      final pairs = await sync.fetchPairs();
      expect(pairs!.map((p) => p.pair.key), ['en-de', 'uz-de']);
      expect(pairs[1].words, 2);
      expect(pairs[1].version, 4);

      backend.online = false;
      expect(await sync.fetchPairs(), isNull);
      expect(await ContentSync(repo, client: backend.client, baseUrl: '').fetchPairs(), isNull);
    });

    test('telemetry ping carries the pair', () async {
      SharedPreferences.setMockInitialValues({'lang_source': 'uz', 'lang_target': 'de'});
      final backend = FakeBackend();
      await Telemetry(client: backend.client, baseUrl: 'http://test').send(TelemetryEvent.appOpen);
      expect(backend.pings.single['pair'], 'uz-de');
    });
  });
}
