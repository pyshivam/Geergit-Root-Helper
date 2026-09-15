import 'dart:io';

import 'package:flutter/material.dart';

/// Persists the Settings-tab theme choice in `<filesDir>/theme.txt`
/// (system|light|dark) so the choice survives restarts. File-based
/// rather than SharedPreferences: no plugin, same pattern as the
/// session logs.
class ThemePrefs {
  static const _fileName = 'theme.txt';

  static File _file(Directory filesRoot) =>
      File('${filesRoot.path}/$_fileName');

  static Future<ThemeMode> load(Directory filesRoot) async {
    try {
      final raw = (await _file(filesRoot).readAsString()).trim();
      return ThemeMode.values.asNameMap()[raw] ?? ThemeMode.system;
    } on IOException {
      return ThemeMode.system;
    }
  }

  static Future<void> save(Directory filesRoot, ThemeMode mode) async {
    await _file(filesRoot).writeAsString(mode.name, flush: true);
  }
}
