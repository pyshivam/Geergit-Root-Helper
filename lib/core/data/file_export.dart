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
}
