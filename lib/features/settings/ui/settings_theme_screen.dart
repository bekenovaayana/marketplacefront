import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/settings/settings_user_me_sync.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/state/app_preferences.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsThemeScreen extends ConsumerWidget {
  const SettingsThemeScreen({super.key});

  Future<void> _onTheme(
    BuildContext context,
    WidgetRef ref,
    ThemeMode mode,
  ) async {
    final auth = ref.read(authControllerProvider);
    ref.read(appPreferencesProvider.notifier).setThemeMode(mode);
    if (!auth.isAuthenticated) return;
    await patchUserMeAndSync(
      ref,
      context,
      UpdateUserMeRequest(
        theme: AppPreferencesNotifier.apiThemeFromMode(mode),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    String t(String key) => AppStrings.of(context, key);

    return AppScaffold(
      title: t('settingsAppearance'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                    value: ThemeMode.light,
                    label: Text(t('themeLight')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.dark,
                    label: Text(t('themeDark')),
                  ),
                  ButtonSegment(
                    value: ThemeMode.system,
                    label: Text(t('themeSystem')),
                  ),
                ],
                selected: {prefs.themeMode},
                emptySelectionAllowed: false,
                onSelectionChanged: (s) => _onTheme(context, ref, s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
