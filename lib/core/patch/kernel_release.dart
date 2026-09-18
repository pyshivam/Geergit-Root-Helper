/// Kernel release and KMI (Kernel Module Interface) parsing.
///
/// Same idea as ksud's `parse_kmi` in
/// `KernelSU-Next/userspace/ksud/src/boot_patch.rs`: an uncompressed
/// kernel image embeds a `Linux version <release> …` string; the KMI is
/// `android<NN>-<major>.<minor>` from that release.
class KernelRelease {
  const KernelRelease({required this.release, required this.kmi});

  /// Full release token, e.g. `6.1.57-android14-8-gb6a3ee44fd2c-ab124`.
  final String release;

  /// KMI, e.g. `android14-6.1`.
  final String kmi;

  /// Release up to the Android level, e.g. `6.1.157-android14` — the
  /// platform version a matching kernel is built for (no build suffix).
  String get baseRelease {
    final tokens = release
        .split('-')
        .takeWhile(
          (t) => RegExp(r'^(\d+\.\d+(\.\d+)?|android\d+)$').hasMatch(t),
        )
        .toList();
    return tokens.isEmpty ? release : tokens.join('-');
  }

  /// Parses a release token (as found in uname or after "Linux version ").
  static KernelRelease? parse(String release) {
    final m = RegExp(r'(\d+\.\d+)(?:\S+)?(android\d+)').firstMatch(release);
    if (m == null) return null;
    return KernelRelease(release: release, kmi: '${m[2]}-${m[1]}');
  }

  /// Finds the embedded version string in raw kernel image bytes.
  ///
  /// An Image carries the literal twice: the printk format string
  /// `Linux version %s (%s)` sits ahead of the banner, so the first marker
  /// is not necessarily the release — take the first token that parses.
  static KernelRelease? parseFromKernelBytes(List<int> bytes) {
    const marker = 'Linux version ';
    var from = 0;
    while (true) {
      final idx = _indexOfSublist(bytes, marker.codeUnits, from);
      if (idx < 0) return null;
      final start = idx + marker.length;
      final end = (start + 160).clamp(0, bytes.length);
      final slice = bytes.sublist(start, end);
      final nul = slice.indexOf(0);
      final line = String.fromCharCodes(
        nul >= 0 ? slice.sublist(0, nul) : slice,
      );
      final token = line.split(' ').firstOrNull;
      final parsed = (token == null || token.isEmpty) ? null : parse(token);
      if (parsed != null) return parsed;
      from = idx + marker.length;
    }
  }

  static int _indexOfSublist(
    List<int> haystack,
    List<int> needle, [
    int from = 0,
  ]) {
    outer:
    for (var i = from; i + needle.length <= haystack.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }
}
