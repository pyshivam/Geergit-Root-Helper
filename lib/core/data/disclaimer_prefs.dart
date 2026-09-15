import 'dart:io';

/// Tracks whether the user has acknowledged the flashing-risk disclaimer.
/// Persisted as `<filesDir>/disclaimer.txt`; absent file = not yet
/// acknowledged. Same file-based pattern as ThemePrefs.
class DisclaimerPrefs {
  static const _fileName = 'disclaimer.txt';

  static File _file(Directory filesRoot) =>
      File('${filesRoot.path}/$_fileName');

  static Future<bool> isAcknowledged(Directory filesRoot) async =>
      _file(filesRoot).existsSync();

  static Future<void> acknowledge(Directory filesRoot) async {
    await _file(filesRoot).writeAsString('acknowledged', flush: true);
  }
}
