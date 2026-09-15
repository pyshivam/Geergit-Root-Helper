import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';

import '../data/device_info.dart';

/// File-based session logging — the same pattern root/Zygisk modules use
/// when logcat is unavailable: every app launch gets its own plain-text
/// log under the app files dir, and a remote user exports them as a zip.
///
/// One file per launch (not per action): a failed patch try is only
/// diagnosable with the session's device context around it. Each try
/// inside the session is delimited by a `===== PATCH TRY =====` banner.
class AppLogger {
  AppLogger._();

  static const _maxSessions = 10;

  static File? _file;
  static Directory? _logsDir;

  /// The active session file, or null before [init] or off-filesystem.
  static File? get currentFile => _file;
  static Directory? get logsDir => _logsDir;

  static Future<void> init() async {
    try {
      final base = await _filesRoot();
      final logs = Directory('${base.path}/logs')..createSync(recursive: true);
      _logsDir = logs;
      _prune(logs);
      final stamp = _stamp(DateTime.now());
      _file = File('${logs.path}/session-$stamp.log');
      _file!.writeAsStringSync('===== SESSION $stamp =====\n');
      log('AppLogger', 'log file: ${_file!.path}');
    } on Object catch (e) {
      debugPrint('AppLogger init failed: $e');
    }
  }

  /// Appends a timestamped line to the session file and debugPrints it.
  static void log(String tag, String message) {
    final line = '${_ts()} $tag: $message';
    debugPrint(line);
    final file = _file;
    if (file == null) return;
    try {
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } on IOException {
      // logging must never crash the caller
    }
  }

  /// Zips every session log into `logs-export.zip` next to the logs dir.
  /// Returns the bundle, or null when there is nothing to export.
  static Future<File?> exportBundle() async {
    final logs = _logsDir;
    if (logs == null) return null;
    final files = logs
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.log'))
        .toList();
    if (files.isEmpty) return null;
    final archive = Archive();
    for (final f in files) {
      archive.addFile(
        ArchiveFile(
          f.uri.pathSegments.last,
          f.lengthSync(),
          f.readAsBytesSync(),
        ),
      );
    }
    final out = File('${logs.parent.path}/logs-export.zip');
    out.writeAsBytesSync(ZipEncoder().encode(archive), flush: true);
    return out;
  }

  static Future<Directory> _filesRoot() async {
    if (Platform.isAndroid) {
      final report = await DeviceInfo.reportPath();
      if (report != null) {
        return Directory(report.substring(0, report.lastIndexOf('/')));
      }
    }
    return Directory.systemTemp;
  }

  static void _prune(Directory logs) {
    final sessions =
        logs
            .listSync()
            .whereType<File>()
            .where((f) => f.path.endsWith('.log'))
            .toList()
          ..sort((a, b) => a.path.compareTo(b.path));
    while (sessions.length > _maxSessions) {
      sessions.removeAt(0).deleteSync();
    }
  }

  static String _stamp(DateTime t) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${t.year}${two(t.month)}${two(t.day)}-${two(t.hour)}${two(t.minute)}${two(t.second)}';
  }

  static String _ts() {
    final t = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    String three(int v) => v.toString().padLeft(3, '0');
    return '${t.year}-${two(t.month)}-${two(t.day)} ${two(t.hour)}:${two(t.minute)}:${two(t.second)}.${three(t.millisecond)}';
  }
}
