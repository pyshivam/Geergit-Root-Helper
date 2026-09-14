import 'package:flutter/material.dart';

/// Material 3 themes, mirroring geergit's `core/theme/app_theme.dart`.
abstract final class AppTheme {
  static const seed = Color(0xFF8AADF4); // KernelSU-Next accent

  static ThemeData fromBrightness(Brightness brightness) => ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    ),
  );
}
