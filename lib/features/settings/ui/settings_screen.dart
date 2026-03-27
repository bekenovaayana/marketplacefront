import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = <_SettingsItem>[
      _SettingsItem(
        title: 'Notifications',
        subtitle: 'Manage alerts and preferences',
        onTap: () => context.push('/settings/notifications'),
      ),
      _SettingsItem(
        title: 'Privacy',
        subtitle: 'Control your privacy options',
        onTap: () => context.push('/settings/privacy'),
      ),
      _SettingsItem(
        title: 'Support',
        subtitle: 'Help and contact',
        onTap: () => context.push('/settings/support'),
      ),
    ];

    return AppScaffold(
      title: 'Settings',
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    title: Text(item.title),
                    subtitle: item.subtitle == null
                        ? null
                        : Text(item.subtitle!),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: item.onTap,
                  );
                },
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemCount: items.length,
              ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(12),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).logout(),
                  icon: const Icon(Icons.logout),
                  label: const Text('Logout'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsItem {
  const _SettingsItem({
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final String title;
  final String? subtitle;
  final VoidCallback onTap;
}
