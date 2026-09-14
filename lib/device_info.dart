import 'dart:io';

import 'package:flutter/services.dart';

/// Device and kernel facts shown on the home page.
class DeviceInfo {
  const DeviceInfo({
    required this.model,
    required this.manufacturer,
    required this.androidRelease,
    required this.sdkInt,
    required this.abis,
    required this.kernelVersion,
    required this.fingerprint,
  });

  final String model;
  final String manufacturer;
  final String androidRelease;
  final int sdkInt;
  final String abis;
  final String kernelVersion;
  final String fingerprint;

  static const _channel = MethodChannel(
    'com.geerxlabs.geergitroothelper/device_info',
  );
  static const _unavailable = 'Unavailable on this platform';

  static Future<DeviceInfo> fetch() async {
    final kernel = await _kernelVersion();
    Map<dynamic, dynamic>? android;
    if (Platform.isAndroid) {
      try {
        android = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'getDeviceInfo',
        );
      } on PlatformException {
        android = null; // emulator/host without the handler
      }
    }
    if (android == null) {
      return DeviceInfo(
        model: _unavailable,
        manufacturer: _unavailable,
        androidRelease: _unavailable,
        sdkInt: 0,
        abis: _unavailable,
        kernelVersion: kernel,
        fingerprint: _unavailable,
      );
    }
    return DeviceInfo(
      model: android['model'] as String? ?? _unavailable,
      manufacturer: android['manufacturer'] as String? ?? _unavailable,
      androidRelease: android['androidRelease'] as String? ?? _unavailable,
      sdkInt: android['sdkInt'] as int? ?? 0,
      abis: android['abis'] as String? ?? _unavailable,
      kernelVersion: kernel,
      fingerprint: android['fingerprint'] as String? ?? _unavailable,
    );
  }

  static Future<String> _kernelVersion() async {
    try {
      final raw = await File('/proc/version').readAsString();
      return raw.split('(').first.trim();
    } on IOException {
      return Platform.operatingSystemVersion;
    }
  }
}
