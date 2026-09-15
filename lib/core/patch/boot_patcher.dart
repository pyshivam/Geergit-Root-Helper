import 'dart:io';

import '../logging/app_logger.dart';
import 'kernel_release.dart';
import 'magiskboot.dart';

/// Unpack → replace kernel → repack. Runs entirely in [workDir] with no
/// root; the output `new-boot.img` is what the user flashes from fastboot.
class BootPatcher {
  BootPatcher({required this.magiskboot, required this.workDir});

  final Magiskboot magiskboot;
  final Directory workDir;

  static const _bootName = 'boot.img';
  static const _kernelName = 'kernel';
  static const _outputName = 'new-boot.img';

  File get _boot => File('${workDir.path}/$_bootName');
  File get _kernel => File('${workDir.path}/$_kernelName');
  File get output => File('${workDir.path}/$_outputName');

  /// Copies [bootImage] into the work dir and unpacks it.
  /// Returns the kernel version found inside, or null when unparseable.
  Future<KernelRelease?> unpackBootImage(File bootImage) async {
    workDir.createSync(recursive: true);
    await bootImage.copy(_boot.path);
    await magiskboot.run(['unpack', _bootName], workingDirectory: workDir.path);
    if (!_kernel.existsSync()) {
      AppLogger.log('BootPatcher', 'unpack produced no kernel');
      throw const BootPatcherException('No kernel found in this boot image');
    }
    final release = KernelRelease.parseFromKernelBytes(
      await _kernel.readAsBytes(),
    );
    AppLogger.log(
      'BootPatcher',
      'unpacked boot.img (${bootImage.lengthSync()} bytes), kernel: '
          '${release?.release ?? 'unparseable'}',
    );
    return release;
  }

  /// Overwrites the unpacked kernel with [kernelBytes] and repacks.
  Future<File> patch(List<int> kernelBytes) async {
    if (!_kernel.existsSync() || !_boot.existsSync()) {
      throw const BootPatcherException('Boot image is not unpacked yet');
    }
    if (!looksLikeKernelImage(kernelBytes)) {
      throw const BootPatcherException(
        'Kernel payload is not an ARM64 kernel image '
        '(a zip or other file was passed instead of the zip\'s kernel entry)',
      );
    }
    await _kernel.writeAsBytes(kernelBytes, flush: true);
    if (output.existsSync()) output.deleteSync();
    await magiskboot.run(['repack', _bootName], workingDirectory: workDir.path);
    if (!output.existsSync()) {
      throw const BootPatcherException(
        'magiskboot did not produce new-boot.img',
      );
    }
    AppLogger.log(
      'BootPatcher',
      'repacked: ${output.path} (${output.lengthSync()} bytes)',
    );
    return output;
  }
}

/// ARM64 kernel Image magic: u32 LE 0x644D5241 ("ARM\x64") at offset 56
/// of the 64-byte ARM64 Image header. GKI/AnyKernel kernels ship as raw
/// ARM64 Images, so this is the payload we expect to write into boot.
bool looksLikeKernelImage(List<int> bytes) {
  if (bytes.length < 64) return false;
  const arm64Magic = 0x644D5241; // 'ARMd'
  final magic =
      bytes[56] | (bytes[57] << 8) | (bytes[58] << 16) | (bytes[59] << 24);
  return magic == arm64Magic;
}

class BootPatcherException implements Exception {
  const BootPatcherException(this.message);
  final String message;
  @override
  String toString() => message;
}
