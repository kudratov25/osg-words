import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:osg_app/data/db/app_database.dart';
import 'package:osg_app/main.dart';
import 'package:osg_app/services/auth_service.dart';

void main() {
  testWidgets('App boots and shows the Home tab', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({'onboarding_done': true, 'lang_source': 'en', 'lang_target': 'de'});
    final testDb = AppDatabase.forTesting(NativeDatabase.memory());
    await tester.pumpWidget(OsgApp(database: testDb, enableNotifications: false, enableNetwork: false, tokenStore: MemoryTokenStore(), enableGuide: false));
    await tester.pumpAndSettle();

    expect(find.text('Today'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
  });
}
