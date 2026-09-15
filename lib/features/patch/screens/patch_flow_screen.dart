import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;

import '../../../core/data/device_info.dart';
import '../../../core/data/file_export.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/logging/log_export.dart';
import '../../../core/patch/anykernel_repo.dart';
import '../../../core/patch/anykernel_zip.dart';
import '../../../core/patch/boot_patcher.dart';
import '../../../core/patch/kernel_release.dart';
import '../../../core/patch/magiskboot.dart';

/// The actual patcher: boot.img → version gates → AnyKernel zip →
/// repack → exportable `new-boot.img`. No root anywhere.
///
/// Two modes (`?mode=simple|advanced`):
/// - simple: zip is fetched from the WildKernels release repo by KMI
/// - advanced: user supplies the zip; both version gates are enforced
class PatchFlowScreen extends StatefulWidget {
  const PatchFlowScreen({super.key, required this.mode});

  final String mode;

  @override
  State<PatchFlowScreen> createState() => _PatchFlowScreenState();
}

enum _Stage { pickBoot, bootReady, zipStep, done }

class _PatchFlowScreenState extends State<PatchFlowScreen> {
  final _deviceInfo = DeviceInfo.fetch();

  _Stage _stage = _Stage.pickBoot;
  String? _error;
  String _busyLabel = '';

  late final bool _simple = widget.mode != 'advanced';

  // Boot image state
  BootPatcher? _patcher;
  KernelRelease? _bootKernel;
  KernelRelease? _deviceKernel;
  bool _bootMatchesDevice = false;
  bool _bootGateAcked = false;

  // Zip state
  AnyKernelZip? _zip;
  RemoteZip? _remoteZip;
  List<int>? _zipBytes;
  KernelRelease? _zipKernel;
  bool _zipMatchesBoot = false;
  bool _zipGateAcked = false;

  File? _output;
  bool _exporting = false;

  bool get _bootGateOk => _bootMatchesDevice || _bootGateAcked;
  bool get _zipGateOk => _zip == null || _zipMatchesBoot || _zipGateAcked;

  Future<String> get _filesRoot async {
    if (Platform.isAndroid) {
      final dir = await DeviceInfo.reportPath(); // <filesDir>/report.txt
      return dir == null
          ? Directory.systemTemp.path
          : dir.substring(0, dir.lastIndexOf('/'));
    }
    return Directory.systemTemp.path;
  }

