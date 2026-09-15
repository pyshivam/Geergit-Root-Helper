import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/core/data/theme_prefs.dart';

void main() {
  test('theme mode round-trips through the prefs file', () async {
    final root = Directory.systemTemp;
    await ThemePrefs.save(root, ThemeMode.dark);
    expect(await ThemePrefs.load(root), ThemeMode.dark);

    await ThemePrefs.save(root, ThemeMode.light);
    expect(await ThemePrefs.load(root), ThemeMode.light);
  });

  test('missing or corrupt file falls back to system', () async {
    final root = Directory(
      '${Directory.systemTemp.path}/grh-theme-test-missing',
    )..createSync();
    expect(await ThemePrefs.load(root), ThemeMode.system);

    File('${root.path}/theme.txt').writeAsStringSync('garbage');
    expect(await ThemePrefs.load(root), ThemeMode.system);
  });
}
