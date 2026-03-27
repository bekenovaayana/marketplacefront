import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/legacy.dart' show StateNotifier, StateNotifierProvider;
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/profile/data/profile_repository.dart';

class AppPreferences {
  const AppPreferences({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('ru'),
  });

  final ThemeMode themeMode;
  final Locale locale;

  AppPreferences copyWith({
    ThemeMode? themeMode,
    Locale? locale,
  }) {
    return AppPreferences(
      themeMode: themeMode ?? this.themeMode,
      locale: locale ?? this.locale,
    );
  }
}

final appPreferencesProvider =
    StateNotifierProvider<AppPreferencesNotifier, AppPreferences>((ref) {
      return AppPreferencesNotifier(ref.watch(profileRepositoryProvider));
    });

class AppPreferencesNotifier extends StateNotifier<AppPreferences> {
  AppPreferencesNotifier(this._profileRepository)
    : super(const AppPreferences());

  final ProfileRepository _profileRepository;

  static ThemeMode themeModeFromApi(String? raw) {
    switch (raw) {
      case 'dark':
        return ThemeMode.dark;
      case 'light':
        return ThemeMode.light;
      default:
        return ThemeMode.system;
    }
  }

  static String apiThemeFromMode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.light:
        return 'light';
      case ThemeMode.system:
        return 'system';
    }
  }

  static Locale localeFromApi(String? lang) {
    if (lang == 'ru') return const Locale('ru');
    if (lang == 'en') return const Locale('en');
    final platformLang =
        PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (platformLang == 'ru') return const Locale('ru');
    return const Locale('en');
  }

  void applyFromUserMe(UserMeResponse me) {
    state = AppPreferences(
      themeMode: themeModeFromApi(me.theme),
      locale: localeFromApi(me.preferredLanguage),
    );
  }

  Future<void> syncFromServer() async {
    try {
      final me = await _profileRepository.getMe();
      applyFromUserMe(me);
    } catch (_) {}
  }

  void setThemeMode(ThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setLocale(Locale locale) {
    state = state.copyWith(locale: locale);
  }

  void resetToGuestDefaults() {
    state = const AppPreferences();
  }
}
