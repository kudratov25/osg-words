/// Backend address, set at build time:
///
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000
///   flutter build apk --dart-define=API_BASE_URL=https://osg-api.example.com
///
/// Left empty (the default), the app stays fully offline: no content sync,
/// no telemetry. Everything else works the same.
const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');

Uri apiUri(String baseUrl, String path, [Map<String, String>? query]) {
  final base = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
  final uri = Uri.parse('$base$path');
  return query == null || query.isEmpty ? uri : uri.replace(queryParameters: query);
}

/// Keep in sync with `version:` in pubspec.yaml.
const String appVersion = '2.1.0';

const Duration apiTimeout = Duration(seconds: 10);

/// The word list itself (~350 KB with job-area words): slow mobile
/// connections need longer than the small API calls.
const Duration contentDownloadTimeout = Duration(seconds: 30);
