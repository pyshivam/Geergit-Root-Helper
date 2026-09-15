import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:geergit_root_helper/core/patch/anykernel_zip.dart';
import 'package:geergit_root_helper/core/patch/boot_patcher.dart';

/// Regression: the flow once passed the WHOLE AnyKernel zip to
/// BootPatcher.patch instead of the extracted kernel entry — the repack
/// "succeeded" and produced a 67MB image whose kernel was a zip
/// (PK\x03\x04), which bootlooped the Pixel 7 it was flashed to.
void main() {
  /// Minimal bytes shaped like a raw ARM64 kernel Image: 64-byte header
  /// with the ARM64 magic (u32 LE 0x644D5241) at offset 56, then padding.
  List<int> fakeArm64Image(int size) {
    final bytes = List<int>.filled(size, 0);
    bytes[56] = 0x41; // 'A'
    bytes[57] = 0x52; // 'R'
    bytes[58] = 0x4D; // 'M'
    bytes[59] = 0x64; // 'd'
    return bytes;
  }

  test('looksLikeKernelImage accepts an ARM64 Image and rejects zips', () {
    expect(looksLikeKernelImage(fakeArm64Image(4096)), isTrue);
    // The exact payload that bootlooped the device: a zip file.
    final zipBytes = ZipEncoder().encode(
      Archive()..addFile(ArchiveFile('Image', 4, fakeArm64Image(4096))),
    );
    expect(looksLikeKernelImage(zipBytes), isFalse);
    expect(looksLikeKernelImage([1, 2, 3]), isFalse);
    expect(looksLikeKernelImage(List<int>.filled(4096, 0)), isFalse);
  });

  test('extracted AnyKernel kernel entry passes the payload guard', () {
    final archive = Archive()
      ..addFile(ArchiveFile('anykernel.sh', 2, [35, 10]))
      ..addFile(ArchiveFile('Image', 4096, fakeArm64Image(4096)));
    final zip = AnyKernelZip.read(ZipEncoder().encode(archive));
    expect(looksLikeKernelImage(zip.kernelBytes), isTrue);
    // ...while the full zip archive does not — the original bug.
    expect(looksLikeKernelImage(ZipEncoder().encode(archive)), isFalse);
  });
}
