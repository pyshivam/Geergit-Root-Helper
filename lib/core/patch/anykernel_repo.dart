import 'dart:convert';

import 'package:http/http.dart' as http;

import 'kernel_release.dart';

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

  /// Finds a release asset for [release] (full kernel release string from
  /// the boot image, e.g. `6.1.157-android14-11-gb6a3e…`).
  ///
  /// Pass 1 prefers an exact patch-level match, pass 2 falls back to the
  /// KMI (`android14-6.1`). Within each pass, AnyKernel builds win.
  /// Returns null when nothing matches.
  Future<RemoteZip?> findMatchingZip(String release) async {
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
    final kmi = KernelRelease.parse(release)?.kmi ?? release;
    RemoteZip? kmiFallback;
    RemoteZip? anyKernelKmiFallback;
    for (final rel in releases) {
      final tag = ((rel as Map)['tag_name'] ?? '').toString();
      final assets = (rel['assets'] as List?) ?? const [];
      for (final raw in assets) {
        final asset = raw as Map;
        final name = (asset['name'] ?? '').toString();
        final lower = name.toLowerCase();
        if (!lower.endsWith('.zip')) continue;
        final zip = RemoteZip(
          name: name,
          size: (asset['size'] as int?) ?? 0,
          releaseTag: tag,
          downloadUrl: (asset['browser_download_url'] as String?) ?? '',
        );
        if (nameMatchesRelease(lower, release)) {
          // Exact match: first AnyKernel hit in newest-first order wins.
          if (lower.contains('anykernel')) return zip;
          kmiFallback ??= zip;
        } else if (nameMatchesKmi(lower, kmi)) {
          if (lower.contains('anykernel')) {
            anyKernelKmiFallback ??= zip;
          } else {
            kmiFallback ??= zip;
          }
        }
      }
    }
    return kmiFallback ?? anyKernelKmiFallback;
  }
}

class RemoteZip {
  const RemoteZip({
    required this.name,
    required this.size,
    required this.releaseTag,
    required this.downloadUrl,
  });

  final String name;
  final int size;
  final String releaseTag;
  final String downloadUrl;
}

class AnyKernelRepoException implements Exception {
  const AnyKernelRepoException(this.message);
  final String message;
  @override
  String toString() => message;
}
