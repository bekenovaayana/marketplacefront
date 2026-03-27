import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/features/promotions/data/promotions_api.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class ProfileMyListingsPanel extends ConsumerWidget {
  const ProfileMyListingsPanel({super.key});

  String _tabLabel(BuildContext context, ProfileListingsTab t) {
    final m = AppStrings.of;
    switch (t) {
      case ProfileListingsTab.active:
        return m(context, 'profileTabActive');
      case ProfileListingsTab.draft:
        return m(context, 'profileTabDraft');
      case ProfileListingsTab.inactive:
        return m(context, 'profileTabInactive');
      case ProfileListingsTab.sold:
        return m(context, 'profileTabSold');
      case ProfileListingsTab.pendingPayment:
        return m(context, 'profileTabPendingPay');
    }
  }

  String _emptyTitle(BuildContext context, ProfileListingsTab t) {
    final m = AppStrings.of;
    switch (t) {
      case ProfileListingsTab.active:
        return m(context, 'profileEmptyActive');
      case ProfileListingsTab.draft:
        return m(context, 'profileEmptyDraft');
      case ProfileListingsTab.inactive:
        return m(context, 'profileEmptyInactive');
      case ProfileListingsTab.sold:
        return m(context, 'profileEmptySold');
      case ProfileListingsTab.pendingPayment:
        return m(context, 'profileEmptyPending');
    }
  }

  String _categoryButtonText(BuildContext context, WidgetRef ref) {
    final s = ref.watch(myActiveListingsProvider);
    final t = AppStrings.of(context, 'profileCategory');
    if (s.categoryId == null) {
      return '$t: ${AppStrings.of(context, 'profileChipAll')}';
    }
    String name = AppStrings.of(context, 'profileChipAll');
    for (final c in s.apiCategories) {
      if (c.id == s.categoryId) {
        name = c.name.isNotEmpty ? c.name : c.slug;
        break;
      }
    }
    return '$t: $name';
  }

  String _sortButtonText(BuildContext context, String sort) {
    final p = AppStrings.of(context, 'profileSort');
    final tail = switch (sort) {
      'price_asc' => AppStrings.of(context, 'profileSortPriceAsc'),
      'price_desc' => AppStrings.of(context, 'profileSortPriceDesc'),
      _ => AppStrings.of(context, 'profileSortNewest'),
    };
    return '$p: $tail';
  }

  Future<void> _openCategorySheet(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(myActiveListingsProvider.notifier);
    final s = ref.read(myActiveListingsProvider);
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        String tt(String k) => AppStrings.of(ctx, k);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    tt('profileCategory'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                ListTile(
                  title: Text(tt('profileChipAll')),
                  trailing: s.categoryId == null
                      ? const Icon(Icons.check, color: Color(0xFF1BB35E))
                      : null,
                  onTap: () async {
                    notifier.selectCategoryChip(null);
                    Navigator.pop(ctx);
                    await notifier.refresh();
                  },
                ),
                ...s.resolvedChips.map(
                  (c) => ListTile(
                    title: Text(c.labelRu),
                    enabled: c.isMatched,
                    subtitle: c.isMatched
                        ? null
                        : Text(tt('categoryChipUnavailable')),
                    trailing: s.categoryId == c.categoryId
                        ? const Icon(Icons.check, color: Color(0xFF1BB35E))
                        : null,
                    onTap: c.isMatched
                        ? () async {
                            notifier.selectCategoryChip(c.categoryId);
                            Navigator.pop(ctx);
                            await notifier.refresh();
                          }
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextButton(
                    onPressed: () async {
                      notifier.selectCategoryChip(null);
                      Navigator.pop(ctx);
                      await notifier.refresh();
                    },
                    child: Text(tt('profileCategoryClear')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String tt(String k) => AppStrings.of(context, k);
    final s = ref.watch(myActiveListingsProvider);
    final notifier = ref.read(myActiveListingsProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          tt('profileMyListings'),
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final tab in ProfileListingsTab.values)
                Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(_tabLabel(context, tab)),
                    selected: s.tab == tab,
                    onSelected: (_) => notifier.setTab(tab),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 42,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: Text(tt('profileChipAll')),
                  selected: s.categoryId == null,
                  onSelected: (_) => notifier.toggleCategoryFilter(null),
                ),
              ),
              ...s.resolvedChips.map(
                (c) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: FilterChip(
                    label: Text(c.labelRu),
                    selected:
                        c.categoryId != null && s.categoryId == c.categoryId,
                    onSelected: c.isMatched
                        ? (_) =>
                            notifier.toggleCategoryFilter(c.categoryId)
                        : (_) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(tt('categoryChipUnavailable')),
                              ),
                            );
                          },
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: s.isLoading ? null : () => _openCategorySheet(context, ref),
                child: Text(
                  _categoryButtonText(context, ref),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: s.isLoading || s.tab == ProfileListingsTab.pendingPayment
                    ? null
                    : () async {
                        final sort = await showModalBottomSheet<String>(
                          context: context,
                          showDragHandle: true,
                          builder: (ctx) => SafeArea(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                ListTile(
                                  title: Text(tt('profileSortNewest')),
                                  trailing: s.sort == 'newest'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () => Navigator.pop(ctx, 'newest'),
                                ),
                                ListTile(
                                  title: Text(tt('profileSortPriceAsc')),
                                  trailing: s.sort == 'price_asc'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () => Navigator.pop(ctx, 'price_asc'),
                                ),
                                ListTile(
                                  title: Text(tt('profileSortPriceDesc')),
                                  trailing: s.sort == 'price_desc'
                                      ? const Icon(Icons.check)
                                      : null,
                                  onTap: () =>
                                      Navigator.pop(ctx, 'price_desc'),
                                ),
                              ],
                            ),
                          ),
                        );
                        if (sort != null && context.mounted) {
                          notifier.setSort(sort);
                        }
                      },
                child: Text(
                  _sortButtonText(context, s.sort),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (s.isLoading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (s.error != null)
          ListTile(
            title: Text(
              ErrorMapper.friendly(s.error),
              style: const TextStyle(color: Colors.red),
            ),
            trailing: TextButton(
              onPressed: () => notifier.refresh(),
              child: Text(tt('retry')),
            ),
          )
        else if (s.tab == ProfileListingsTab.pendingPayment)
          _PendingPaymentsList(
            promotions: s.pendingPromotions,
            previews: s.pendingPreviews,
          )
        else if (s.items.isEmpty)
          _EmptyListings(
            title: _emptyTitle(context, s.tab),
            hint: tt('profileTemshikHint'),
            onPost: () => context.go('/app?tab=2'),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: s.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final item = s.items[i];
              return _ListingMineCard(
                item: item,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ListingDetailPage(listingId: item.id),
                  ),
                ),
              );
            },
          ),
      ],
    );
  }
}

