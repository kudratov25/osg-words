import 'dart:async';
import 'dart:convert';
import 'dart:io' show SocketException;

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'device_id.dart';

/// Where the account token lives. Real app: Keystore/Keychain via
/// flutter_secure_storage. Tests: [MemoryTokenStore].
abstract class TokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

class SecureTokenStore implements TokenStore {
  SecureTokenStore([FlutterSecureStorage? storage])
      : _storage = storage ?? const FlutterSecureStorage(aOptions: AndroidOptions(encryptedSharedPreferences: true));
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read(String key) => _storage.read(key: key);
  @override
  Future<void> write(String key, String value) => _storage.write(key: key, value: value);
  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

class MemoryTokenStore implements TokenStore {
  final values = <String, String>{};
  @override
  Future<String?> read(String key) async => values[key];
  @override
  Future<void> write(String key, String value) async => values[key] = value;
  @override
  Future<void> delete(String key) async => values.remove(key);
}

enum AuthError { invalidEmail, wrongCode, codeExpired, tooManyAttempts, network, unavailable, unknown }

class AuthException implements Exception {
  AuthException(this.error, [this.detail]);
  final AuthError error;
  final String? detail;
  @override
  String toString() => 'AuthException($error, $detail)';
}

const _tokenKey = 'auth_token';
const _emailKey = 'auth_email';

/// Minimal optional account (SPEC section 5, "Auth"): email -> 6-digit
/// code -> signed in. Nothing else is asked. Only offered when
/// GET /auth/config says it's enabled.
class AuthService extends ChangeNotifier {
  AuthService({http.Client? client, this.baseUrl = apiBaseUrl, TokenStore? store})
      : _client = client ?? http.Client(),
        _store = store ?? SecureTokenStore();

  final http.Client _client;
  final String baseUrl;
  final TokenStore _store;

  String? _email;
  String? _token;

  /// Email of the signed-in account, null when signed out.
  String? get email => _email;
  bool get signedIn => _token != null;

  Future<void> load() async {
    try {
      // Bounded: a stuck Keystore/Keychain must never block app start.
      _token = await _store.read(_tokenKey).timeout(const Duration(seconds: 3));
      _email = await _store.read(_emailKey).timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('Reading account token failed: $e');
    }
    notifyListeners();
  }

  /// GET /auth/config. False when disabled, offline or unconfigured.
  Future<bool> isEnabled() async {
    if (baseUrl.isEmpty) return false;
    try {
      final res = await _client.get(apiUri(baseUrl, '/auth/config')).timeout(const Duration(seconds: 5));
      if (res.statusCode != 200) return false;
      return (jsonDecode(res.body) as Map<String, dynamic>)['enabled'] == true;
    } catch (_) {
      return false;
    }
  }

  static bool looksLikeEmail(String email) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  /// POST /auth/email/start - the server always answers 204 (no account
  /// enumeration), so success only means "a code is on its way if valid".
  Future<void> startEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (!looksLikeEmail(e)) throw AuthException(AuthError.invalidEmail);
    final res = await _send(() => _client.post(apiUri(baseUrl, '/auth/email/start'),
        headers: _json, body: jsonEncode({'email': e})));
    _check(res, badRequest: AuthError.invalidEmail);
  }

  /// POST /auth/email/verify with this install's device id, then stores
  /// the token securely.
  Future<void> verifyCode(String email, String code) async {
    final e = email.trim().toLowerCase();
    final id = await deviceId();
    final res = await _send(() => _client.post(apiUri(baseUrl, '/auth/email/verify'),
        headers: _json, body: jsonEncode({'email': e, 'code': code.trim(), 'device_id': id})));
    _check(res, badRequest: AuthError.wrongCode);
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    final token = body['token'] as String;
    final userEmail = (body['user'] as Map<String, dynamic>?)?['email'] as String? ?? e;
    await _store.write(_tokenKey, token);
    await _store.write(_emailKey, userEmail);
    _token = token;
    _email = userEmail;
    notifyListeners();
  }

  /// POST /auth/logout (best-effort), then forgets the token. Local data
  /// on the phone is untouched.
  Future<void> signOut() async {
    final token = _token;
    if (token != null && baseUrl.isNotEmpty) {
      try {
        await _client
            .post(apiUri(baseUrl, '/auth/logout'), headers: {'Authorization': 'Bearer $token'})
            .timeout(apiTimeout);
      } catch (_) {
        // Signing out locally works offline too.
      }
    }
    await _clear();
  }

  /// DELETE /me. Throws on failure (the account still exists then).
  Future<void> deleteAccount() async {
    final token = _token;
    if (token == null) return;
    final res = await _send(() => _client.delete(apiUri(baseUrl, '/me'), headers: {'Authorization': 'Bearer $token'}));
    if (res.statusCode == 401) {
      // Session already gone server-side: nothing left to delete with it.
      await _clear();
      return;
    }
    _check(res);
    await _clear();
  }

  Future<void> _clear() async {
    await _store.delete(_tokenKey);
    await _store.delete(_emailKey);
    _token = null;
    _email = null;
    notifyListeners();
  }

  static const _json = {'Content-Type': 'application/json'};

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    if (baseUrl.isEmpty) throw AuthException(AuthError.unavailable);
    try {
      return await request().timeout(apiTimeout);
    } on SocketException {
      throw AuthException(AuthError.network);
    } on http.ClientException {
      throw AuthException(AuthError.network);
    } on TimeoutException {
      throw AuthException(AuthError.network);
    }
  }

  void _check(http.Response res, {AuthError badRequest = AuthError.unknown}) {
    if (res.statusCode >= 200 && res.statusCode < 300) return;
    String? detail;
    try {
      detail = (jsonDecode(res.body) as Map<String, dynamic>)['detail']?.toString();
    } catch (_) {}
    if (res.statusCode == 429) throw AuthException(AuthError.tooManyAttempts, detail);
    if (res.statusCode == 503) throw AuthException(AuthError.unavailable, detail);
    if (res.statusCode == 400 || res.statusCode == 422) {
      final d = detail?.toLowerCase() ?? '';
      // Backend details (routers/auth.py): "Code expired. Request a new
      // one.", "No active code for this email...", "Too many wrong
      // attempts...", "Wrong code. 4 attempt(s) left.".
      if (d.contains('too many')) throw AuthException(AuthError.tooManyAttempts, detail);
      if (d.contains('expired') || d.contains('no active code')) throw AuthException(AuthError.codeExpired, detail);
      throw AuthException(badRequest, detail);
    }
    throw AuthException(AuthError.unknown, detail);
  }
}