  Future<void> _run(String label, Future<void> Function() body) async {
    setState(() {
      _busyLabel = label;
      _error = null;
    });
    AppLogger.log('PatchFlow', label);
    try {
      await body();
    } on Exception catch (e) {
      AppLogger.log('PatchFlow', 'ERROR: $e');
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busyLabel = '');
    }
  }

  Future<void> _pickBootImage() async {
    // readAsByteStream: file bytes never cross the platform channel — a
    // 64MB boot.img OOMs otherwise (file_selector was tried first and
    // ships the whole file through its Pigeon codec; confirmed on device).
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['img'],
    );
    if (files.isEmpty) return;
    final file = files.single;
    final stream = file.readAsByteStream();
    AppLogger.log(
      'PatchFlow',
      '===== PATCH TRY mode=${widget.mode} =====\n'
          'picked boot.img: ${file.name}',
    );
    await _run('Unpacking boot image…', () async {
      final root = await _filesRoot;
      final workspace = Directory(
        '$root/patchwork/${DateTime.now().millisecondsSinceEpoch}',
      );
      final info = await _deviceInfo;
      final magiskboot = Magiskboot(abis: info.abis);
      final patcher = BootPatcher(magiskboot: magiskboot, workDir: workspace);
      workspace.createSync(recursive: true);
      final boot = File('${workspace.path}/picked-boot.img');
      await boot.openWrite().addStream(stream);
      final kernel = await patcher.unpackBootImage(boot);
      final deviceKernel = KernelRelease.parse(info.kernelVersion);
      if (!mounted) return;
      setState(() {
        _patcher = patcher;
        _bootKernel = kernel;
        _deviceKernel = deviceKernel;
        _bootMatchesDevice =
            kernel != null &&
            deviceKernel != null &&
            kernel.kmi == deviceKernel.kmi;
        _bootGateAcked = false;
        _stage = _Stage.bootReady;
      });
      if (_bootGateOk) _continueFromBootGate();
    });
  }

  void _continueFromBootGate() {
    AppLogger.log(
      'PatchFlow',
      'boot gate: match=$_bootMatchesDevice acked=$_bootGateAcked',
    );
    setState(() {
      _bootGateAcked = true;
      _stage = _Stage.zipStep;
    });
    if (_simple) _startSimpleZipSearch();
  }

  Future<void> _startSimpleZipSearch() async {
    final release = _bootKernel?.release;
    if (release == null) {
      setState(
        () => _error = 'Could not read the kernel version from this boot image — use Advanced mode and pick the zip manually.',
      );
      return;
    }
    await _run('Searching WildKernels releases for $release…', () async {
      final info = await _deviceInfo;
      final zip = await AnyKernelRepo(manufacturer: info.manufacturer)
          .findMatchingZip(release);
      if (!mounted) return;
      if (zip == null) {
        setState(
          () => _error =
              'No zip matching $release found in the release repo — use Advanced mode with a zip you trust.',
        );
        return;
      }
      setState(() => _remoteZip = zip);
    });
  }

  Future<void> _downloadRemoteZip() async {
    final zip = _remoteZip;
    if (zip == null) return;
    await _run('Downloading ${zip.name}…', () async {
      final res = await http.get(
        Uri.parse(zip.downloadUrl),
        headers: const {'User-Agent': 'geergit-root-helper'},
      );
      if (res.statusCode != 200) {
        throw AnyKernelRepoException('Download failed: HTTP ${res.statusCode}');
      }
      AppLogger.log(
        'PatchFlow',
        'downloaded ${zip.name}: ${res.bodyBytes.length} bytes',
      );
      _loadZipBytes(res.bodyBytes);
    });
  }

  Future<void> _pickZip() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (files.isEmpty) return;
    final file = files.single;
    await _run('Reading ${file.name}…', () async {
      final chunks = await file.readAsByteStream().toList();
      _loadZipBytes(chunks.expand((c) => c).toList());
    });
  }

  void _loadZipBytes(List<int> bytes) {
    final zip = AnyKernelZip.read(bytes);
    final zipKernel = zip.kernelRelease;
    final bootKmi = _bootKernel?.kmi;
    AppLogger.log(
      'PatchFlow',
      'zip kernel: ${zipKernel?.release ?? 'unparseable'} '
          '(entry ${zip.kernelEntryName}, ${bytes.length} bytes)',
    );
    setState(() {
      _zip = zip;
      _zipBytes = bytes;
      _zipKernel = zipKernel;
      _zipMatchesBoot =
          zipKernel != null && bootKmi != null && zipKernel.kmi == bootKmi;
      _zipGateAcked = false;
      _stage = _Stage.zipStep;
    });
  }

  Future<void> _patch() async {
    final patcher = _patcher;
    final zip = _zip;
    if (patcher == null || zip == null) return;
    await _run('Patching boot image…', () async {
      final output = await patcher.patch(zip.kernelBytes);
      if (!mounted) return;
      setState(() {
        _output = output;
        _stage = _Stage.done;
      });
      _writeReport(output);
    });
  }

  // Debug aid per developer-guide: exact values via
  // `adb exec-out run-as <pkg> cat files/patch-report.txt`.
  Future<void> _writeReport(File output) async {
    final path = await DeviceInfo.reportPath();
    if (path == null) return;
    final report =
        '''
Geergit Root Helper patch report
mode: ${_simple ? 'simple' : 'advanced'}
deviceKernel: ${_deviceKernel?.release ?? 'unknown'} (${_deviceKernel?.kmi ?? 'no KMI'})
bootKernel: ${_bootKernel?.release ?? 'unknown'} (${_bootKernel?.kmi ?? 'no KMI'})
bootMatchesDevice: $_bootMatchesDevice
zipKernel: ${_zipKernel?.release ?? 'unknown'} (${_zipKernel?.kmi ?? 'no KMI'})
zipMatchesBoot: ${_zipMatchesBoot
            ? 'true'
            : _zip == null
            ? 'n/a (remote zip, not verified before download)'
            : 'false'}
zip: ${_remoteZip?.name ?? _zip?.kernelEntryName ?? 'manual'}
output: ${output.path} (${output.lengthSync()} bytes)
''';
    try {
      await File(path.replaceFirst('report.txt', 'patch-report.txt'))
          .writeAsString(report);
    } on IOException {
      // verification aid only
    }
  }

  Future<void> _exportOutput() async {
    final output = _output;
    if (output == null) return;
    setState(() => _exporting = true);
    final uri = await FileExport.export(sourcePath: output.path);
    AppLogger.log(
      'PatchFlow',
      'exported ${output.path} -> ${uri ?? 'cancelled'}',
    );
    if (mounted) setState(() => _exporting = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _simple ? 'Patch boot image' : 'Patch boot image (advanced)',
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_busyLabel.isNotEmpty) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Text(_busyLabel),
            const SizedBox(height: 16),
          ],
          if (_error != null) ...[
            _ErrorCard(
              message: _error!,
              onDismiss: () => setState(() => _error = null),
            ),
            const SizedBox(height: 16),
          ],
          switch (_stage) {
            _Stage.pickBoot => _buildPickBoot(context),
            _Stage.bootReady => _buildBootReady(context),
            _Stage.zipStep => _buildZipStep(context),
            _Stage.done => _buildDone(context),
          },
        ],
      ),
    );
  }

  Widget _buildPickBoot(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Boot image first',
                  style: Theme.of(context).textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pick the stock boot.img for this device (extracted from '
                  'the full firmware, or dumped via fastboot). Its kernel '
                  'version is checked against the running kernel before '
                  'anything else. No root is needed.',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busyLabel.isEmpty ? _pickBootImage : null,
          icon: const Icon(Icons.upload_file),
          label: const Text('Choose boot.img'),
        ),
      ],
    );
  }

  Widget _buildBootReady(BuildContext context) {
    final mismatch = !_bootMatchesDevice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KernelCompareCard(
          title: 'Boot image vs device',
          leftLabel: 'Boot image kernel',
          left: _bootKernel,
          rightLabel: 'Device kernel (running)',
          right: _deviceKernel,
          match: _bootMatchesDevice,
        ),
        if (mismatch) ...[
          const SizedBox(height: 16),
          const _WarningCard(
            text:
                'Kernel versions do not match. Patching with a mismatched '
                'kernel usually means the boot.img is not from this device '
                'or firmware — flashing it can bootloop the device.',
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busyLabel.isEmpty ? _continueFromBootGate : null,
            child: const Text('I understand, continue anyway'),
          ),
        ] else ...[
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _busyLabel.isEmpty ? _continueFromBootGate : null,
            child: const Text('Continue'),
          ),
        ],
        const SizedBox(height: 8),
        TextButton(
          onPressed: _busyLabel.isEmpty
              ? () => setState(() {
                  _stage = _Stage.pickBoot;
                  _bootKernel = null;
                  _bootGateAcked = false;
                })
              : null,
          child: const Text('Choose a different boot.img'),
        ),
      ],
    );
  }

  Widget _buildZipStep(BuildContext context) {
    final base = _bootKernel?.baseRelease ?? 'unknown version';
    final kmi = _bootKernel?.kmi ?? 'unknown KMI';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_simple) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AnyKernel zip for $base (KMI $kmi)',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  if (_remoteZip == null && _zipBytes == null)
                    const Text('Searching the WildKernels release repo…')
                  else if (_remoteZip != null && _zipBytes == null) ...[
                    _InfoLine(label: 'Zip', value: _remoteZip!.name),
                    _InfoLine(label: 'Release', value: _remoteZip!.releaseTag),
                    _InfoLine(
                      label: 'Size',
                      value:
                          '${(_remoteZip!.size / 1048576).toStringAsFixed(1)} MB',
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_remoteZip != null && _zipBytes == null)
            FilledButton.icon(
              onPressed: _busyLabel.isEmpty ? _downloadRemoteZip : null,
              icon: const Icon(Icons.download),
              label: const Text('Download and patch'),
            ),
          if (_zipBytes != null) _buildZipVerified(context),
          TextButton(
            onPressed: () =>
                context.pushReplacement('/patch/flow?mode=advanced'),
            child: const Text(
              'Switch to advanced mode (pick the zip yourself)',
            ),
          ),
        ] else ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AnyKernel zip',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _zip == null
                        ? 'Pick the AnyKernel zip built for $base '
                              '(KMI $kmi) — match the patch level too, '
                              'not just the KMI. Its kernel is compared '
                              'against the boot image before patching.'
                        : 'Kernel entry: ${_zip!.kernelEntryName}',
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (_zip == null)
            FilledButton.icon(
              onPressed: _busyLabel.isEmpty ? _pickZip : null,
              icon: const Icon(Icons.upload_file),
              label: const Text('Choose AnyKernel zip'),
            ),
          if (_zip != null) _buildZipVerified(context),
        ],
      ],
    );
  }

  Widget _buildZipVerified(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _KernelCompareCard(
          title: 'Zip kernel vs boot image',
          leftLabel: 'Zip kernel',
          left: _zipKernel,
          rightLabel: 'Boot image kernel',
          right: _bootKernel,
          match: _zipMatchesBoot,
        ),
        if (!_zipMatchesBoot) ...[
          const SizedBox(height: 16),
          _WarningCard(
            text: _zipKernel == null
                ? 'Could not read a version from the zip kernel (it may be '
                      'compressed). Patching continues only if you accept the risk.'
                : 'The zip kernel does not match the boot image KMI. Flashing '
                      'a mismatched kernel usually bootloops the device.',
          ),
          const SizedBox(height: 16),
        ],
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _busyLabel.isEmpty && _zipGateOk ? _patch : null,
          icon: const Icon(Icons.build),
          label: Text(_zipMatchesBoot ? 'Patch boot image' : 'Patch anyway'),
        ),
        if (!_zipMatchesBoot && !_zipGateAcked)
          TextButton(
            onPressed: _busyLabel.isEmpty
                ? () => setState(() => _zipGateAcked = true)
                : null,
            child: const Text('I understand, enable patch anyway'),
          ),
        TextButton(
          onPressed: _busyLabel.isEmpty
              ? () => setState(() {
                  _zip = null;
                  _zipBytes = null;
                  _zipKernel = null;
                  _zipGateAcked = false;
                  _remoteZip = null;
                })
              : null,
          child: Text(_simple ? 'Search again' : 'Choose a different zip'),
        ),
      ],
    );
  }

  Widget _buildDone(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: const Padding(
            padding: EdgeInsets.all(24),
            child: Row(
              children: [
                Icon(Icons.check_circle),
                SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Patched boot image is ready. Save it somewhere '
                    'you can reach from a PC.',
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: _exporting ? null : _exportOutput,
          icon: _exporting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.save_alt),
          label: const Text('Save patched boot.img…'),
        ),
        const SizedBox(height: 16),
        const _FlashInstructionsCard(),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: _exporting ? null : () => exportLogsWithFeedback(context),
          icon: const Icon(Icons.description_outlined),
          label: const Text('Export logs'),
        ),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to home'),
        ),
      ],
    );
  }
}

