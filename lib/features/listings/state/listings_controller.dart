import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/favorites/data/favorites_api.dart';
import 'package:marketplace_frontend/features/listings/data/listings_api.dart';
import 'package:marketplace_frontend/features/listings/models/listing.dart';
import 'package:marketplace_frontend/features/listings/state/listings_state.dart';

final listingsControllerProvider =
    StateNotifierProvider<ListingsController, ListingsState>((ref) {
  return ListingsController(
    ref.watch(listingsApiProvider),
    ref.watch(favoritesApiProvider),
  );
});

class ListingsController extends StateNotifier<ListingsState> {
  ListingsController(this._api, this._favoritesApi) : super(const ListingsState());

  final ListingsApi _api;
  final FavoritesApi _favoritesApi;

  Future<void> loadInitial() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final page = await _api.fetchListings(page: 1);
      state = state.copyWith(
        isLoading: false,
        items: page.items,
        page: page.page,
        totalPages: page.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) {
      return;
    }
    state = state.copyWith(isLoadingMore: true, clearError: true);
    final nextPage = state.page + 1;
    try {
      final page = await _api.fetchListings(page: nextPage);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...page.items],
        page: page.page,
        totalPages: page.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<Listing?> getDetail(int id) async {
    try {
      return await _api.fetchListingDetail(id);
    } catch (_) {
      return null;
    }
  }

  Future<void> createListing({
    required String title,
    required String description,
    required double price,
    required String city,
  }) async {
    await _api.createListing(
      title: title,
      description: description,
      price: price,
      city: city,
    );
    await loadInitial();
  }

  Future<void> toggleFavorite(Listing listing) async {
    if (listing.isFavorite) {
      await _favoritesApi.removeFavorite(listing.id);
    } else {
      await _favoritesApi.addFavorite(listing.id);
    }
    final updated = state.items
        .map((e) => e.id == listing.id ? e.copyWith(isFavorite: !e.isFavorite) : e)
        .toList();
    state = state.copyWith(items: updated);
  }
}
