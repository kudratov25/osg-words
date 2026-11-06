import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../data/languages.dart';
import 'api_config.dart';
import 'device_id.dart';

/// Kinds accepted by POST /feedback/word-issue (SPEC section 4, WordIssue).
enum WordIssueKind {
  wrongTranslation('wrong_translation'),
  wrongArticle('wrong_article'),
  wrongExample('wrong_example'),
  other('other');

  const WordIssueKind(this.wire);
  final String wire;
}

enum ReportResult { sent, offline, tooMany, failed }

/// "Report a mistake" on the word card.
class FeedbackApi {
  FeedbackApi({http.Client? client, this.baseUrl = apiBaseUrl}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  static const maxNoteLength = 300;

  Future<ReportResult> reportWordIssue({
    required String externalId,
    required LanguagePair pair,
    required WordIssueKind kind,
    String? note,
  }) async {
    if (baseUrl.isEmpty) return ReportResult.offline;
    final trimmed = note?.trim();
    try {
      final res = await _client
          .post(
            apiUri(baseUrl, '/feedback/word-issue'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': await deviceId(),
              'external_id': externalId,
              'source': pair.source,
              'target': pair.target,
              'kind': kind.wire,
              if (trimmed != null && trimmed.isNotEmpty)
                'note': trimmed.length > maxNoteLength ? trimmed.substring(0, maxNoteLength) : trimmed,
            }),
          )
          .timeout(apiTimeout);
      if (res.statusCode == 204 || res.statusCode == 200 || res.statusCode == 201) return ReportResult.sent;
      if (res.statusCode == 429) return ReportResult.tooMany;
      return ReportResult.failed;
    } catch (e) {
      debugPrint('Word report failed: $e');
      return ReportResult.offline;
    }
  }
}
