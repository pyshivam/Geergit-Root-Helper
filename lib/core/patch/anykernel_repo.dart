import 'dart:convert';

import 'package:http/http.dart' as http;

import '../logging/app_logger.dart';
import 'kernel_release.dart';
import 'root_manager.dart';

/// Fetches KernelSU/SUSFS AnyKernel zips from the WildKernels release
/// repos and matches them against a boot image's KMI.
class AnyKernelRepo {
  AnyKernelRepo({String? manufacturer}) : repo = _repoFor(manufacturer ?? '');

  /// GitHub repo slug under `WildKernels/`.
  final String repo;

  static const _base = 'https://api.github.com/repos/WildKernels';
  static const _userAgent = 'geergit-root-helper';

  /// GKI zips for most devices; OPlus-family devices ship their own kernels.
  static String _repoFor(String manufacturer) {
    final m = manufacturer.toLowerCase();
    if (m.contains('oneplus') || m.contains('oppo') || m.contains('realme')) {
      return 'OnePlus_KernelSU_SUSFS';
    }
    return 'GKI_KernelSU_SUSFS';
  }

  /// Pure KMI-vs-asset-name check, split out for unit testing.
  ///
  /// Asset names carry the full release prefix (`6.1.99-android14-...`),
  /// so the KMI (e.g. `android14-6.1`) is matched by tokens: the android
  /// level plus the `major.minor.` version prefix.
  static bool nameMatchesKmi(String assetNameLower, String kmi) {
    final tokens = kmi
        .split('-')
        .map((t) => t.trim().toLowerCase())
        .where((t) => t.isNotEmpty)
        .toList();
    for (final token in tokens) {
      // Dot-boundary is wrong here: exact tokens are followed by '-'
      // (`6.1.157-android14`), KMI tokens by '.' (`6.1.99-android14`).
      // A digit after the token means a longer version (`6.10` vs `6.1`).
      final needle = RegExp(r'^\d').hasMatch(token) ? '$token(?![0-9])' : token;
      final matched = needle == token
          ? assetNameLower.contains(token)
          : RegExp(needle).hasMatch(assetNameLower);
      if (!matched) return false;
    }
    return true;
  }

  /// Exact patch-level match: every leading release token of
  /// [release] (`6.1.157-android14-11-g…` → `6.1.157.` + `android14`)
  /// must appear in the asset name. Trailing build suffixes are ignored.
  static bool nameMatchesRelease(String assetNameLower, String release) {
    final tokens = release
        .split('-')
        .takeWhile(
          (t) => RegExp(r'^(\d+\.\d+(\.\d+)?|android\d+)$').hasMatch(t),
        )
        .map((t) => t.toLowerCase())
        .toList();
    if (tokens.isEmpty) return false;
    return nameMatchesKmi(assetNameLower, tokens.join('-'));
  }

  /// An AnyKernel3 kernel-swap build — the kernel replacement this app
  /// performs. GKI repo names them `…-AnyKernel3.zip`, the OnePlus repo
  /// `AK3_…zip`; anything else in the same release (metamodules and the
  /// like) is not a boot image kernel.
  static bool isKernelSwapZip(String assetNameLower) =>
      assetNameLower.contains('anykernel') || assetNameLower.startsWith('ak3');

  /// A label for a build whose asset name carries no known manager — the
  /// older WildKernels naming (`5.15.104-android13-2023-06-Bypass-AnyKernel3.zip`,
  /// `WKSU-13974-…-2024-11-Bypass-BBG-AnyKernel3.zip`): the name minus the
  /// kernel/date prefix and the AnyKernel3 suffix.
  static String buildLabel(String assetName) {
    var name = assetName
        .replaceFirst(RegExp(r'\.zip$', caseSensitive: false), '')
        .replaceFirst(RegExp(r'-AnyKernel3$', caseSensitive: false), '');
    final dated = name.replaceFirst(RegExp(r'^.*?\d{4}-\d{2}-?'), '');
    name = dated != name
        ? dated
        : name.replaceFirst(RegExp(r'^[\d.]+-android\d+(-lts)?-'), '');
    return name.isEmpty ? 'Other build' : name;
  }

