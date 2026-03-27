import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class SettingsPasswordScreen extends ConsumerStatefulWidget {
  const SettingsPasswordScreen({super.key});

  @override
  ConsumerState<SettingsPasswordScreen> createState() =>
      _SettingsPasswordScreenState();
}

class _SettingsPasswordScreenState extends ConsumerState<SettingsPasswordScreen> {
  final _currentPw = TextEditingController();
  final _newPw = TextEditingController();
  final _confirmPw = TextEditingController();

  @override
  void dispose() {
    _currentPw.dispose();
    _newPw.dispose();
    _confirmPw.dispose();
    super.dispose();
  }

  String t(String key) => AppStrings.of(context, key);

  Future<void> _submit() async {
    final cur = _currentPw.text;
    final next = _newPw.text;
    final confirm = _confirmPw.text;
    if (next.length < 8) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('passwordMinLength'))),
      );
      return;
    }
    if (next != confirm) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('passwordsDoNotMatch'))),
      );
      return;
    }
    await ref.read(profileControllerProvider.notifier).changePassword(
          currentPassword: cur,
          newPassword: next,
        );
    if (!mounted) return;
    final err = ref.read(profileControllerProvider).error;
    if (err != null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(err))),
      );
      return;
    }
    _currentPw.clear();
    _newPw.clear();
    _confirmPw.clear();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t('passwordChanged'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final busy = ref.watch(profileControllerProvider).isChangingPassword;

    return AppScaffold(
      title: t('settingsPasswordChange'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _currentPw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t('currentPassword'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _newPw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t('newPassword'),
                helperText: t('passwordMinLength'),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _confirmPw,
              obscureText: true,
              decoration: InputDecoration(
                labelText: t('confirmNewPassword'),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: busy ? null : _submit,
                child: Text(t('changePassword')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
