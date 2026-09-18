import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/data/device_info.dart';
import '../../../core/data/disclaimer_prefs.dart';
import '../../../core/logging/app_logger.dart';

/// Home tab: patch CTA hero card + device/software info cards.
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late final Future<DeviceInfo> _info = DeviceInfo.fetch()..then(_writeReport);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowDisclaimer());
  }

  /// One-time flashing-risk disclaimer, shown on first launch. The app
  /// flashes boot images — the user must understand the brick risk
  /// before reaching anything else.
  Future<void> _maybeShowDisclaimer() async {
    final filesRoot =
        AppLogger.currentFile?.parent.parent ?? Directory.systemTemp;
    if (await DisclaimerPrefs.isAcknowledged(filesRoot)) return;
    if (!mounted) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('Flashing can brick your device'),
        content: const Text(
          'This app patches and helps flash boot images. A wrong image '
          'can permanently brick your device, wipe your data, or void '
          'your warranty.\n\n'
          'Only flash images built for your exact device model and '
          'build. GRoot Helper is not responsible for any damage.',
        ),
        actions: [
          TextButton(
            onPressed: () => SystemNavigator.pop(),
            child: const Text('Exit'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
    await DisclaimerPrefs.acknowledge(filesRoot);
  }

  // Debug aid: device verification pulls this file via
  // `adb exec-out run-as <pkg> cat files/report.txt` instead of screenshots.
  Future<void> _writeReport(DeviceInfo info) async {
    final path = await DeviceInfo.reportPath();
    if (path == null) return;
    try {
      await File(path).writeAsString(info.toReport());
    } on IOException {
      // verification aid only — never break the UI over it
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DeviceInfo>(
        future: _info,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return _HomeBody(info: snapshot.data!);
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({required this.info});

  final DeviceInfo info;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // KernelSU-manager style: large display title, no app bar,
        // generous breathing room above (matches KSU home).
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 115, 8, 16),
          child: Text(
            'GRoot Helper',
            style: Theme.of(context).textTheme.headlineLarge,
          ),
        ),
        const _PatchCtaCard(),
        const SizedBox(height: 16),
        // Priority order within one card: kernel version first (it
        // decides patch compatibility), then model, manufacturer,
        // build fingerprint; ABI last as least important.
        _LabeledCard(
          title: 'Device',
          rows: [
            _InfoRow(
              icon: Icons.terminal,
              label: 'Kernel version',
              value: info.kernelVersion,
              highlight: true,
            ),
            _InfoRow(
              icon: Icons.android,
              label: 'Android version',
              value: info.sdkInt > 0
                  ? 'Android ${info.androidRelease} (API ${info.sdkInt})'
                  : info.androidRelease,
            ),
            const Divider(height: 32),
            _InfoRow(icon: Icons.smartphone, label: 'Model', value: info.model),
            _InfoRow(
              icon: Icons.precision_manufacturing,
              label: 'Manufacturer',
              value: info.manufacturer,
            ),
            _InfoRow(
              icon: Icons.fingerprint,
              label: 'Build fingerprint',
              value: info.fingerprint,
            ),
            _InfoRow(icon: Icons.memory, label: 'ABI', value: info.abis),
          ],
        ),
        const SizedBox(height: 16),
        const _SupportCard(),
      ],
    );
  }
}

/// Hero card: entry point to the boot.img / AnyKernel patch guide.
class _PatchCtaCard extends StatelessWidget {
  const _PatchCtaCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push('/patch/flow?mode=simple'),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(
                Icons.system_update_alt,
                size: 40,
                color: scheme.onPrimaryContainer,
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Patch boot.img with AnyKernel zip',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Patch a stock boot.img with a KernelSU-family '
                      'kernel — no root needed',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: scheme.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}

/// Support card: Patreon link, KernelSU-manager style.
class _SupportCard extends StatelessWidget {
  const _SupportCard();

  static final Uri _patreon = Uri.parse(
    'https://www.patreon.com/cw/pyshivam/membership',
  );

  Future<void> _open() async {
    // ExternalApplication so the Patreon app/browser handles it directly.
    await launchUrl(_patreon, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _open,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.favorite, size: 40, color: scheme.primary),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Support development',
                      style: Theme.of(context).textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Support GRoot Helper on Patreon',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledCard extends StatelessWidget {
  const _LabeledCard({required this.title, required this.rows});

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0) const SizedBox(height: 16),
              rows[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.highlight = false,
  });

  final IconData icon;
  final String label;
  final String value;

  /// Emphasized row (e.g. kernel version): value in the theme's
  /// primary color, one weight up.
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final valueStyle = Theme.of(context).textTheme.bodySmall;
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: highlight
                    ? valueStyle?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                      )
                    : valueStyle,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