class _KernelCompareCard extends StatelessWidget {
  const _KernelCompareCard({
    required this.title,
    required this.leftLabel,
    required this.left,
    required this.rightLabel,
    required this.right,
    required this.match,
  });

  final String title;
  final String leftLabel;
  final KernelRelease? left;
  final String rightLabel;
  final KernelRelease? right;
  final bool match;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                Icon(
                  match ? Icons.check_circle : Icons.error,
                  color: match ? scheme.primary : scheme.error,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _InfoLine(label: leftLabel, value: _describe(left)),
            const SizedBox(height: 6),
            _InfoLine(label: rightLabel, value: _describe(right)),
          ],
        ),
      ),
    );
  }

  static String _describe(KernelRelease? k) =>
      k == null ? 'unknown (unparseable)' : '${k.release}  ·  KMI ${k.kmi}';
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 150,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ),
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.bodySmall),
        ),
      ],
    );
  }
}

class _WarningCard extends StatelessWidget {
  const _WarningCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.warning_amber,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, required this.onDismiss});

  final String message;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
            IconButton(icon: const Icon(Icons.close), onPressed: onDismiss),
          ],
        ),
      ),
    );
  }
}

class _FlashInstructionsCard extends StatelessWidget {
  const _FlashInstructionsCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Flash from fastboot',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              '1. Copy the saved boot.img to a PC with adb/fastboot.\n'
              '2. Reboot to the bootloader: `adb reboot bootloader`.\n'
              '3. Flash: `fastboot flash boot boot.img`\n'
              '   (use `init_boot` instead of `boot` on devices that ship one — Android 13+).\n'
              '4. Reboot. If it bootloops, flash your stock boot.img backup.',
            ),
          ],
        ),
      ),
    );
  }
}
