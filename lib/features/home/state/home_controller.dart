import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/home/data/home_repository.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class HomeState {
  const HomeState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.error,
    this.categories = const [],
    this.recommended = const [],
    this.latest = const [],
    this.feed = const [],
    this.query = const ListingQuery(),
    this.page = 1,
    this.totalPages = 1,
    this.totalItems = 0,
    this.facets = const ListingsFacets(
      priceMin: null,
      priceMax: null,
      cities: [],
      categories: [],
    ),
  });

  final bool isLoading;
  final bool isLoadingMore;
  final String? error;
  final List<HomeCategory> categories;
  final List<ListingPublic> recommended;
  final List<ListingPublic> latest;
  final List<ListingPublic> feed;
  final ListingQuery query;
  final int page;
  final int totalPages;
  final int totalItems;
  final ListingsFacets facets;

  bool get hasMore => page < totalPages;
  bool get inSearchMode =>
      (query.q?.isNotEmpty ?? false) ||
      (query.city?.isNotEmpty ?? false) ||
      query.minPrice != null ||
      query.maxPrice != null ||
      query.sort != 'newest';

  HomeState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    String? error,
    List<HomeCategory>? categories,
    List<ListingPublic>? recommended,
    List<ListingPublic>? latest,
    List<ListingPublic>? feed,
    ListingQuery? query,
    int? page,
    int? totalPages,
    int? totalItems,
    ListingsFacets? facets,
    bool clearError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      error: clearError ? null : (error ?? this.error),
      categories: categories ?? this.categories,
      recommended: recommended ?? this.recommended,
      latest: latest ?? this.latest,
      feed: feed ?? this.feed,
      query: query ?? this.query,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalItems: totalItems ?? this.totalItems,
      facets: facets ?? this.facets,
    );
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref.watch(homeRepositoryProvider));
});

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._repository) : super(const HomeState());

  final HomeRepository _repository;
  Timer? _debounce;
  int _requestNonce = 0;
  final Map<String, ListingPageResult> _cache = {};

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final home = await _repository.getHome(
        city: state.query.city,
        categoryId: state.query.categoryId,
      );
      state = state.copyWith(
        isLoading: false,
        categories: home.categories,
        recommended: home.recommended,
        latest: home.latest,
        feed: home.latest,
        page: 1,
        totalPages: 1,
        totalItems: home.latest.length,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> search({String? query}) async {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 350), () async {
      final q = (query ?? '').trim();
      await _runSearch(
        state.query.copyWith(q: q.isEmpty ? null : q, page: 1),
      );
    });
  }

  Future<void> applyFilters(ListingQuery query) async {
    await _runSearch(query.copyWith(page: 1, includeFacets: false));
    await loadInitial();
  }

  /// Home rail filter: keep Home layout and reload recommended/latest by selected category.
  Future<void> setHomeCategoryFilter(int? categoryId) async {
    state = state.copyWith(
      query: state.query.copyWith(
        categoryId: categoryId,
        clearCategory: categoryId == null,
        clearQuery: true,
        clearCity: true,
        clearPrice: true,
        sort: 'newest',
        page: 1,
      ),
      clearError: true,
    );
    await loadInitial();
  }

  Future<void> loadFacets() async {
    try {
      final result = await _repository.getListingsWithFacets(
        state.query.copyWith(page: 1, pageSize: 20),
      );
      if (result.facets != null) {
        state = state.copyWith(facets: result.facets!);
      }
    } catch (_) {}
  }

  Future<void> _runSearch(ListingQuery query) async {
    final requestId = ++_requestNonce;
    state = state.copyWith(isLoading: true, clearError: true, query: query);
    try {
      final cached = _cache[query.cacheKey];
      final result = cached ?? await _repository.searchListings(query);
      _cache[query.cacheKey] = result;
      if (requestId != _requestNonce) {
        return;
      }
      state = state.copyWith(
        isLoading: false,
        feed: result.items,
        page: result.page,
        totalPages: result.totalPages,
        totalItems: result.totalItems,
        facets: result.facets ?? state.facets,
      );
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        return;
      }
      state = state.copyWith(isLoading: false, error: e.toString());
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextQuery = state.query.copyWith(page: state.page + 1);
      final result = await _repository.searchListings(nextQuery);
      state = state.copyWith(
        isLoadingMore: false,
        query: nextQuery,
        feed: [...state.feed, ...result.items],
        page: result.page,
        totalPages: result.totalPages,
        totalItems: result.totalItems,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  void syncFavorite(int listingId, bool isFavorite) {
    List<ListingPublic> update(List<ListingPublic> input) {
      return input
          .map((item) => item.id == listingId ? item.copyWith(isFavorite: isFavorite) : item)
          .toList();
    }

    state = state.copyWith(
      recommended: update(state.recommended),
      latest: update(state.latest),
      feed: update(state.feed),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _cache.clear();
    super.dispose();
  }
}
