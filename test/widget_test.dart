import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/main.dart';

void main() {
  testWidgets('Home page shows device and kernel sections', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RootHelperApp());
      await Future<void>.delayed(
        const Duration(milliseconds: 50),
      ); // let the /proc read land
    });
    await tester.pumpAndSettle();

    expect(find.text('Geergit Root Helper'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Kernel version'), findsOneWidget);
  });
}
