import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// Settings tab: app header (identity + support), theme mode, credits.
class SettingsTabScreen extends StatelessWidget {
  const SettingsTabScreen({super.key, required this.themeMode});

  final ValueNotifier<ThemeMode> themeMode;

  static final Uri _patreon = Uri.parse(
    'https://www.patreon.com/cw/pyshivam/membership',
  );

  Future<void> _openPatreon() async {
    await launchUrl(_patreon, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // App header: identity + support, same content the About
          // page used to hold — now inline at the top of Settings.
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/launcher_icon/grh_logo.png',
              width: 72,
              height: 72,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'GRoot Helper',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          FutureBuilder<PackageInfo>(
            future: PackageInfo.fromPlatform(),
            builder: (context, snapshot) {
              final info = snapshot.data;
              return Text(
                info == null
                    ? ''
                    : 'Version ${info.version} (${info.buildNumber})',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              );
            },
          ),
          const SizedBox(height: 8),
          Text(
            'Patch a stock boot.img with KernelSU-family kernels — no root '
            'needed. Flash at your own risk.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ValueListenableBuilder<ThemeMode>(
            valueListenable: themeMode,
            builder: (context, mode, _) => SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode),
                ),
              ],
              selected: {mode},
              onSelectionChanged: (selection) =>
                  themeMode.value = selection.first,
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.favorite_outline),
              title: const Text('Credits'),
              subtitle: const Text('The projects GRoot Helper builds on'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => context.push('/settings/credits'),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            clipBehavior: Clip.antiAlias,
            child: ListTile(
              leading: const Icon(Icons.favorite),
              title: const Text('Support on Patreon'),
              subtitle: const Text(
                'Help keep GRoot Helper free and maintained',
              ),
              trailing: const Icon(Icons.open_in_new),
              onTap: _openPatreon,
            ),
          ),
        ],
      ),
    );
  }
}
