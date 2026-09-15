import 'dart:typed_data';

import 'package:archive/archive.dart';

import 'kernel_release.dart';

/// An AnyKernel zip's kernel payload.
///
/// AnyKernel3 zips carry the kernel image under a handful of conventional
/// names; we take the first match and parse its version string for the
/// KMI comparison.
class AnyKernelZip {
  AnyKernelZip._({required this.kernelBytes, required this.kernelEntryName});

  final List<int> kernelBytes;
  final String kernelEntryName;

  static const _kernelNames = ['image', 'zimage', 'kernel'];

  KernelRelease? get kernelRelease =>
      KernelRelease.parseFromKernelBytes(kernelBytes);

  /// Reads [zipBytes] and extracts the kernel entry.
  /// Throws [AnyKernelZipException] when no kernel is found.
  static AnyKernelZip read(List<int> zipBytes) {
    final archive = ZipDecoder().decodeBytes(zipBytes, verify: false);
    ArchiveFile? kernel;
    for (final file in archive.files) {
      if (!file.isFile) continue;
      final base = file.name.split('/').last.toLowerCase();
      if (_kernelNames.contains(base)) {
        kernel = file;
        break;
      }
    }
    final content = kernel?.content;
    if (kernel == null || content == null || content.isEmpty) {
      throw const AnyKernelZipException(
        'No kernel (Image/zImage/kernel) found in this zip — is it an AnyKernel zip?',
      );
    }
    return AnyKernelZip._(
      kernelBytes: Uint8List.fromList(content),
      kernelEntryName: kernel.name.split('/').last,
    );
  }
}

class AnyKernelZipException implements Exception {
  const AnyKernelZipException(this.message);
  final String message;
  @override
  String toString() => message;
}
