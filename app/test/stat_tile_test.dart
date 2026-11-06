import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:osg_app/widgets/stat_tile.dart';

void main() {
  for (final scale in [1.0, 1.3]) {
    testWidgets('stat tiles in a row are the same size (text scale $scale)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(size: const Size(360, 800), textScaler: TextScaler.linear(scale)),
          child: const Scaffold(
            body: Row(children: [
              StatTile(label: "O'rganilgan so'zlar", value: '36'),
              SizedBox(width: 12),
              StatTile(label: 'Bugun bajarildi', value: '0'),
              SizedBox(width: 12),
              StatTile(label: 'Ketma-ketlik', value: '1234 kun'),
            ]),
          ),
        ),
      ));
      final sizes = tester.widgetList(find.byType(StatTile)).map((w) => tester.getSize(find.byWidget(w))).toList();
      expect(sizes.map((s) => s.height).toSet(), hasLength(1), reason: '$sizes');
      expect(sizes.map((s) => s.width.round()).toSet(), hasLength(1), reason: '$sizes');
      // Numbers centred on the same line.
      final centres = ['36', '0', '1234 kun'].map((t) => tester.getCenter(find.text(t)).dy.round()).toSet();
      expect(centres, hasLength(1));
      expect(tester.takeException(), isNull, reason: 'no overflow');
    });
  }
}
