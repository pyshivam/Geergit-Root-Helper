import 'package:flutter/material.dart';

import '../data/file_export.dart';
import 'app_logger.dart';

/// Bundles all session logs and hands them to the SAF save sheet,
/// with a SnackBar describing the outcome.
Future<void> exportLogsWithFeedback(BuildContext context) async {
  final messenger = ScaffoldMessenger.of(context);
  final bundle = await AppLogger.exportBundle();
  if (bundle == null) {
    messenger.showSnackBar(
      const SnackBar(content: Text('No logs to export yet.')),
    );
    return;
  }
  final uri = await FileExport.export(
    sourcePath: bundle.path,
    displayName: 'grh-logs-${DateTime.now().millisecondsSinceEpoch}.zip',
  );
  if (!context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        uri == null
            ? 'Export cancelled.'
            : 'Logs exported — attach the zip to your bug report.',
      ),
    ),
  );
}
