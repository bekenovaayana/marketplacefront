import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/features/settings/settings_user_me_sync.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsNotificationsScreen extends ConsumerStatefulWidget {
  const SettingsNotificationsScreen({super.key});

  @override
  ConsumerState<SettingsNotificationsScreen> createState() =>
      _SettingsNotificationsScreenState();
}

class _SettingsNotificationsScreenState
    extends ConsumerState<SettingsNotificationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(profileControllerProvider.notifier).load();
    });
  }

  String t(String key) => AppStrings.of(context, key);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    return AppScaffold(
      title: t('settingsNotifications'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          children: [
            if (state.error != null && profile == null && !state.isLoading)
              ListTile(
                title: Text(
                  ErrorMapper.friendly(state.error),
                  style: const TextStyle(color: Colors.red),
                ),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(profileControllerProvider.notifier).load(),
                  child: Text(t('retry')),
                ),
              ),
            if (state.isLoading && profile == null)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (profile != null) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('notifyNewMessage')),
                value: profile.notifyNewMessage,
                onChanged: state.isSaving
                    ? null
                    : (v) => patchUserMeAndSync(
                          ref,
                          context,
                          UpdateUserMeRequest(notifyNewMessage: v),
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('notifyContactRequest')),
                value: profile.notifyContactRequest,
                onChanged: state.isSaving
                    ? null
                    : (v) => patchUserMeAndSync(
                          ref,
                          context,
                          UpdateUserMeRequest(notifyContactRequest: v),
                        ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t('notifyListingFavorited')),
                value: profile.notifyListingFavorited,
                onChanged: state.isSaving
                    ? null
                    : (v) => patchUserMeAndSync(
                          ref,
                          context,
                          UpdateUserMeRequest(notifyListingFavorited: v),
                        ),
              ),
            ],
            const SizedBox(height: 24),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(t('settingsViewInbox')),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/notifications'),
            ),
          ],
        ),
      ),
    );
  }
}
