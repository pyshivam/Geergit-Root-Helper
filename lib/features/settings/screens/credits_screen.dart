import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Credits page: the projects and people GRoot Helper builds on.
/// Each entry opens its upstream repository.
class CreditsScreen extends StatelessWidget {
  const CreditsScreen({super.key});

  static const _entries = [
    // The Wild Kernels "Special Thanks" list (GKI_KernelSU_SUSFS README),
    // plus Magisk and Flutter. URLs verbatim from that README.
    (
      name: 'GKI KernelSU SUSFS (Wild Kernels)',
      author: 'WildKernels',
      role: 'The kernel zips this app patches and flashes',
      url: 'https://github.com/WildKernels/GKI_KernelSU_SUSFS',
    ),
    (
      name: 'KernelSU',
      author: 'tiann',
      role: 'Root solution and app design inspiration',
      url: 'https://github.com/tiann/KernelSU',
    ),
    (
      name: 'KernelSU-Next',
      author: 'rifsxd',
      role: 'Root implementation',
      url: 'https://github.com/KernelSU-Next/KernelSU-Next',
    ),
    (
      name: 'KernelSU-Next SUSFS Fork',
      author: 'pershoot',
      role: 'Root implementation with SUSFS',
      url: 'https://github.com/pershoot/KernelSU-Next',
    ),
    (
      name: 'ReSukiSU',
      author: 'ReSukiSU',
      role: 'Root implementation',
      url: 'https://github.com/ReSukiSU/ReSukiSU',
    ),
    (
      name: 'Magic-KSU',
      author: '5ec1cff',
      role: 'Root implementation',
      url: 'https://github.com/5ec1cff/KernelSU',
    ),
    (
      name: 'SUSFS',
      author: 'simonpunk',
      role: 'Root hiding',
      url: 'https://gitlab.com/simonpunk/susfs4ksu',
    ),
    (
      name: 'SUSFS Module',
      author: 'sidex15',
      role: 'SUSFS companion module',
      url: 'https://github.com/sidex15',
    ),
    (
      name: 'NoMount',
      author: 'maxsteeel',
      role: 'Mount metamodules',
      url: 'https://github.com/maxsteeel/nomount',
    ),
    (
      name: 'DroidSpaces-OSS',
      author: 'ravindu644',
      role: 'Container runtime',
      url: 'https://github.com/ravindu644/Droidspaces-OSS',
    ),
    (
      name: 'Baseband-guard (BBG)',
      author: 'vc-teahouse',
      role: 'Baseband partition protection',
      url: 'https://github.com/vc-teahouse/Baseband-guard',
    ),
    (
      name: 'Kernel Patches',
      author: 'WildKernels/kernel_patches',
      role: 'Kernel patches',
      url: 'https://github.com/WildKernels/kernel_patches',
    ),
    (
      name: 'AnyKernel3',
      author: 'osm0sis',
      role: 'The zip format the patcher flashes',
      url: 'https://github.com/osm0sis/AnyKernel3',
    ),
    (
      name: 'Sultan Kernels (Pixel)',
      author: 'kerneltoast',
      role: 'Pixel kernel sources',
      url: 'https://github.com/kerneltoast',
    ),
    (
      name: 'Device Boot Fix',
      author: 'Anything-at-25-00',
      role: 'Boot fix commit',
      url: 'https://github.com/Anything-at-25-00/android_kernel_common_android12-5.10/commit/2476d262b597fe8af82cfb7aaf96676f51c6b4ed',
    ),
    (
      name: 'Magisk',
      author: 'topjohnwu',
      role: 'magiskboot upstream',
      url: 'https://github.com/topjohnwu/Magisk',
    ),
    (
      name: 'Flutter',
      author: 'flutter',
      role: 'The framework this app is built with',
      url: 'https://github.com/flutter/flutter',
    ),
  ];

  Future<void> _open(String url) async {
    await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Credits')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'GRoot Helper builds on the Wild Kernels project and its special thanks list. Tap any entry to visit its repository.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          for (final e in _entries)
            Card(
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.code),
                title: Text(e.name),
                subtitle: Text('${e.author} — ${e.role}'),
                trailing: const Icon(Icons.open_in_new),
                onTap: () => _open(e.url),
              ),
            ),
        ],
      ),
    );
  }
}
