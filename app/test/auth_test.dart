import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/services/auth_service.dart';

import 'support/app_harness.dart';
import 'support/fake_backend.dart';

void main() {
  group('AuthService', () {
    late FakeBackend backend;
    late MemoryTokenStore store;
    late AuthService auth;

    setUp(() {
      SharedPreferences.setMockInitialValues({'telemetry_device_id': 'device-123'});
      backend = FakeBackend();
      store = MemoryTokenStore();
      auth = AuthService(client: backend.client, baseUrl: 'http://test', store: store);
    });

    test('config: enabled / disabled / offline / unconfigured', () async {
      expect(await auth.isEnabled(), isTrue);
      backend.authEnabled = false;
      expect(await auth.isEnabled(), isFalse);
      backend.online = false;
      expect(await auth.isEnabled(), isFalse);
      expect(await AuthService(baseUrl: '', store: store).isEnabled(), isFalse);
    });

    test('email -> code -> signed in, token stored securely, device linked', () async {
      await auth.startEmail('  Me@Example.com ');
      final start = backend.requests.firstWhere((r) => r.url.path == '/auth/email/start');
      expect(start.body, '{"email":"me@example.com"}');

      await auth.verifyCode('me@example.com', '123456');
      expect(auth.signedIn, isTrue);
      expect(auth.email, 'me@example.com');
      expect(store.values['auth_token'], startsWith('osgu_'));
      expect(backend.verifyBodies.single['device_id'], 'device-123');

      // Survives a restart.
      final again = AuthService(client: backend.client, baseUrl: 'http://test', store: store);
      await again.load();
      expect(again.signedIn, isTrue);
      expect(again.email, 'me@example.com');
    });

    test('invalid email is rejected locally', () async {
      expect(() => auth.startEmail('not-an-email'),
          throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.invalidEmail)));
      expect(backend.requests, isEmpty);
    });

    test('wrong code -> wrongCode (not "too many"), stays signed out', () async {
      await auth.startEmail('me@example.com');
      await expectLater(auth.verifyCode('me@example.com', '000000'),
          throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.wrongCode)));
      expect(auth.signedIn, isFalse);
      expect(store.values, isEmpty);
    });

    test('offline -> network error', () async {
      backend.online = false;
      await expectLater(auth.startEmail('me@example.com'),
          throwsA(isA<AuthException>().having((e) => e.error, 'error', AuthError.network)));
    });

    test('sign out revokes the session and forgets the token', () async {
      await auth.verifyCode('me@example.com', '123456');
      await auth.signOut();
      expect(backend.loggedOut, isTrue);
      expect(auth.signedIn, isFalse);
      expect(store.values, isEmpty);
    });

    test('sign out works offline too', () async {
      await auth.verifyCode('me@example.com', '123456');
      backend.online = false;
      await auth.signOut();
      expect(auth.signedIn, isFalse);
    });

    test('delete account calls DELETE /me with the token', () async {
      await auth.verifyCode('me@example.com', '123456');
      await auth.deleteAccount();
      expect(backend.deleted, isTrue);
      final req = backend.requests.lastWhere((r) => r.url.path == '/me');
      expect(req.method, 'DELETE');
      expect(req.headers['Authorization'], startsWith('Bearer osgu_'));
      expect(auth.signedIn, isFalse);
    });

    test('delete account offline keeps the account (and says so)', () async {
      await auth.verifyCode('me@example.com', '123456');
      backend.online = false;
      await expectLater(auth.deleteAccount(), throwsA(isA<AuthException>()));
      expect(auth.signedIn, isTrue);
    });
  });

  testWidgets('Settings -> Account: sign in, sign out, delete with confirm', (tester) async {
    final backend = FakeBackend();
    await pumpOsgApp(tester, backend: backend, prefs: donePrefs());
    await tapAndSettle(tester, find.text('Settings'));

    expect(find.text('Account'), findsOneWidget);
    await tester.enterText(find.byKey(const Key('account-email')), 'me@example.com');
    await tapAndSettle(tester, find.byKey(const Key('account-send')));
    expect(find.text('We sent a 6-digit code to me@example.com.'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('account-code')), '111111');
    await tapAndSettle(tester, find.byKey(const Key('account-verify')));
    expect(find.text("That code didn't work. Check it and try again."), findsOneWidget);

    await tester.enterText(find.byKey(const Key('account-code')), '123456');
    await tapAndSettle(tester, find.byKey(const Key('account-verify')));
    expect(find.text('Signed in as me@example.com'), findsOneWidget);

    await tapAndSettle(tester, find.byKey(const Key('account-signout')));
    expect(backend.loggedOut, isTrue);
    expect(find.byKey(const Key('account-email')), findsOneWidget);

    // Sign in again and delete.
    await tester.enterText(find.byKey(const Key('account-email')), 'me@example.com');
    await tapAndSettle(tester, find.byKey(const Key('account-send')));
    await tester.enterText(find.byKey(const Key('account-code')), '123456');
    await tapAndSettle(tester, find.byKey(const Key('account-verify')));
    await tapAndSettle(tester, find.byKey(const Key('account-delete')));
    expect(find.text('Delete account?'), findsOneWidget);
    await tapAndSettle(tester, find.byKey(const Key('account-delete-confirm')));
    expect(backend.deleted, isTrue);
    expect(find.text('Account deleted.'), findsOneWidget);
    await unmountApp(tester);
  });

  testWidgets('Account section hidden when the server has accounts disabled', (tester) async {
    final backend = FakeBackend()..authEnabled = false;
    await pumpOsgApp(tester, backend: backend, prefs: donePrefs());
    await tapAndSettle(tester, find.text('Settings'));
    expect(find.text('Account'), findsNothing);
    expect(find.text('Languages'), findsOneWidget);
    await unmountApp(tester);
  });
}
