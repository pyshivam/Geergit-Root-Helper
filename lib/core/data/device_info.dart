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
    // /proc/version is filterable (root-helper stealth stacks rewrite it);
    // uname().release matches what KernelSU manager shows.
    if (!Platform.isAndroid) {
      return DeviceInfo(
        model: _unavailable,
        manufacturer: _unavailable,
        androidRelease: _unavailable,
        sdkInt: 0,
        abis: _unavailable,
        kernelVersion: await _kernelVersion(),
        fingerprint: _unavailable,
      );
    }
    try {
      final android = await _channel.invokeMethod<Map<dynamic, dynamic>>(
        'getDeviceInfo',
      );
      if (android != null) {
        return DeviceInfo(
          model: android['model'] as String? ?? _unavailable,
          manufacturer: android['manufacturer'] as String? ?? _unavailable,
          androidRelease: android['androidRelease'] as String? ?? _unavailable,
          sdkInt: android['sdkInt'] as int? ?? 0,
          abis: android['abis'] as String? ?? _unavailable,
          kernelVersion:
              android['kernelRelease'] as String? ?? await _kernelVersion(),
          fingerprint: android['fingerprint'] as String? ?? _unavailable,
        );
      }
    } on PlatformException {
      // fall through to the /proc/version fallback
    }
    return DeviceInfo(
      model: _unavailable,
      manufacturer: _unavailable,
      androidRelease: _unavailable,
      sdkInt: 0,
      abis: _unavailable,
      kernelVersion: await _kernelVersion(),
      fingerprint: _unavailable,
    );
  }

  /// Internal-storage path for the device-verification report, or null
  /// off-Android / without the handler.
  static Future<String?> reportPath() async {
    if (!Platform.isAndroid) return null;
    try {
      final dir = await _channel.invokeMethod<String>('getFilesDir');
      return dir == null ? null : '$dir/report.txt';
    } on PlatformException {
      return null;
    }
  }

  String toReport() =>
      '''
GRoot Helper device report
model: $model
manufacturer: $manufacturer
androidRelease: $androidRelease
sdkInt: $sdkInt
abis: $abis
kernelVersion: $kernelVersion
fingerprint: $fingerprint
''';

  static Future<String> _kernelVersion() async {
    try {
      final raw = await File('/proc/version').readAsString();
      return raw.split('(').first.trim();
    } on IOException {
      return Platform.operatingSystemVersion;
    }
  }
}