class _ListingMineCard extends StatelessWidget {
  const _ListingMineCard({required this.item, required this.onTap});

  final ListingMine item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final url = ApiUrls.absoluteUrl(item.cover);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: url.isEmpty
                    ? Container(
                        width: 72,
                        height: 72,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image_outlined),
                      )
                    : Image.network(
                        url,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(
                          width: 72,
                          height: 72,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (item.isBoosted)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Chip(
                          padding: EdgeInsets.zero,
                          label: Text(
                            AppStrings.of(context, 'profileBoosted'),
                            style: const TextStyle(fontSize: 11),
                          ),
                          visualDensity: VisualDensity.compact,
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          backgroundColor: const Color(0x331BB35E),
                        ),
                      ),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.price.toStringAsFixed(0)} ${item.currency} • ${item.city}',
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

class _PendingPaymentsList extends StatelessWidget {
  const _PendingPaymentsList({
    required this.promotions,
    required this.previews,
  });

  final List<PromotionListItem> promotions;
  final Map<int, ListingPreviewCard?> previews;

  @override
  Widget build(BuildContext context) {
    final tt = AppStrings.of;
    if (promotions.isEmpty) {
      return _EmptyListings(
        title: tt(context, 'profileEmptyPending'),
        hint: tt(context, 'profileTemshikHint'),
        onPost: () => context.go('/app?tab=2'),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: promotions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (ctx, i) {
        final p = promotions[i];
        final pv = previews[p.listingId];
        final img = pv != null ? ApiUrls.absoluteUrl(pv.imageUrl) : '';
        return Card(
          child: InkWell(
            onTap: p.listingId > 0
                ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ListingDetailPage(listingId: p.listingId),
                      ),
                    )
                : null,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (img.isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        img,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const SizedBox(
                          width: 64,
                          height: 64,
                          child: Icon(Icons.image_outlined),
                        ),
                      ),
                    )
                  else
                    const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.payments_outlined),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tt(context, 'profilePendingPayTitle'),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (pv != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            pv.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${pv.price.toStringAsFixed(0)} ${pv.currency} • ${pv.city}',
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                        ],
                        if (p.price != null)
                          Text(
                            '${p.price!.toStringAsFixed(0)} ${p.currency ?? ''}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1BB35E),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _EmptyListings extends StatelessWidget {
  const _EmptyListings({
    required this.title,
    required this.hint,
    required this.onPost,
  });

  final String title;
  final String hint;
  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
          ),
          const SizedBox(height: 14),
          FilledButton(
            onPressed: onPost,
            child: Text(AppStrings.of(context, 'profilePostListing')),
          ),
        ],
      ),
    );
  }
}
