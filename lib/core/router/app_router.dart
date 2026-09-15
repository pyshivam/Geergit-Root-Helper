import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/home/screens/home_tab_screen.dart';
import '../../features/patch/screens/patch_flow_screen.dart';
import '../../features/patch/screens/patch_guide_screen.dart';
import '../../features/patch/screens/patch_landing_screen.dart';
import '../../features/settings/screens/credits_screen.dart';
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
                builder: (context, state) => const PatchLandingScreen(),
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
      GoRoute(
        path: '/settings/credits',
        builder: (context, state) => const CreditsScreen(),
      ),
      GoRoute(
        path: '/patch/flow',
        builder: (context, state) => PatchFlowScreen(
          mode: state.uri.queryParameters['mode'] ?? 'simple',
        ),
      ),
    ],
  );
}
