import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/main.dart';

/// The one-time flashing-risk disclaimer pops on first launch; tests
/// run against a fresh temp dir so it appears every time. Acknowledge
/// it and move on.
Future<void> dismissDisclaimer(WidgetTester tester) async {
  final button = find.text('I understand');
  if (button.evaluate().isNotEmpty) {
    await tester.tap(button);
    await tester.pumpAndSettle();
  }
}

void main() {
  testWidgets('Home tab shows device sections and nav tabs', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RootHelperApp(themeMode: ValueNotifier(ThemeMode.system)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await dismissDisclaimer(tester);
    expect(find.text('GRoot Helper'), findsOneWidget);
    expect(find.text('Kernel version'), findsOneWidget);
    expect(find.text('Model'), findsOneWidget);
    // The display title pushes the fingerprint row below the default
    // 800x600 test viewport — scroll it into view before asserting.
    await tester.scrollUntilVisible(find.text('Build fingerprint'), 100);
    expect(find.text('Build fingerprint'), findsOneWidget);
    expect(find.text('Patch'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('Patch CTA opens the patch flow', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RootHelperApp(themeMode: ValueNotifier(ThemeMode.system)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await dismissDisclaimer(tester);
    await tester.tap(find.text('Patch boot.img with AnyKernel zip'));
    await tester.pumpAndSettle();

    expect(find.text('Boot image first'), findsOneWidget);
    expect(find.text('Choose boot.img'), findsOneWidget);
  });

  testWidgets('Patch tab shows simple and advanced mode cards', (tester) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        RootHelperApp(themeMode: ValueNotifier(ThemeMode.system)),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pumpAndSettle();

    await dismissDisclaimer(tester);
    await tester.tap(find.text('Patch'));
    await tester.pumpAndSettle();

    expect(find.text('Simple — patch now'), findsOneWidget);
    expect(find.text('Advanced — bring your own zip'), findsOneWidget);
    expect(find.text('Flashing guide'), findsOneWidget);
  });
}
