import 'dart:io';

import 'package:flutter/services.dart';

/// Platform side of the `exportFile` channel method (SAF save on Android).
class FileExport {
  static const _channel = MethodChannel(
    'com.geerxlabs.geergitroothelper/device_info',
  );

  /// Copies [sourcePath] to a user-picked location.
  /// Returns the destination URI, or null when cancelled / off-Android.
  static Future<String?> export({
    required String sourcePath,
    String displayName = 'new-boot.img',
  }) async {
    if (!Platform.isAndroid) return null;
    try {
      return await _channel.invokeMethod<String>('exportFile', {
        'sourcePath': sourcePath,
        'displayName': displayName,
      });
    } on PlatformException {
      return null;
    }
  }

  /// Opens the system document picker and copies the picked document to
  /// [targetPath] in the app workspace. Returns the target path, null when
  /// cancelled, or null with [pickError] set when the pick failed (e.g. a
  /// stale picker result the provider can no longer open).
  static String? pickError;

  static Future<String?> pickTo({required String targetPath}) async {
    if (!Platform.isAndroid) return null;
    pickError = null;
    try {
      return await _channel.invokeMethod<String>('pickFile', {
        'targetPath': targetPath,
      });
    } on PlatformException catch (e) {
      pickError = e.message ?? e.code;
      return null;
    }
  }
}
