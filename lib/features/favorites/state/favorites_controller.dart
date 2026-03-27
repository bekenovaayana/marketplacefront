import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/favorites/data/favorites_repository.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class FavoritesState {
  const FavoritesState({
    this.items = const [],
    this.isLoading = false,
    this.isMutating = false,
    this.error,
  });

  final List<ListingPublic> items;
  final bool isLoading;
  final bool isMutating;
  final String? error;

  FavoritesState copyWith({
    List<ListingPublic>? items,
    bool? isLoading,
    bool? isMutating,
    String? error,
    bool clearError = false,
  }) {
    return FavoritesState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isMutating: isMutating ?? this.isMutating,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final favoritesControllerProvider =
    StateNotifierProvider<FavoritesController, FavoritesState>((ref) {
  return FavoritesController(ref.watch(favoritesRepositoryProvider));
});

class FavoritesController extends StateNotifier<FavoritesState> {
  FavoritesController(this._repository)
      : super(const FavoritesState(isLoading: true)) {
    load();
  }

  final FavoritesRepository _repository;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repository.list();
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> remove(int listingId) async {
    final previous = state.items;
    state = state.copyWith(
      isMutating: true,
      items: state.items.where((item) => item.id != listingId).toList(),
    );
    try {
      await _repository.remove(listingId);
      state = state.copyWith(isMutating: false);
    } catch (e) {
      state = state.copyWith(
        isMutating: false,
        items: previous,
        error: e.toString(),
      );
    }
  }

  Future<void> add(int listingId) async {
    try {
      await _repository.add(listingId);
      await load();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}
