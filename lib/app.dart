import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/core/routing/app_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/state/app_preferences.dart';
import 'package:marketplace_frontend/shared/theme/app_theme.dart';

class MarketplaceApp extends ConsumerStatefulWidget {
  const MarketplaceApp({super.key});

  @override
  ConsumerState<MarketplaceApp> createState() => _MarketplaceAppState();
}

class _MarketplaceAppState extends ConsumerState<MarketplaceApp> {
  ValueNotifier<int>? _sessionNotifier;
  int _lastSessionValue = 0;
  ValueNotifier<int>? _reauthNotifier;
  int _lastReauthValue = 0;

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(authControllerProvider.notifier).initialize();
    });
    _sessionNotifier = ref.read(sessionExpiredProvider);
    _lastSessionValue = _sessionNotifier!.value;
    _sessionNotifier!.addListener(_onSessionExpired);
    _reauthNotifier = ref.read(reauthCoordinatorProvider).promptTicker;
    _lastReauthValue = _reauthNotifier!.value;
    _reauthNotifier!.addListener(_onReauthRequested);
  }

  @override
  void dispose() {
    _sessionNotifier?.removeListener(_onSessionExpired);
    _reauthNotifier?.removeListener(_onReauthRequested);
    super.dispose();
  }

  void _onSessionExpired() {
    final value = _sessionNotifier?.value ?? 0;
    if (value != _lastSessionValue) {
      _lastSessionValue = value;
      ref.read(authControllerProvider.notifier).handleUnauthorized();
    }
  }

  void _onReauthRequested() {
    final value = _reauthNotifier?.value ?? 0;
    if (value == _lastReauthValue) return;
    _lastReauthValue = value;
    final router = ref.read(appRouterProvider);
    final location = router.routeInformationProvider.value.uri.toString();
    if (location.startsWith('/auth-gate')) return;
    final encoded = Uri.encodeComponent(location);
    router.push('/auth-gate?from=$encoded');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<AuthState>(authControllerProvider, (previous, next) {
      if (!next.initialized) return;
      if (next.isAuthenticated) {
        final sameSession = previous?.isAuthenticated == true &&
            previous?.user?.id == next.user?.id;
        if (sameSession) return;
        Future.microtask(
          () => ref.read(appPreferencesProvider.notifier).syncFromServer(),
        );
      } else {
        ref.read(appPreferencesProvider.notifier).resetToGuestDefaults();
      }
    });
    final router = ref.watch(appRouterProvider);
    final prefs = ref.watch(appPreferencesProvider);
    return MaterialApp.router(
      title: 'Marketplace',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: prefs.themeMode,
      routerConfig: router,
      supportedLocales: AppStrings.supportedLocales,
      locale: prefs.locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
