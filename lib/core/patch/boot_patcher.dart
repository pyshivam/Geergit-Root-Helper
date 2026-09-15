import 'dart:io';

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
      throw const BootPatcherException('No kernel found in this boot image');
    }
    return KernelRelease.parseFromKernelBytes(await _kernel.readAsBytes());
  }

  /// Overwrites the unpacked kernel with [kernelBytes] and repacks.
  Future<File> patch(List<int> kernelBytes) async {
    if (!_kernel.existsSync() || !_boot.existsSync()) {
      throw const BootPatcherException('Boot image is not unpacked yet');
    }
    await _kernel.writeAsBytes(kernelBytes, flush: true);
    if (output.existsSync()) output.deleteSync();
    await magiskboot.run(['repack', _bootName], workingDirectory: workDir.path);
    if (!output.existsSync()) {
      throw const BootPatcherException(
        'magiskboot did not produce new-boot.img',
      );
    }
    return output;
  }
}

class BootPatcherException implements Exception {
  const BootPatcherException(this.message);
  final String message;
  @override
  String toString() => message;
}
