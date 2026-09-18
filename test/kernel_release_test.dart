import 'package:flutter_test/flutter_test.dart';
import 'package:geergit_root_helper/core/patch/anykernel_repo.dart';
import 'package:geergit_root_helper/core/patch/kernel_release.dart';

void main() {
  group('KernelRelease.parse', () {
    test('parses uname-style GKI release', () {
      final k = KernelRelease.parse('6.1.57-android14-8-gb6a3ee44fd2c-ab124');
      expect(k, isNotNull);
      expect(k!.kmi, 'android14-6.1');
      expect(k.release, '6.1.57-android14-8-gb6a3ee44fd2c-ab124');
    });

    test('parses older 5.x android12 release', () {
      final k = KernelRelease.parse('5.10.198-android12-9-00040-gc1b0b7c6a4d3');
      expect(k, isNotNull);
      expect(k!.kmi, 'android12-5.10');
    });

    test('returns null for a non-GKI string', () {
      expect(KernelRelease.parse('4.19.191-perf-gabcdef'), isNull);
      expect(KernelRelease.parse('not a version'), isNull);
    });

    test('baseRelease strips the build suffix', () {
      final k = KernelRelease.parse(
        '6.1.157-android14-11-gbd23337e42e7-ab14791245',
      );
      expect(k!.baseRelease, '6.1.157-android14');
      expect(
        KernelRelease.parse('5.10.198-android12-9-00040-gc1b0b7c6a4d3')!
            .baseRelease,
        '5.10.198-android12',
      );
    });
  });

  group('KernelRelease.parseFromKernelBytes', () {
    List<int> kernelWithVersion(String release) {
      final marker = 'Linux version ';
      final tail = '$release (build-user@host) #1 SMP PREEMPT';
      return [...marker.codeUnits, ...tail.codeUnits, 0, ...List.filled(64, 0)];
    }

    test('finds version string in raw kernel bytes', () {
      final k = KernelRelease.parseFromKernelBytes(
        kernelWithVersion('6.1.99-android15-3-test'),
      );
      expect(k, isNotNull);
      expect(k!.kmi, 'android15-6.1');
    });

    test('stops at the null terminator', () {
      final bytes = kernelWithVersion('5.15.123-android14-1-x');
      final k = KernelRelease.parseFromKernelBytes(bytes);
      expect(k!.release, '5.15.123-android14-1-x');
    });

    test('skips the printk format string printed ahead of the banner', () {
      // A real Image (e.g. lz4_legacy GKI) holds `Linux version %s (%s)`
      // before `linux_banner`; the format string alone must not count.
      final bytes = [
        ...'Linux version '.codeUnits,
        ...'%s (%s)'.codeUnits,
        0,
        ...kernelWithVersion('5.15.189-android13-8-00004-g1c3825f8ac0a'),
      ];
      final k = KernelRelease.parseFromKernelBytes(bytes);
      expect(k, isNotNull);
      expect(k!.kmi, 'android13-5.15');
      expect(k.release, '5.15.189-android13-8-00004-g1c3825f8ac0a');
    });

    test('returns null when no version string exists', () {
      expect(KernelRelease.parseFromKernelBytes(List.filled(256, 0)), isNull);
    });
  });

  group('AnyKernelRepo.nameMatchesKmi', () {
    test('matches real WildKernels asset naming', () {
      expect(
        AnyKernelRepo.nameMatchesKmi(
          '6.1.99-android14-2025-05-kernelsu-anykernel3.zip',
          'android14-6.1',
        ),
        isTrue,
      );
      expect(
        AnyKernelRepo.nameMatchesKmi(
          '5.10.226-android13-kernelsu-next-anykernel3.zip',
          'android13-5.10',
        ),
        isTrue,
      );
    });

    test('rejects wrong android level or kernel version', () {
      expect(
        AnyKernelRepo.nameMatchesKmi(
          '6.1.99-android14-kernelsu-anykernel3.zip',
          'android15-6.1',
        ),
        isFalse,
      );
      expect(
        AnyKernelRepo.nameMatchesKmi(
          '6.6.30-android15-kernelsu-anykernel3.zip',
          'android15-6.1',
        ),
        isFalse,
      );
    });

    test('major.minor does not match a different minor via prefix', () {
      // '6.1.' must not match inside '6.10.' — version prefix is dot-bound.
      expect(
        AnyKernelRepo.nameMatchesKmi(
          '6.10.0-android14-kernelsu-anykernel3.zip',
          'android14-6.1',
        ),
        isFalse,
      );
    });
  });

  group('AnyKernelRepo.nameMatchesRelease', () {
    const release = '6.1.157-android14-11-gbd23337e42e7-ab14791245';

    test('matches exact patch level', () {
      expect(
        AnyKernelRepo.nameMatchesRelease(
          '6.1.157-android14-2025-12-kernelsu-anykernel3.zip',
          release,
        ),
        isTrue,
      );
    });

    test('rejects same KMI but different patch level', () {
      expect(
        AnyKernelRepo.nameMatchesRelease(
          '6.1.112-android14-2024-11-kernelsu-anykernel3.zip',
          release,
        ),
        isFalse,
      );
    });

    test('rejects same patch level but wrong android level', () {
      expect(
        AnyKernelRepo.nameMatchesRelease(
          '6.1.157-android15-kernelsu-anykernel3.zip',
          release,
        ),
        isFalse,
      );
    });

    test('ignores trailing build suffixes of the release', () {
      expect(KernelRelease.parse(release)!.kmi, 'android14-6.1');
    });
  });
}
