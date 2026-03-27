import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class ProfileTab extends ConsumerStatefulWidget {
  const ProfileTab({super.key});

  @override
  ConsumerState<ProfileTab> createState() => _ProfileTabState();
}

class _ProfileTabState extends ConsumerState<ProfileTab>
    with AutomaticKeepAliveClientMixin {
  bool _requestedLoad = false;
  bool _requestedListings = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = ref.watch(authControllerProvider);
    if (auth.isAuthenticated && !_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(
        () => ref.read(profileControllerProvider.notifier).load(),
      );
    }
    if (auth.isAuthenticated && !_requestedListings) {
      _requestedListings = true;
      Future.microtask(
        () => ref.read(myActiveListingsProvider.notifier).load(),
      );
    }
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;
    final listingsState = ref.watch(myActiveListingsProvider);
    if (auth.isGuest) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Profile'),
          actions: [
            IconButton(
              tooltip: 'Settings',
              onPressed: () => context.push('/settings'),
              icon: const Icon(Icons.settings_outlined),
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 12),
            const Icon(Icons.person_outline, size: 64),
            const SizedBox(height: 12),
            const Text(
              'Sign in or create an account',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'Save favorites, post listings, chat with sellers, and manage your profile.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                final from = Uri.encodeComponent('/app?tab=5');
                context.push('/auth-gate?from=$from');
              },
              child: const Text('Sign in / Create account'),
            ),
            const SizedBox(height: 18),
            Card(
              child: ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit profile'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/auth-gate?from=/profile/edit'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Promote listing'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push('/auth-gate?from=/promote'),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () {
          if (!auth.isAuthenticated) return Future.value();
          final a = ref.read(profileControllerProvider.notifier).load();
          final b = ref.read(myActiveListingsProvider.notifier).load();
          return Future.wait(<Future<void>>[a, b]);
        },
        child: ListView(
          key: const PageStorageKey('profile_tab_list'),
          padding: const EdgeInsets.all(16),
          children: [
            if (state.isLoading) ...[
              const SkeletonBox(height: 16, width: 140),
              const SizedBox(height: 10),
              const SkeletonBox(height: 42),
              const SizedBox(height: 10),
              const SkeletonBox(height: 80),
              const SizedBox(height: 10),
              const SkeletonBox(height: 42),
            ],
            if (state.error != null)
              ListTile(
                title: Text(
                  ErrorMapper.friendly(state.error),
                  style: const TextStyle(color: Colors.red),
                ),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(profileControllerProvider.notifier).load(),
                  child: const Text('Retry'),
                ),
              ),
            _AccountCard(
              isLoading: state.isLoading,
              avatarUrl: profile?.avatarUrl,
              fullName: profile?.fullName ?? '',
              onTap: () async {
                final changed = await context.push<bool>('/profile/edit');
                if (changed == true && context.mounted) {
                  await ref.read(profileControllerProvider.notifier).load();
                  await ref.read(myActiveListingsProvider.notifier).load();
                }
              },
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.campaign_outlined),
                title: const Text('Promote listing'),
                subtitle: const Text('Boost your active listing'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final changed = await context.push<bool>('/promote');
                  if (changed == true && context.mounted) {
                    await ref.read(myActiveListingsProvider.notifier).load();
                  }
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'My Active Listings',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 8),
            if (listingsState.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (listingsState.error != null)
              Card(
                child: ListTile(
                  title: Text(
                    ErrorMapper.friendly(listingsState.error),
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: TextButton(
                    onPressed: () =>
                        ref.read(myActiveListingsProvider.notifier).load(),
                    child: const Text('Retry'),
                  ),
                ),
              )
            else if (listingsState.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 18),
                child: Center(child: Text('You have no active listings')),
              )
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  final item = listingsState.items[index];
                  return _ListingMineTile(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailPage(listingId: item.id),
                      ),
                    ),
                  );
                },
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemCount: listingsState.items.length,
              ),
          ],
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  const _AccountCard({
    required this.isLoading,
    required this.avatarUrl,
    required this.fullName,
    required this.onTap,
  });

  final bool isLoading;
  final String? avatarUrl;
  final String fullName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 26,
                backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                    ? NetworkImage(avatarUrl!)
                    : null,
                child: (avatarUrl == null || avatarUrl!.isEmpty)
                    ? const Icon(Icons.person_outline)
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isLoading
                          ? 'Loading…'
                          : (fullName.isEmpty ? 'Your account' : fullName),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Tap to edit profile',
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingMineTile extends StatelessWidget {
  const _ListingMineTile({required this.item, required this.onTap});

  final ListingMine item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: item.cover.isEmpty
            ? const SizedBox(
                width: 56,
                height: 56,
                child: Icon(Icons.image_outlined),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  item.cover,
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 56,
                    height: 56,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
        title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text('${item.price.toStringAsFixed(0)} • ${item.city}'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
