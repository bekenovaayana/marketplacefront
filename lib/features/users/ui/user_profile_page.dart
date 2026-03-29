import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/favorites/state/favorites_controller.dart';
import 'package:marketplace_frontend/features/home/state/home_controller.dart';
import 'package:marketplace_frontend/features/listings/data/listings_api.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/features/users/data/public_user_profile.dart';
import 'package:marketplace_frontend/features/users/data/users_api.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/listing_card.dart';

class UserProfilePageData {
  const UserProfilePageData({
    required this.user,
    required this.listings,
  });

  final PublicUserProfile user;
  final List<ListingPublic> listings;
}

final userProfilePageDataProvider =
    FutureProvider.family<UserProfilePageData, int>((ref, userId) async {
  if (userId <= 0) {
    throw StateError('Invalid user id');
  }
  final usersApi = ref.watch(usersApiProvider);
  final listingsApi = ref.watch(listingsApiProvider);
  final user = await usersApi.getUser(userId);
  final listings =
      await listingsApi.fetchActiveListingsForUser(userId: userId);
  return UserProfilePageData(user: user, listings: listings);
});

/// Seller-focused profile: avatar, name, active listings grid.
class UserProfilePage extends ConsumerWidget {
  const UserProfilePage({super.key, required this.userId});

  final int userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String key) => AppStrings.of(context, key);
    final async = ref.watch(userProfilePageDataProvider(userId));

    return Scaffold(
      appBar: AppBar(title: Text(t('userProfileTitle'))),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(ErrorMapper.friendly(e)),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(userProfilePageDataProvider(userId)),
                  child: Text(t('retry')),
                ),
              ],
            ),
          ),
        ),
        data: (data) => _UserProfileBody(data: data),
      ),
    );
  }
}

class _UserProfileBody extends ConsumerWidget {
  const _UserProfileBody({required this.data});

  final UserProfilePageData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String key) => AppStrings.of(context, key);
    final user = data.user;
    final avatarUrl = ApiUrls.avatarUrlForDisplay(user.avatarUrl);
    final auth = ref.watch(authControllerProvider);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 48,
                  backgroundImage: avatarUrl.isNotEmpty
                      ? NetworkImage(avatarUrl)
                      : null,
                  child: avatarUrl.isEmpty
                      ? Text(
                          user.fullName.isNotEmpty ? user.fullName[0] : '?',
                          style: const TextStyle(fontSize: 36),
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  user.fullName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t('userProfileActiveListings'),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        if (data.listings.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(t('userProfileNoListings'))),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.60,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = data.listings[index];
                  return ListingCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ListingDetailPage(listingId: item.id),
                      ),
                    ),
                    onFavoriteTap: () async {
                      if (!auth.isAuthenticated) {
                        final from = Uri.encodeComponent(
                          GoRouterState.of(context).uri.toString(),
                        );
                        if (context.mounted) {
                          context.push('/auth-gate?from=$from');
                        }
                        return;
                      }
                      final favorite = item.isFavorite;
                      ref
                          .read(homeControllerProvider.notifier)
                          .syncFavorite(item.id, !favorite);
                      if (!favorite) {
                        await ref
                            .read(favoritesControllerProvider.notifier)
                            .add(item.id);
                      } else {
                        await ref
                            .read(favoritesControllerProvider.notifier)
                            .remove(item.id);
                      }
                    },
                  );
                },
                childCount: data.listings.length,
              ),
            ),
          ),
      ],
    );
  }
}
