import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_tab_screen.dart';
import '../../features/patch/screens/patch_guide_screen.dart';
import '../../features/settings/screens/settings_tab_screen.dart';
import '../../screens/home/home_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Declarative router, same shape as geergit's `core/router/app_router.dart`:
/// a [StatefulShellRoute.indexedStack] for the bottom-nav tabs plus pushed
/// detail routes outside the shell.
GoRouter buildRouter({required ValueNotifier<ThemeMode> themeMode}) {
  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/home',
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return HomeScreen(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                builder: (context, state) => const HomeTabScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/patch',
                builder: (context, state) => const PatchGuideScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) =>
                    SettingsTabScreen(themeMode: themeMode),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/patch/guide',
        builder: (context, state) => const PatchGuideScreen(),
      ),
    ],
  );
}
