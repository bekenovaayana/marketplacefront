import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/auth/ui/auth_gate_page.dart';
import 'package:marketplace_frontend/features/auth/ui/login_page.dart';
import 'package:marketplace_frontend/features/auth/ui/register_page.dart';
import 'package:marketplace_frontend/features/notifications/ui/notifications_screen.dart';
import 'package:marketplace_frontend/features/payments/ui/wallet_page.dart';
import 'package:marketplace_frontend/features/posting/ui/post_listing_page.dart';
import 'package:marketplace_frontend/features/profile/ui/edit_profile_screen.dart';
import 'package:marketplace_frontend/features/promotions/ui/promote_listing_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_language_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_notifications_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_password_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_screen.dart';
import 'package:marketplace_frontend/features/settings/ui/settings_theme_screen.dart';
import 'package:marketplace_frontend/features/users/ui/user_profile_page.dart';
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
      final protectedRoutes = <String>{
        '/profile/edit',
        '/promote',
        '/notifications',
        '/wallet',
        '/settings/notifications',
        '/settings/password',
      };
      if (auth.initialized && auth.isGuest && state.matchedLocation == '/listings/new') {
        return '/app?tab=4';
      }
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
          return MainTabsPage(initialIndex: tab.clamp(0, 4));
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
            builder: (context, state) => const SettingsNotificationsScreen(),
          ),
          GoRoute(
            path: 'theme',
            builder: (context, state) => const SettingsThemeScreen(),
          ),
          GoRoute(
            path: 'language',
            builder: (context, state) => const SettingsLanguageScreen(),
          ),
          GoRoute(
            path: 'password',
            builder: (context, state) => const SettingsPasswordScreen(),
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
      GoRoute(
        path: '/wallet',
        builder: (context, state) => const WalletPage(),
      ),
      GoRoute(
        path: '/user/:userId',
        builder: (context, state) {
          final id = int.tryParse(state.pathParameters['userId'] ?? '') ?? 0;
          return UserProfilePage(userId: id);
        },
      ),
      GoRoute(
        path: '/listings/new',
        builder: (context, state) => const PostListingPage(),
      ),
    ],
    errorBuilder: (context, state) =>
        Scaffold(body: Center(child: Text(state.error.toString()))),
  );
});
