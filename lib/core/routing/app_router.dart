import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/auth/ui/auth_gate_page.dart';
import 'package:marketplace_frontend/features/auth/ui/login_page.dart';
import 'package:marketplace_frontend/features/auth/ui/register_page.dart';
import 'package:marketplace_frontend/features/notifications/ui/notifications_screen.dart';
import 'package:marketplace_frontend/features/profile/ui/edit_profile_screen.dart';
import 'package:marketplace_frontend/features/promotions/ui/promote_listing_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_stub_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_screen.dart';
import 'package:marketplace_frontend/shared/widgets/main_tabs_page.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.listen<AuthState>(authControllerProvider, (previous, next) {
    notifier.value++;
  });
  return GoRouter(
    initialLocation: '/app',
    refreshListenable: notifier,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (!auth.initialized) return null;
      final protectedRoutes = <String>{'/profile/edit', '/promote'};
      if (auth.initialized &&
          auth.isGuest &&
          protectedRoutes.contains(state.matchedLocation)) {
        final from = Uri.encodeComponent(state.uri.toString());
        return '/auth-gate?from=$from';
      }
      if (auth.initialized &&
          auth.isAuthenticated &&
          state.matchedLocation == '/auth-gate') {
        final from = state.uri.queryParameters['from'];
        if (from != null && from.isNotEmpty) return from;
        return '/app';
      }
      if (auth.initialized &&
          auth.isAuthenticated &&
          (state.matchedLocation == '/login' ||
              state.matchedLocation == '/register')) {
        return '/app';
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/auth-gate',
        builder: (context, state) =>
            AuthGatePage(from: state.uri.queryParameters['from']),
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/app',
        builder: (context, state) {
          final tab = int.tryParse(state.uri.queryParameters['tab'] ?? '') ?? 0;
          return MainTabsPage(initialIndex: tab.clamp(0, 5));
        },
      ),
      GoRoute(
        path: '/notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
        routes: [
          GoRoute(
            path: 'notifications',
            builder: (context, state) =>
                const SettingsStubScreen(title: 'Notifications'),
          ),
          GoRoute(
            path: 'privacy',
            builder: (context, state) =>
                const SettingsStubScreen(title: 'Privacy'),
          ),
          GoRoute(
            path: 'support',
            builder: (context, state) =>
                const SettingsStubScreen(title: 'Support'),
          ),
        ],
      ),
      GoRoute(
        path: '/profile/edit',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/promote',
        builder: (context, state) => const PromoteListingScreen(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});
