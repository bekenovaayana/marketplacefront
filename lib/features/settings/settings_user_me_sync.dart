import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/shared/state/app_preferences.dart';

Future<void> patchUserMeAndSync(
  WidgetRef ref,
  BuildContext context,
  UpdateUserMeRequest request,
) async {
  final ok = await ref.read(profileControllerProvider.notifier).patchMe(request);
  if (!context.mounted) return;
  if (ok) {
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null) {
      ref.read(appPreferencesProvider.notifier).applyFromUserMe(profile);
    }
  } else {
    final err = ref.read(profileControllerProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(ErrorMapper.friendly(err))),
    );
    await ref.read(profileControllerProvider.notifier).load();
    final profile = ref.read(profileControllerProvider).profile;
    if (profile != null && context.mounted) {
      ref.read(appPreferencesProvider.notifier).applyFromUserMe(profile);
    }
  }
}
