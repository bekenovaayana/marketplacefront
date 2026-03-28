import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';

class ProfileListingsNavIntent {
  const ProfileListingsNavIntent({
    required this.tab,
    this.filterCategoryId,
    required this.nonce,
  });

  final ProfileListingsTab tab;
  final int? filterCategoryId;
  final int nonce;
}

class ProfileListingsNavIntentNotifier
    extends StateNotifier<ProfileListingsNavIntent?> {
  ProfileListingsNavIntentNotifier() : super(null);

  void setIntent(ProfileListingsNavIntent value) => state = value;

  void clear() => state = null;
}

final profileListingsNavIntentProvider = StateNotifierProvider<
    ProfileListingsNavIntentNotifier,
    ProfileListingsNavIntent?>((ref) {
  return ProfileListingsNavIntentNotifier();
});