  /// The builds to offer for one kernel, one entry per build.
  ///
  /// [assets] come newest release first. Only the newest release that
  /// publishes anything for the kernel counts — walking every historical
  /// release piles up hundreds of builds of the same line. Pass 1 wants
  /// the exact patch level, pass 2 the KMI; within a release a build
  /// appears once, and a kernel-swap build beats a non-kernel-swap one.
  /// Patchable entries come first, then by label.
  static List<RemoteZip> variants(
    Iterable<ReleaseAsset> assets, {
    required String release,
    required String kmi,
  }) {
    for (final exactOnly in const [true, false]) {
      for (final releaseAssets in _byRelease(assets)) {
        final found = _variantsIn(
          releaseAssets,
          release: release,
          kmi: kmi,
          exactOnly: exactOnly,
        );
        if (found.isNotEmpty) return found;
      }
    }
    return const [];
  }

  static Iterable<List<ReleaseAsset>> _byRelease(
    Iterable<ReleaseAsset> assets,
  ) {
    final groups = <String, List<ReleaseAsset>>{};
    for (final asset in assets) {
      (groups[asset.tag] ??= []).add(asset);
    }
    return groups.values;
  }

  static List<RemoteZip> _variantsIn(
    List<ReleaseAsset> assets, {
    required String release,
    required String kmi,
    required bool exactOnly,
  }) {
    final byBuild = <String, RemoteZip>{};
    for (final asset in assets) {
      final lower = asset.name.toLowerCase();
      if (!lower.endsWith('.zip')) continue;
      final matches = exactOnly
          ? nameMatchesRelease(lower, release)
          : nameMatchesKmi(lower, kmi);
      if (!matches) continue;
      final label = RootManager.of(lower)?.name ?? buildLabel(asset.name);
      final zip = RemoteZip(
        name: asset.name,
        size: asset.size,
        releaseTag: asset.tag,
        downloadUrl: asset.url,
        manager: label,
        patchable: isKernelSwapZip(lower),
      );
      final previous = byBuild[label];
      if (previous == null || (!previous.patchable && zip.patchable)) {
        byBuild[label] = zip;
      }
    }
    final found = byBuild.values.toList();
    found.sort((a, b) {
      if (a.patchable != b.patchable) return a.patchable ? -1 : 1;
      return a.manager.compareTo(b.manager);
    });
    return found;
  }

  /// Manager APKs and module zips published by the release line.
  ///
  /// These are not kernel-specific (a manager app or a metamodule fits any
  /// kernel), so the newest release carrying any of them wins. Manager APKs
  /// are labelled with the manager they belong to and whether they are the
  /// spoofed build.
  static List<SupportAsset> supportAssets(Iterable<ReleaseAsset> assets) {
    for (final releaseAssets in _byRelease(assets)) {
      final found = <SupportAsset>[];
      for (final asset in releaseAssets) {
        final lower = asset.name.toLowerCase();
        if (lower.endsWith('.apk')) {
          found.add(
            SupportAsset(
              name: asset.name,
              size: asset.size,
              releaseTag: asset.tag,
              downloadUrl: asset.url,
              kind: SupportKind.managerApk,
              manager: RootManager.of(lower)?.name,
              spoofed: lower.contains('spoofed'),
            ),
          );
        } else if (lower.endsWith('.zip') && !isKernelPayload(lower)) {
          found.add(
            SupportAsset(
              name: asset.name,
              size: asset.size,
              releaseTag: asset.tag,
              downloadUrl: asset.url,
              kind: SupportKind.moduleZip,
              manager: RootManager.of(lower)?.name,
            ),
          );
        }
      }
      if (found.isNotEmpty) {
        found.sort((a, b) {
          if (a.kind != b.kind) return a.kind.index - b.kind.index;
          return a.name.compareTo(b.name);
        });
        return found;
      }
    }
    return const [];
  }

  /// Anything in a release that carries a kernel rather than supporting it:
  /// the AnyKernel3 builds, the prebuilt boot images, the image bundles.
  static bool isKernelPayload(String assetNameLower) =>
      isKernelSwapZip(assetNameLower) ||
      assetNameLower.contains('-boot') ||
      assetNameLower.contains('kernelimages');

