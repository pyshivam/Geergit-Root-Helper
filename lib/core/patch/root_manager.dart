/// Root managers that publish kernels as AnyKernel3 zips.
///
/// A WildKernels release carries one asset per manager for the same kernel
/// build (`…-KernelSU-AnyKernel3.zip`, `…-KernelSU-Next-AnyKernel3.zip`,
/// `…-ReSukiSU-AnyKernel3.zip`), so the patch page lists them and the user
/// picks the root to patch for.
class RootManager {
  const RootManager({required this.name, required this.needles});

  /// Display name, e.g. `KernelSU-Next`.
  final String name;

  /// Lowercase substrings that identify the build in an asset name.
  final List<String> needles;

  static const kernelSuNext = RootManager(
    name: 'KernelSU-Next',
    needles: ['kernelsu-next', 'ksun'],
  );
  static const kernelSu = RootManager(name: 'KernelSU', needles: ['kernelsu']);
  static const reSukiSU = RootManager(name: 'ReSukiSU', needles: ['resukisu']);
  static const sukiSU = RootManager(
    name: 'SukiSU-Ultra',
    needles: ['sukisu-ultra', 'sukisu'],
  );
  static const kowSU = RootManager(name: 'KowSU', needles: ['kowsu']);
  static const aPatch = RootManager(name: 'APatch', needles: ['apatch']);
  static const magisk = RootManager(name: 'Magisk', needles: ['magisk']);

  static const all = <RootManager>[
    kernelSu,
    kernelSuNext,
    kowSU,
    reSukiSU,
    sukiSU,
    aPatch,
    magisk,
  ];

  /// Identifies the manager behind an asset name, or null when the name
  /// matches none of the known builds. Manager APKs use underscores
  /// (`KernelSU_Next_v3.3.0-…-release.apk`), kernel zips hyphens, so both
  /// spellings are normalized before matching.
  ///
  /// Longest needle wins, so `kernelsu-next` never degrades to `kernelsu`
  /// and `resukisu` (a SukiSU fork) never to `sukisu`.
  static RootManager? of(String assetNameLower) {
    final name = assetNameLower.replaceAll('_', '-');
    RootManager? hit;
    var hitLength = 0;
    for (final manager in all) {
      for (final needle in manager.needles) {
        if (needle.length > hitLength && name.contains(needle)) {
          hit = manager;
          hitLength = needle.length;
        }
      }
    }
    return hit;
  }
}
