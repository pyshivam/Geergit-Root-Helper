import 'dart:io';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/data/device_info.dart';

/// Home tab: patch CTA hero card + device/software info cards.
class HomeTabScreen extends StatefulWidget {
  const HomeTabScreen({super.key});

  @override
  State<HomeTabScreen> createState() => _HomeTabScreenState();
}

class _HomeTabScreenState extends State<HomeTabScreen> {
  late final Future<DeviceInfo> _info = DeviceInfo.fetch()..then(_writeReport);

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
      appBar: AppBar(title: const Text('Geergit Root Helper')),
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
        const _PatchCtaCard(),
        const SizedBox(height: 16),
        _LabeledCard(
          title: 'Device',
          rows: [
            _InfoRow(icon: Icons.smartphone, label: 'Model', value: info.model),
            _InfoRow(
              icon: Icons.precision_manufacturing,
              label: 'Manufacturer',
              value: info.manufacturer,
            ),
            _InfoRow(icon: Icons.memory, label: 'ABI', value: info.abis),
            _InfoRow(
              icon: Icons.fingerprint,
              label: 'Build fingerprint',
              value: info.fingerprint,
            ),
          ],
        ),
        const SizedBox(height: 16),
        _LabeledCard(
          title: 'Software',
          rows: [
            _InfoRow(
              icon: Icons.android,
              label: 'Android version',
              value: info.sdkInt > 0
                  ? 'Android ${info.androidRelease} (API ${info.sdkInt})'
                  : info.androidRelease,
            ),
            _InfoRow(
              icon: Icons.terminal,
              label: 'Kernel version',
              value: info.kernelVersion,
            ),
          ],
        ),
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
                      'Patch a stock boot.img with KernelSU — no root needed',
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
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
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
              Text(value, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
