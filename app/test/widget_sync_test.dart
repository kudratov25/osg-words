import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osg_app/notifications/widget_sync.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('updateWidget names the real Android provider class', () async {
    final calls = <MethodCall>[];
    const channel = MethodChannel('home_widget');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return true;
    });
    addTearDown(() => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(channel, null));

    await WidgetSync().sync(const []);

    final update = calls.singleWhere((c) => c.method == 'updateWidget');
    final args = Map<String, dynamic>.from(update.arguments as Map);
    expect(args['qualifiedAndroidName'], androidWidgetProvider);
  });

  test('that class really exists in the Kotlin sources and the manifest', () {
    final parts = androidWidgetProvider.split('.');
    final className = parts.removeLast();
    final file = File('android/app/src/main/kotlin/${parts.join('/')}/$className.kt');
    expect(file.existsSync(), isTrue, reason: file.path);
    expect(file.readAsStringSync(), contains('package ${parts.join('.')}'));
    expect(file.readAsStringSync(), contains('class $className'));
    final manifest = File('android/app/src/main/AndroidManifest.xml').readAsStringSync();
    expect(manifest, contains('android:name=".$className"'));
    final gradle = File('android/app/build.gradle.kts').readAsStringSync();
    expect(gradle, contains('namespace = "${parts.join('.')}"'), reason: '".X" in the manifest resolves against the namespace');
  });
}
