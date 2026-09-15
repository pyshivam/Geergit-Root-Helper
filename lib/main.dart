import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'core/data/device_info.dart';
import 'core/logging/app_logger.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppLogger.init();
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
