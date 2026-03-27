import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/settings/settings_user_me_sync.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/state/app_preferences.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsLanguageScreen extends ConsumerWidget {
  const SettingsLanguageScreen({super.key});

  Future<void> _onLang(
    BuildContext context,
    WidgetRef ref,
    String lang,
  ) async {
    final auth = ref.read(authControllerProvider);
    final locale = lang == 'ru' ? const Locale('ru') : const Locale('en');
    ref.read(appPreferencesProvider.notifier).setLocale(locale);
    if (!auth.isAuthenticated) return;
    await patchUserMeAndSync(
      ref,
      context,
      UpdateUserMeRequest(preferredLanguage: lang),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(appPreferencesProvider);
    String t(String key) => AppStrings.of(context, key);

    return AppScaffold(
      title: t('settingsLanguage'),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SegmentedButton<String>(
                segments: [
                  ButtonSegment(
                    value: 'en',
                    label: Text(t('langEnglish')),
                  ),
                  ButtonSegment(
                    value: 'ru',
                    label: Text(t('langRussian')),
                  ),
                ],
                selected: {prefs.locale.languageCode == 'ru' ? 'ru' : 'en'},
                emptySelectionAllowed: false,
                onSelectionChanged: (s) => _onLang(context, ref, s.first),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
