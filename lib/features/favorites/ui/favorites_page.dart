import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/favorites/state/favorites_controller.dart';
import 'package:marketplace_frontend/features/home/state/home_controller.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/listing_card.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class FavoritesPage extends ConsumerStatefulWidget {
  const FavoritesPage({super.key});

  @override
  ConsumerState<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends ConsumerState<FavoritesPage>
    with AutomaticKeepAliveClientMixin {
  bool _requestedLoad = false;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String t(String key) => AppStrings.of(context, key);
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.favorite_border, size: 56),
                const SizedBox(height: 10),
                const Text('Sign in to save favorites'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final from = Uri.encodeComponent('/app?tab=1');
                    context.push('/auth-gate?from=$from');
                  },
                  child: const Text('Sign in / Create account'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (auth.isAuthenticated && !_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(
        () => ref.read(favoritesControllerProvider.notifier).load(),
      );
    }
    final state = ref.watch(favoritesControllerProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          if (!auth.isAuthenticated) return Future.value();
          return ref.read(favoritesControllerProvider.notifier).load();
        },
        child: state.isLoading
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: ListingGridSkeleton(),
              )
            : state.error != null
            ? ListView(
                children: [
                  ListTile(
                    title: Text(ErrorMapper.friendly(state.error)),
                    trailing: TextButton(
                      onPressed: () =>
                          ref.read(favoritesControllerProvider.notifier).load(),
                      child: Text(t('retry')),
                    ),
                  ),
                ],
              )
            : state.items.isEmpty
            ? ListView(
                key: const PageStorageKey('favorites_tab_list'),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(t('noFavorites'))),
                ],
              )
            : GridView.builder(
                key: const PageStorageKey('favorites_tab_grid'),
                padding: const EdgeInsets.all(12),
                itemCount: state.items.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.60,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemBuilder: (context, index) {
                  final item = state.items[index];
                  return ListingCard(
                    item: item,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ListingDetailPage(listingId: item.id),
                      ),
                    ),
                    onFavoriteTap: () async {
                      await ref
                          .read(favoritesControllerProvider.notifier)
                          .remove(item.id);
                      ref
                          .read(homeControllerProvider.notifier)
                          .syncFavorite(item.id, false);
                    },
                  );
                },
              ),
      ),
    );
  }
}