  /// Supporting downloads relevant to one root manager: that manager's
  /// apps (plain and spoofed), plus every module zip.
  static List<SupportAsset> supportForManager(
    List<SupportAsset> all,
    String? manager,
  ) => all
      .where(
        (a) => switch (a.kind) {
          SupportKind.moduleZip => true,
          SupportKind.managerApk => a.manager == manager,
        },
      )
      .toList();

  /// Kernel builds and supporting downloads for one boot image kernel, in
  /// a single GitHub lookup.
  Future<ReleaseSearch> search(String release) async {
    AppLogger.log('AnyKernelRepo', 'searching $repo for "$release"');
    final res = await http.get(
      Uri.parse('$_base/$repo/releases'),
      headers: const {'User-Agent': _userAgent},
    );
    if (res.statusCode != 200) {
      throw AnyKernelRepoException(
        'GitHub lookup failed: HTTP ${res.statusCode}',
      );
    }
    final releases = jsonDecode(res.body) as List<dynamic>;
    final assets = <ReleaseAsset>[];
    for (final rel in releases) {
      final tag = ((rel as Map)['tag_name'] ?? '').toString();
      for (final raw in (rel['assets'] as List?) ?? const []) {
        final asset = raw as Map;
        assets.add((
          name: (asset['name'] ?? '').toString(),
          size: (asset['size'] as int?) ?? 0,
          tag: tag,
          url: (asset['browser_download_url'] as String?) ?? '',
        ));
      }
    }
    final kernelBuilds = variants(
      assets,
      release: release,
      kmi: KernelRelease.parse(release)?.kmi ?? release,
    );
    final support = supportAssets(assets);
    AppLogger.log(
      'AnyKernelRepo',
      kernelBuilds.isEmpty
          ? 'no match for "$release" in $repo'
          : 'found ${kernelBuilds.length} build(s) for "$release": '
                '${kernelBuilds.map((z) => '${z.manager}${z.patchable ? '' : ' (not patchable)'}').join(', ')}',
    );
    AppLogger.log(
      'AnyKernelRepo',
      support.isEmpty
          ? 'no supporting downloads in $repo'
          : 'supporting downloads (${support.first.releaseTag}): '
                '${support.map((a) => a.name).join(', ')}',
    );
    return (kernelBuilds: kernelBuilds, support: support);
  }
}

/// One release asset, as the GitHub API reports it.
typedef ReleaseAsset = ({String name, int size, String tag, String url});

/// Kernel builds and supporting downloads for one boot image kernel, from
/// a single release lookup.
typedef ReleaseSearch = ({
  List<RemoteZip> kernelBuilds,
  List<SupportAsset> support,
});

/// What a [SupportAsset] is for.
enum SupportKind { managerApk, moduleZip }

/// A downloadable asset that supports the patch: the manager app to install
/// after flashing, or a module zip to flash in that manager.
class SupportAsset {
  const SupportAsset({
    required this.name,
    required this.size,
    required this.releaseTag,
    required this.downloadUrl,
    required this.kind,
    this.manager,
    this.spoofed = false,
  });

  final String name;
  final int size;
  final String releaseTag;
  final String downloadUrl;
  final SupportKind kind;

  /// The manager the asset belongs to, when the name identifies one.
  final String? manager;

  /// Spoofed manager builds (hidden from other apps' package lookups).
  final bool spoofed;
}

/// A downloadable KernelSU/SUSFS build for one root manager.
class RemoteZip {
  const RemoteZip({
    required this.name,
    required this.size,
    required this.releaseTag,
    required this.downloadUrl,
    required this.manager,
    required this.patchable,
  });

  final String name;
  final int size;
  final String releaseTag;
  final String downloadUrl;

  /// Root manager this build roots with, e.g. `KernelSU-Next`.
  final String manager;

  /// True for AnyKernel3 kernel-swap builds, which this app can patch with.
  final bool patchable;
}

class AnyKernelRepoException implements Exception {
  const AnyKernelRepoException(this.message);
  final String message;
  @override
  String toString() => message;
}
