import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_repository.dart';
import 'package:marketplace_frontend/features/profile/data/profile_category_chips.dart';
import 'package:marketplace_frontend/features/promotions/data/promotions_api.dart';

enum ProfileListingsTab {
  active,
  draft,
  inactive,
  sold,
  pendingPayment,
}

extension on ProfileListingsTab {
  String? get listingsApiStatus {
    switch (this) {
      case ProfileListingsTab.active:
        return 'active';
      case ProfileListingsTab.draft:
        return 'draft';
      case ProfileListingsTab.inactive:
        return 'inactive';
      case ProfileListingsTab.sold:
        return 'sold';
      case ProfileListingsTab.pendingPayment:
        return null;
    }
  }
}

class ProfileMyListingsState {
  const ProfileMyListingsState({
    this.isLoading = false,
    this.items = const [],
    this.pendingPromotions = const [],
    this.pendingPreviews = const {},
    this.apiCategories = const [],
    this.resolvedChips = const [],
    this.tab = ProfileListingsTab.active,
    this.categoryId,
    this.sort = 'newest',
    this.error,
  });

  final bool isLoading;
  final List<ListingMine> items;
  final List<PromotionListItem> pendingPromotions;
  final Map<int, ListingPreviewCard?> pendingPreviews;
  final List<HomeCategory> apiCategories;
  final List<ProfileCategoryChipResolved> resolvedChips;
  final ProfileListingsTab tab;
  final int? categoryId;
  final String sort;
  final Object? error;

  ProfileMyListingsState copyWith({
    bool? isLoading,
    List<ListingMine>? items,
    List<PromotionListItem>? pendingPromotions,
    Map<int, ListingPreviewCard?>? pendingPreviews,
    List<HomeCategory>? apiCategories,
    List<ProfileCategoryChipResolved>? resolvedChips,
    ProfileListingsTab? tab,
    int? categoryId,
    bool clearCategory = false,
    String? sort,
    Object? error,
    bool clearError = false,
  }) {
    return ProfileMyListingsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      pendingPromotions: pendingPromotions ?? this.pendingPromotions,
      pendingPreviews: pendingPreviews ?? this.pendingPreviews,
      apiCategories: apiCategories ?? this.apiCategories,
      resolvedChips: resolvedChips ?? this.resolvedChips,
      tab: tab ?? this.tab,
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      sort: sort ?? this.sort,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final myActiveListingsProvider =
    StateNotifierProvider<MyActiveListingsController, ProfileMyListingsState>((
      ref,
    ) {
      return MyActiveListingsController(
        ref.watch(postingRepositoryProvider),
        ref.watch(promotionsApiProvider),
      );
    });

class MyActiveListingsController extends StateNotifier<ProfileMyListingsState> {
  MyActiveListingsController(this._repo, this._promotionsApi)
    : super(const ProfileMyListingsState());

  final PostingRepository _repo;
  final PromotionsApi _promotionsApi;

  Future<void> ensureCategories() async {
    if (state.apiCategories.isNotEmpty) return;
    try {
      final cats = await _repo.categories();
      state = state.copyWith(
        apiCategories: cats,
        resolvedChips: ProfileCategoryChips.resolve(cats),
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(error: e);
    }
  }

  Future<void> setTab(ProfileListingsTab tab) async {
    state = state.copyWith(tab: tab, clearError: true);
    await refresh();
  }

  void selectCategoryChip(int? id) {
    state = state.copyWith(categoryId: id, clearCategory: id == null);
  }

  /// Tap same chip again → clear filter (only for matched chips with id).
  void toggleCategoryFilter(int? chipCategoryId) {
    if (chipCategoryId == null) {
      state = state.copyWith(clearCategory: true);
      refresh();
      return;
    }
    if (state.categoryId == chipCategoryId) {
      state = state.copyWith(clearCategory: true);
    } else {
      state = state.copyWith(categoryId: chipCategoryId);
    }
    refresh();
  }

  void setSort(String sort) {
    state = state.copyWith(sort: sort);
    refresh();
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await ensureCategories();
      if (state.tab == ProfileListingsTab.pendingPayment) {
        final promos = await _promotionsApi.fetchPromotions(
          status: 'pending_payment',
        );
        final previews = <int, ListingPreviewCard?>{};
        for (final p in promos) {
          if (p.listingId <= 0) continue;
          try {
            final raw = await _repo.preview(p.listingId);
            previews[p.listingId] = ListingPreviewCard.fromPreviewJson(
              raw,
              p.listingId,
            );
          } catch (_) {
            previews[p.listingId] = null;
          }
        }
        state = state.copyWith(
          isLoading: false,
          items: const [],
          pendingPromotions: promos,
          pendingPreviews: previews,
        );
        return;
      }
      final status = state.tab.listingsApiStatus!;
      final items = await _repo.myListings(
        status: status,
        categoryId: state.categoryId,
        sort: state.sort,
        page: 1,
        pageSize: 40,
      );
      state = state.copyWith(
        isLoading: false,
        items: items,
        pendingPromotions: const [],
        pendingPreviews: const {},
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  /// Backwards-compatible: load active listings only (used after promote etc.).
  Future<void> load() async {
    state = state.copyWith(tab: ProfileListingsTab.active);
    await refresh();
  }
}
