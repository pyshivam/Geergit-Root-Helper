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

  testWidgets('Patch CTA opens the patch flow', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RootHelperApp());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patch boot.img with AnyKernel zip'));
    await tester.pumpAndSettle();

    expect(find.text('Boot image first'), findsOneWidget);
    expect(find.text('Choose boot.img'), findsOneWidget);
  });

  testWidgets('Patch tab shows simple and advanced mode cards', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const RootHelperApp());
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await tester.tap(find.text('Patch'));
    await tester.pumpAndSettle();

    expect(find.text('Simple — patch now'), findsOneWidget);
    expect(find.text('Advanced — bring your own zip'), findsOneWidget);
    expect(find.text('Flashing guide'), findsOneWidget);
  });
}
