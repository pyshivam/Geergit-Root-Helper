import 'package:flutter/material.dart';

/// Material 3 themes, mirroring geergit's `core/theme/app_theme.dart`.
abstract final class AppTheme {
  /// Theme seed: the logo's navy, straight from GRH.svg (#003966).
  static const seed = Color(0xFF003966);

  /// Dark surfaces: navy-tinted slate ladder designed against the
  /// KernelSU manager's Material dark theme (which the user prefers
  /// over near-black) — background and cards clearly separated, hue
  /// tied to the brand navy. Flutter's `fromSeed` tonal-spot produces
  /// near-black flat surfaces, so the dark values are fixed here.
  static const _darkSurface = Color(0xFF161C28); // app background
  static const _darkSurfaceContainerLowest = Color(0xFF0E131C);
  static const _darkSurfaceContainerLow = Color(0xFF202936); // Card default
  static const _darkSurfaceContainer = Color(0xFF252E40);
  static const _darkSurfaceContainerHigh = Color(0xFF2B3547);
  static const _darkSurfaceContainerHighest = Color(0xFF333E52);

  static ThemeData fromBrightness(Brightness brightness) {
    var scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
    if (brightness == Brightness.dark) {
      scheme = scheme.copyWith(
        surface: _darkSurface,
        surfaceContainerLowest: _darkSurfaceContainerLowest,
        surfaceContainerLow: _darkSurfaceContainerLow,
        surfaceContainer: _darkSurfaceContainer,
        surfaceContainerHigh: _darkSurfaceContainerHigh,
        surfaceContainerHighest: _darkSurfaceContainerHighest,
      );
    }
    return ThemeData(
      useMaterial3: true,
      // Comfortaa (bundled, OFL): the app's display font.
      fontFamily: 'Comfortaa',
      colorScheme: scheme,
    );
  }
}
