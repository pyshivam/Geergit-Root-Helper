import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/data/device_info.dart';
import 'core/data/theme_prefs.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
  final filesRoot =
      AppLogger.currentFile?.parent.parent ?? Directory.systemTemp;
  final themeMode = ValueNotifier(await ThemePrefs.load(filesRoot));
  themeMode.addListener(() => ThemePrefs.save(filesRoot, themeMode.value));
  final device = await DeviceInfo.fetch();
  AppLogger.log(
    'Device',
    '${device.manufacturer} ${device.model}, Android ${device.androidRelease} '
        '(SDK ${device.sdkInt}), abis ${device.abis}',
  );
  AppLogger.log('Device', 'kernel: ${device.kernelVersion}');
  AppLogger.log('Device', 'fingerprint: ${device.fingerprint}');

  // File-based logging exists for shared-APK users with no adb: make sure
  // hard crashes leave their stack in the session log too.
  final origOnError = FlutterError.onError;
  FlutterError.onError = (details) {
    AppLogger.log('FATAL', details.exceptionAsString());
    AppLogger.log('FATAL', '${details.stack ?? 'no stack'}');
    origOnError?.call(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.log('FATAL', 'uncaught: $error');
    AppLogger.log('FATAL', '$stack');
    return true;
  };

  runApp(RootHelperApp(themeMode: themeMode));
}

class RootHelperApp extends StatefulWidget {
  const RootHelperApp({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  @override
  State<RootHelperApp> createState() => _RootHelperAppState();
}

class _RootHelperAppState extends State<RootHelperApp> {
  late final GoRouter _router = buildRouter(themeMode: widget.themeMode);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: widget.themeMode,
      builder: (context, mode, _) {
        return MaterialApp.router(
          title: 'GRoot Helper',
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
