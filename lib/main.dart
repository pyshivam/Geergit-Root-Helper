import 'package:flutter/material.dart';

import 'device_info.dart';

void main() {
  runApp(const RootHelperApp());
}

class RootHelperApp extends StatelessWidget {
  const RootHelperApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF8AADF4); // KernelSU-Next accent
    return MaterialApp(
      title: 'Geergit Root Helper',
      themeMode: ThemeMode.system,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seed),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
        ),
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final Future<DeviceInfo> _info = DeviceInfo.fetch();

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
        _StatusCard(info: info),
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.info});

  final DeviceInfo info;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      color: scheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.smartphone, size: 40, color: scheme.onPrimaryContainer),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    info.model,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    info.sdkInt > 0
                        ? 'Android ${info.androidRelease} (API ${info.sdkInt})'
                        : info.androidRelease,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
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
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
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
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
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
