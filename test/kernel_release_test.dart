import 'package:flutter_test/flutter_test.dart';
import 'package:geergit_root_helper/core/patch/anykernel_repo.dart';
import 'package:geergit_root_helper/core/patch/kernel_release.dart';
import 'package:geergit_root_helper/core/patch/root_manager.dart';

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

  group('RootManager.of', () {
    test('labels the GKI manager builds', () {
      String? manager(String name) => RootManager.of(name)?.name;
      const base = '6.1.157-android14-2025-12-';
      expect(manager('${base}kernelsu-anykernel3.zip'), 'KernelSU');
      expect(manager('${base}kernelsu-next-anykernel3.zip'), 'KernelSU-Next');
      expect(manager('${base}resukisu-anykernel3.zip'), 'ReSukiSU');
    });

    test('labels the OnePlus KSUN build', () {
      expect(
        RootManager.of(
          'ak3_op-ace-2-pro_a15_android13-5.15.149_ksun_33239_susfs_v2.2.0.zip',
        )?.name,
        'KernelSU-Next',
      );
    });

    test('labels manager APKs, which spell the name with underscores', () {
      expect(
        RootManager.of('kernelsu_next_v3.3.0-41-g39ba3821_33255-release.apk')
            ?.name,
        'KernelSU-Next',
      );
      expect(
        RootManager.of(
          'resukisu_v4.2.0-rc1-spoofed_35116-universal-release.apk',
        )?.name,
        'ReSukiSU',
      );
      expect(
        RootManager.of('kernelsu_v3.3.0-19-gc72f294e_32620-release.apk')?.name,
        'KernelSU',
      );
    });

    test('does not fold a fork into the project it forked', () {
      // Longest needle wins: `kernelsu-next` must not read as `kernelsu`,
      // `resukisu` must not read as `sukisu` (SukiSU-Ultra).
      expect(RootManager.of('x-kernelsu-next-y.zip')?.name, isNot('KernelSU'));
      expect(RootManager.of('x-resukisu-y.zip')?.name, 'ReSukiSU');
    });

    test('returns null for an asset that names no manager', () {
      expect(RootManager.of('nomount-metamodule.zip'), isNull);
    });
  });

  group('AnyKernelRepo.variants', () {
    const release = '6.1.157-android14-11-gbd23337e42e7-ab14791245';
    const kmi = 'android14-6.1';

    ReleaseAsset asset(String name, {String tag = 'r20'}) =>
        (name: name, size: 1024, tag: tag, url: 'https://example.test/$name');

    List<RemoteZip> variants(List<ReleaseAsset> assets) =>
        AnyKernelRepo.variants(assets, release: release, kmi: kmi);

    test('lists every root manager published for the kernel', () {
      final found = variants([
        asset('6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip'),
        asset('6.1.157-android14-2025-12-KernelSU-Next-AnyKernel3.zip'),
        asset('6.1.157-android14-2025-12-ReSukiSU-AnyKernel3.zip'),
      ]);
      expect(found.map((z) => z.manager), [
        'KernelSU',
        'KernelSU-Next',
        'ReSukiSU',
      ]);
      expect(found.every((z) => z.patchable), isTrue);
    });

    test('keeps the newest build when a manager repeats', () {
      final found = variants([
        asset('6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip', tag: 'r20'),
        asset('6.1.157-android14-2025-11-KernelSU-AnyKernel3.zip', tag: 'r19'),
      ]);
      expect(found.single.releaseTag, 'r20');
    });

    test('prefers the exact patch level over a KMI-only build', () {
      final found = variants([
        asset('6.1.130-android14-2025-06-KernelSU-AnyKernel3.zip', tag: 'r18'),
        asset('6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip', tag: 'r20'),
      ]);
      expect(found.single.releaseTag, 'r20');
    });

    test('drops assets that match neither the release nor the KMI', () {
      expect(variants([asset('NoMount-Metamodule.zip')]), isEmpty);
    });

    test('lists the manager apps and module zips of the newest release', () {
      final found = AnyKernelRepo.supportAssets([
        asset(
          'KernelSU_Next_v3.3.0-41-g39ba3821_33255-release.apk',
          tag: 'r20',
        ),
        asset(
          'KernelSU_Next_v3.3.0-41-g39ba3821-spoofed_33255-release.apk',
          tag: 'r20',
        ),
        asset('KernelSU_v3.3.0-19-gc72f294e_32620-release.apk', tag: 'r20'),
        asset('NoMount-Metamodule.zip', tag: 'r20'),
        asset('AIO-REJ.zip', tag: 'v2.0.0-r19'),
      ]);
      expect(found.map((a) => a.kind).toSet(), {
        SupportKind.managerApk,
        SupportKind.moduleZip,
      });
      expect(
        found
            .where((a) => a.kind == SupportKind.managerApk)
            .map((a) => a.manager),
        ['KernelSU-Next', 'KernelSU-Next', 'KernelSU'],
      );
      expect(found.where((a) => a.spoofed).map((a) => a.name), [
        'KernelSU_Next_v3.3.0-41-g39ba3821-spoofed_33255-release.apk',
      ]);
      // Manager apps first, then module zips; older releases drop out.
      expect(found.last.name, 'NoMount-Metamodule.zip');
      expect(found.any((a) => a.name == 'AIO-REJ.zip'), isFalse);
    });

    test('never offers kernel payloads as supporting downloads', () {
      final found = AnyKernelRepo.supportAssets([
        asset('6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip', tag: 'r20'),
        asset('WKSU-13780-android14-6.1.148-lts-KernelImages.zip', tag: 'r7'),
        asset('NoMount-Metamodule.zip', tag: 'r20'),
      ]);
      expect(found.single.name, 'NoMount-Metamodule.zip');
      for (final name in [
        '6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip',
        'wkSU-13780-android14-6.1.148-lts-KernelImages.zip',
        'WKSU-13861-android12-5.10.168-2023-04-boot-gz.img',
      ]) {
        expect(AnyKernelRepo.isKernelPayload(name.toLowerCase()), isTrue);
      }
    });

    test('keeps only the chosen manager app, plus every module zip', () {
      final all = AnyKernelRepo.supportAssets([
        asset(
          'KernelSU_Next_v3.3.0-41-g39ba3821_33255-release.apk',
          tag: 'r20',
        ),
        asset(
          'KernelSU_Next_v3.3.0-41-g39ba3821-spoofed_33255-release.apk',
          tag: 'r20',
        ),
        asset('KernelSU_v3.3.0-19-gc72f294e_32620-release.apk', tag: 'r20'),
        asset('NoMount-Metamodule.zip', tag: 'r20'),
      ]);
      expect(
        AnyKernelRepo.supportForManager(
          all,
          'KernelSU-Next',
        ).map((a) => a.name),
        [
          'KernelSU_Next_v3.3.0-41-g39ba3821-spoofed_33255-release.apk',
          'KernelSU_Next_v3.3.0-41-g39ba3821_33255-release.apk',
          'NoMount-Metamodule.zip',
        ],
      );
      expect(
        AnyKernelRepo.supportForManager(all, 'KernelSU').map((a) => a.name),
        [
          'KernelSU_v3.3.0-19-gc72f294e_32620-release.apk',
          'NoMount-Metamodule.zip',
        ],
      );
      // A legacy build with no manager token has no manager app published.
      expect(
        AnyKernelRepo.supportForManager(all, 'Bypass').map((a) => a.name),
        ['NoMount-Metamodule.zip'],
      );
    });

    test('returns nothing when a release carries no supporting downloads', () {
      expect(
        AnyKernelRepo.supportAssets([
          asset(
            '6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip',
            tag: 'r20',
          ),
        ]),
        isEmpty,
      );
    });

    test('marks a matching build that is no kernel swap unpatchable', () {
      final found = variants([asset('6.1.157-android14-2025-12-KernelSU.zip')]);
      expect(found.single.manager, 'KernelSU');
      expect(found.single.patchable, isFalse);
    });

    test('offers only the newest release that publishes for the kernel', () {
      final found = variants([
        asset('6.1.157-android14-2025-12-KernelSU-AnyKernel3.zip', tag: 'r20'),
        asset('6.1.157-android14-2025-12-ReSukiSU-AnyKernel3.zip', tag: 'r19'),
        asset('6.1.157-android14-2025-11-KernelSU-AnyKernel3.zip', tag: 'r18'),
      ]);
      expect(found.single.releaseTag, 'r20');
      expect(found.single.manager, 'KernelSU');
    });

    test('caps the KMI fallback to the newest matching release too', () {
      final found = variants([
        // Second tag stands in for a release with the same KMI but another
        // patch level; both are KMI-only matches for this boot image.
        asset('6.1.112-android14-2024-11-Bypass-AnyKernel3.zip', tag: 'r8'),
        asset('6.1.112-android14-2024-11-Normal-AnyKernel3.zip', tag: 'r8'),
        asset('6.1.115-android14-2024-12-Bypass-AnyKernel3.zip', tag: 'r3'),
      ]);
      expect(found.map((z) => z.manager), ['Bypass', 'Normal']);
      expect(found.every((z) => z.releaseTag == 'r8'), isTrue);
    });

    test('labels legacy builds that carry no manager token', () {
      expect(
        AnyKernelRepo.buildLabel('5.15.104-android13-2023-06-AnyKernel3.zip'),
        'Other build',
      );
      expect(
        AnyKernelRepo.buildLabel(
          '5.15.104-android13-2023-06-Bypass-AnyKernel3.zip',
        ),
        'Bypass',
      );
      expect(
        AnyKernelRepo.buildLabel(
          'WKSU-13974-SUSFS_v1.5.12-android14-6.1.112-2024-11-Bypass-BBG-AnyKernel3.zip',
        ),
        'Bypass-BBG',
      );
    });

    test('orders patchable builds first', () {
      final found = variants([
        asset('6.1.157-android14-2025-12-KernelSU.zip'),
        asset('6.1.157-android14-2025-12-ReSukiSU-AnyKernel3.zip'),
      ]);
      expect(found.map((z) => z.manager), ['ReSukiSU', 'KernelSU']);
      expect(found.first.patchable, isTrue);
      expect(found.last.patchable, isFalse);
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
