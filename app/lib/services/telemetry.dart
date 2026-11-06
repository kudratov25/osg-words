import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'api_config.dart';
import 'device_id.dart';
import 'language_settings.dart' show sourcePrefKey, targetPrefKey;

/// Settings -> "Share anonymous usage data".
const telemetryPrefKey = 'telemetry_enabled';

enum TelemetryEvent { appOpen, notifTapped }

extension on TelemetryEvent {
  String get wire => switch (this) {
        TelemetryEvent.appOpen => 'app_open',
        TelemetryEvent.notifTapped => 'notif_tapped',
      };
}

/// Anonymous usage pings to POST /telemetry/ping. Respects the
/// "Share anonymous usage data" switch in Settings. The device id is a
/// random UUID generated on first use - not tied to any identity.
/// Pings carry the language pair (`uz-de`) once one is chosen.
/// Fire-and-forget: failures are ignored.
class Telemetry {
  Telemetry({http.Client? client, this.baseUrl = apiBaseUrl}) : _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  Future<void> send(TelemetryEvent event) async {
    if (baseUrl.isEmpty) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!(prefs.getBool(telemetryPrefKey) ?? true)) return;

      final id = await deviceId();
      final source = prefs.getString(sourcePrefKey);
      final target = prefs.getString(targetPrefKey);

      final os = '${Platform.operatingSystem} ${Platform.operatingSystemVersion}';
      await _client
          .post(
            apiUri(baseUrl, '/telemetry/ping'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'device_id': id,
              'os_version': os.length > 100 ? os.substring(0, 100) : os,
              'app_version': appVersion,
              'event_type': event.wire,
              // The language pair only - no other onboarding answers.
              if (source != null && target != null) 'pair': '$source-$target',
            }),
          )
          .timeout(apiTimeout);
    } catch (e) {
      debugPrint('Telemetry ping failed (ignored): $e');
    }
  }
}
