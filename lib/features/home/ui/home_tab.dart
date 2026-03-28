import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/favorites/state/favorites_controller.dart';
import 'package:marketplace_frontend/features/home/data/home_repository.dart';
import 'package:marketplace_frontend/features/home/state/home_controller.dart';
import 'package:marketplace_frontend/features/home/ui/widgets/home_filter_sheet.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';
import 'package:marketplace_frontend/shared/data/category_catalog.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/listing_card.dart';
import 'package:marketplace_frontend/shared/widgets/pagination_loader.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab>
    with AutomaticKeepAliveClientMixin {
  final _searchController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(homeControllerProvider.notifier).loadInitial());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String t(String key) => AppStrings.of(context, key);
    final state = ref.watch(homeControllerProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(homeControllerProvider.notifier).loadInitial(),
        child: ListView(
          key: const PageStorageKey('home_tab_list'),
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: t('searchListings'),
                      prefixIcon: Icon(Icons.search),
                    ),
                    textInputAction: TextInputAction.search,
                    onChanged: (value) {
                      ref.read(homeControllerProvider.notifier).search(query: value);
                    },
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton.tonal(
                  onPressed: () async {
                    await ref.read(homeControllerProvider.notifier).loadFacets();
                    if (!context.mounted) return;
                    final latestState = ref.read(homeControllerProvider);
                    final query = await showModalBottomSheet<ListingQuery>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => HomeFilterSheet(
                        categories: latestState.categories,
                        facets: latestState.facets,
                        initial: latestState.query,
                      ),
                    );
                    if (query != null && context.mounted) {
                      await ref.read(homeControllerProvider.notifier).applyFilters(query);
                    }
                  },
                  child: Text(t('filter')),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (state.isLoading) ...[
              const SkeletonBox(height: 40),
              const SizedBox(height: 10),
              const SkeletonBox(height: 90),
              const SizedBox(height: 10),
              const ListingGridSkeleton(),
              const SizedBox(height: 10),
            ],
            if (state.error != null)
              ListTile(
                title: Text(ErrorMapper.friendly(state.error)),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(homeControllerProvider.notifier).loadInitial(),
                  child: Text(t('retry')),
                ),
              ),
            if (!state.inSearchMode) ...[
              _SectionTitle(
                title: t('categories'),
                action: state.categories.length > 8 ? t('seeAll') : null,
              ),
              Builder(
                builder: (context) {
                  final resolved = CategoryCatalog.resolve(state.categories);
                  final (row1, row2) = CategoryCatalog.splitTwoRows(resolved);

                  Widget railRow(List<ResolvedFixedCategory> row) {
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final item in row)
                            Padding(
                              padding: const EdgeInsets.only(right: 10),
                              child: GestureDetector(
                                onTap: item.isMatched
                                    ? () => ref
                                          .read(homeControllerProvider.notifier)
                                          .setHomeCategoryFilter(item.categoryId)
                                    : () => ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(t('categoryChipUnavailable'))),
                                        ),
                                child: Container(
                                  width: 166,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: item.categoryId != null && state.query.categoryId == item.categoryId
                                        ? const Color(0xFFD7F2E2)
                                        : const Color(0xFFEAF8F0),
                                    borderRadius: BorderRadius.circular(14),
                                    border: item.isMatched
                                        ? Border.all(
                                            color: item.categoryId != null &&
                                                    state.query.categoryId == item.categoryId
                                                ? const Color(0xFF1BB35E)
                                                : Colors.transparent,
                                          )
                                        : Border.all(color: Colors.black12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        item.labelRu,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w600),
                                      ),
                                      Text(
                                        item.isMatched
                                            ? '${item.apiCategory?.listingsCount ?? 0} объявлений'
                                            : t('categoryChipUnavailable'),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: item.isMatched ? Colors.grey.shade700 : Colors.grey.shade500,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => ref.read(homeControllerProvider.notifier).setHomeCategoryFilter(null),
                          child: Text(
                            state.query.categoryId == null ? '${t('clear')}: ${t('profileChipAll')}' : t('clear'),
                          ),
                        ),
                      ),
                      railRow(row1),
                      const SizedBox(height: 8),
                      railRow(row2),
                    ],
                  );
                },
              ),
              const SizedBox(height: 10),
              _PromoBanner(
                title: t('promoTitle'),
                subtitle: t('promoSubtitle'),
              ),
              const SizedBox(height: 10),
              _SectionTitle(title: t('recommended')),
              _ListingsGrid(
                items: state.recommended,
                onTap: (id) => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailPage(listingId: id)),
                ),
                onFavoriteTap: (id, favorite) async {
                  ref.read(homeControllerProvider.notifier).syncFavorite(id, !favorite);
                  if (!favorite) {
                    await ref.read(favoritesControllerProvider.notifier).add(id);
                  } else {
                    await ref.read(favoritesControllerProvider.notifier).remove(id);
                  }
                },
              ),
              const SizedBox(height: 10),
              _SectionTitle(title: t('new')),
              _ListingsGrid(
                items: state.latest,
                onTap: (id) => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailPage(listingId: id)),
                ),
                onFavoriteTap: (id, favorite) async {
                  ref.read(homeControllerProvider.notifier).syncFavorite(id, !favorite);
                  if (!favorite) {
                    await ref.read(favoritesControllerProvider.notifier).add(id);
                  } else {
                    await ref.read(favoritesControllerProvider.notifier).remove(id);
                  }
                },
              ),
            ] else ...[
              _SectionTitle(
                title: t('results'),
                action: t('clear'),
                onActionTap: () {
                  _searchController.clear();
                  ref.read(homeControllerProvider.notifier).applyFilters(
                        const ListingQuery(),
                      );
                },
              ),
              if (state.feed.isEmpty && !state.isLoading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      state.query.q?.isNotEmpty == true
                          ? 'No results for "${state.query.q}"'
                          : 'No listings for selected filters',
                    ),
                  ),
                ),
              _ListingsGrid(
                items: state.feed,
                onTap: (id) => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => ListingDetailPage(listingId: id)),
                ),
                onFavoriteTap: (id, favorite) async {
                  ref.read(homeControllerProvider.notifier).syncFavorite(id, !favorite);
                  if (!favorite) {
                    await ref.read(favoritesControllerProvider.notifier).add(id);
                  } else {
                    await ref.read(favoritesControllerProvider.notifier).remove(id);
                  }
                },
              ),
              PaginationLoader(
                hasMore: state.hasMore,
                isLoadingMore: state.isLoadingMore,
                onLoadMore: () => ref.read(homeControllerProvider.notifier).loadMore(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    this.action,
    this.onActionTap,
  });

  final String title;
  final String? action;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
        if (action != null)
          TextButton(
            onPressed: onActionTap,
            child: Text(action!),
          ),
      ],
    );
  }
}

class _PromoBanner extends StatelessWidget {
  const _PromoBanner({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [Color(0xFFFFF1F4), Color(0xFFFFFDF2)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          const Icon(Icons.local_offer_outlined, color: Color(0xFFE45A76)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingsGrid extends StatelessWidget {
  const _ListingsGrid({
    required this.items,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final List<ListingPublic> items;
  final void Function(int id) onTap;
  final Future<void> Function(int id, bool favorite) onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      itemCount: items.length,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.60,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListingCard(
          item: item,
          onTap: () => onTap(item.id),
          onFavoriteTap: () => onFavoriteTap(item.id, item.isFavorite),
        );
      },
    );
  }
}
