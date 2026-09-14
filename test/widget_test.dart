import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/main.dart';

void main() {
  testWidgets('Home tab shows device sections and nav tabs', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RootHelperApp());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    expect(find.text('Geergit Root Helper'), findsOneWidget);
    expect(find.text('Device'), findsOneWidget);
    expect(find.text('Software'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    expect(find.text('Kernel version'), findsOneWidget);
    expect(find.text('Build fingerprint'), findsOneWidget);
    expect(find.text('Patch'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Patch CTA opens the step-by-step guide', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RootHelperApp());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patch boot.img with AnyKernel zip'));
    await tester.pumpAndSettle();

    expect(find.text('Prepare'), findsOneWidget);
    expect(find.text('Get the right zip'), findsOneWidget);
    expect(find.text('Flash'), findsOneWidget);
    expect(find.text('Verify'), findsOneWidget);
  });
}
