import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/logging/log_export.dart';

/// Patch tab landing: pick a mode, or read the flashing guide.
class PatchLandingScreen extends StatelessWidget {
  const PatchLandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Patch')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _ModeCard(
            icon: Icons.auto_fix_high,
            color: scheme.primaryContainer,
            title: 'Simple — patch now',
            subtitle:
                'Pick your stock boot.img. The KernelSU-family AnyKernel '
                'builds published for your kernel are listed — you choose '
                'which root to patch for.',
            onTap: () => context.push('/patch/flow?mode=simple'),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.tune,
            color: scheme.secondaryContainer,
            title: 'Advanced — bring your own zip',
            subtitle:
                'Pick the boot.img and the AnyKernel zip yourself. '
                'Kernel versions are compared before patching.',
            onTap: () => context.push('/patch/flow?mode=advanced'),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.menu_book_outlined,
            color: scheme.surfaceContainerHighest,
            title: 'Flashing guide',
            subtitle:
                'Bootloader prep, fastboot steps, and recovery from a '
                'bad flash.',
            onTap: () => context.push('/patch/guide'),
          ),
          const SizedBox(height: 16),
          _ModeCard(
            icon: Icons.description_outlined,
            color: scheme.surfaceContainerHighest,
            title: 'Export logs',
            subtitle:
                'Bundle every session log into a zip you can send for '
                'debugging — what happened stays on record even if the app '
                'crashed.',
            onTap: () => exportLogsWithFeedback(context),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Icon(icon, size: 32),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward),
            ],
          ),
        ),
      ),
    );
  }
}
