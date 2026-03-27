import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    String t(String key) => AppStrings.of(context, key);

    return AppScaffold(
      title: t('settings'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    title: Text(t('settingsNotifications')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (!auth.isAuthenticated) {
                        final from = Uri.encodeComponent(
                          GoRouterState.of(context).uri.toString(),
                        );
                        context.push('/auth-gate?from=$from');
                        return;
                      }
                      context.push('/settings/notifications');
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(t('settingsAppearance')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/theme'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(t('settingsLanguage')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push('/settings/language'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    title: Text(t('settingsPasswordChange')),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      if (!auth.isAuthenticated) {
                        final from = Uri.encodeComponent(
                          GoRouterState.of(context).uri.toString(),
                        );
                        context.push('/auth-gate?from=$from');
                        return;
                      }
                      context.push('/settings/password');
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await ref.read(authControllerProvider.notifier).logout();
                    if (context.mounted) context.go('/login');
                  },
                  icon: const Icon(Icons.logout),
                  label: Text(t('logout')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
