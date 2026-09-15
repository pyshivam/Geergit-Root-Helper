import 'dart:io';

import 'package:flutter/services.dart';

import '../logging/app_logger.dart';

/// Runs the magiskboot bundled with the APK as `libmagiskboot.so`.
///
/// Android W^X (SELinux) blocks executing downloaded binaries from the
/// app files dir (`execute_no_trans` denied), so the prebuilt WildKernels
/// nightly binaries ship as jniLibs — files extracted from the APK into
/// nativeLibraryDir are `apk_data_file` and executable. Desktop platforms
/// have no bundled binary and are unsupported.
class Magiskboot {
  Magiskboot({String? abis}) : _abis = abis ?? '';

  final String _abis;

  static const _channel = MethodChannel(
    'com.geerxlabs.geergitroothelper/device_info',
  );

  bool _resolved = false;
  late final String _binaryPath;

  Future<String> ensure() async {
    if (_resolved) return _binaryPath;
    if (!Platform.isAndroid) {
      throw const MagiskbootException(
        'Bundled magiskboot is Android-only — patch on the phone',
      );
    }
    try {
      final dir = await _channel.invokeMethod<String>('getNativeLibraryDir');
      if (dir == null || dir.isEmpty) {
        throw const MagiskbootException('nativeLibraryDir is unavailable');
      }
      final bin = File('$dir/libmagiskboot.so');
      if (!bin.existsSync()) {
        throw MagiskbootException('libmagiskboot.so missing for ABI: $_abis');
      }
      _binaryPath = bin.path;
      _resolved = true;
      return _binaryPath;
    } on PlatformException catch (e) {
      throw MagiskbootException('nativeLibraryDir failed: ${e.message}');
    }
  }

  /// Runs magiskboot with [args] in [workingDirectory].
  /// Throws [MagiskbootException] on non-zero exit.
  Future<void> run(
    List<String> args, {
    required String workingDirectory,
  }) async {
    final bin = await ensure();
    AppLogger.log('Magiskboot', 'exec ${bin.split('/').last} ${args.join(' ')}');
    final result = await Process.run(
      bin,
      args,
      workingDirectory: workingDirectory,
    );
    AppLogger.log(
      'Magiskboot',
      'exit ${result.exitCode}'
          '${result.stderr.toString().trim().isEmpty ? '' : ' stderr: ${result.stderr.toString().trim()}'}}',
    );
    if (result.exitCode != 0) {
      final err = (result.stderr as String?)?.trim();
      throw MagiskbootException(
        'magiskboot ${args.first} failed (exit ${result.exitCode})${err == null || err.isEmpty ? '' : ': $err'}',
      );
    }
  }
}

class MagiskbootException implements Exception {
  const MagiskbootException(this.message);
  final String message;
  @override
  String toString() => message;
}
