import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const RootHelperApp());
}

class RootHelperApp extends StatefulWidget {
  const RootHelperApp({super.key});

  @override
  State<RootHelperApp> createState() => _RootHelperAppState();
}

class _RootHelperAppState extends State<RootHelperApp> {
  final _themeMode = ValueNotifier(ThemeMode.system);

  late final GoRouter _router = buildRouter(themeMode: _themeMode);

  @override
  void dispose() {
    _themeMode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeMode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'Geergit Root Helper',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: AppTheme.fromBrightness(Brightness.light),
          darkTheme: AppTheme.fromBrightness(Brightness.dark),
          routerConfig: _router,
        );
      },
    );
  }
}
