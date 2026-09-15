import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/core/logging/app_logger.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'session log gets timestamped lines and the bundle zip contains it',
    () async {
      // AppLogger resolves its dir from the device channel, unavailable in
      // tests — so point it at a temp root through the only seam we have:
      // run off-Android (Platform.isAndroid is false under `dart test`) and
      // let the systemTemp fallback carry it. To keep this hermetic, patch
      // the temp dir via the TMPDIR-style override the platform gives us is
      // overkill; instead assert on the live systemTemp file directly.
      final logs = Directory('${Directory.systemTemp.path}/logs')
        ..createSync(recursive: true);

      // Re-init by hand: the public surface is static, so exercise the
      // file it creates. Clean any earlier test residue first.
      for (final f in logs.listSync().whereType<File>()) {
        f.deleteSync();
      }

      await AppLogger.init();
      final session = AppLogger.currentFile!;
      expect(session.path, contains('${logs.path}/session-'));
      expect(session.readAsStringSync(), contains('===== SESSION'));

      AppLogger.log('TestTag', 'hello log');
      final contents = session.readAsStringSync();
      expect(contents, contains('TestTag: hello log'));
      expect(
        RegExp(r'\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}\.\d{3} TestTag')
            .hasMatch(contents),
        isTrue,
      );

      final bundle = await AppLogger.exportBundle();
      expect(bundle, isNotNull);
      final names = ZipDecoder()
          .decodeBytes(bundle!.readAsBytesSync())
          .files
          .map((f) => f.name)
          .toList();
      expect(
        names.any((n) => n.startsWith('session-') && n.endsWith('.log')),
        isTrue,
      );
    },
  );

  test('old sessions beyond the cap are pruned', () async {
    final logs = Directory('${Directory.systemTemp.path}/logs')
      ..createSync(recursive: true);
    for (final f in logs.listSync().whereType<File>()) {
      f.deleteSync();
    }
    // Seed 12 stale session files older than the cap.
    for (var i = 0; i < 12; i++) {
      File('${logs.path}/session-2026010$i-120000.log')
          .writeAsStringSync('old');
    }

    await AppLogger.init();
    final remaining = logs
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList();
    // Prune runs before the fresh session is created: 12 seeded → 10
    // kept, then the new session is added → 11 on disk.
    expect(remaining.length, 11);
    expect(remaining.any((f) => f.path.contains('session-20260100-')), isFalse);
    expect(
      remaining.any((f) => f.readAsStringSync().contains('===== SESSION')),
      isTrue,
    );
  });
}
