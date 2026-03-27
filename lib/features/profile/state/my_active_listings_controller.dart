import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_repository.dart';

class MyActiveListingsState {
  const MyActiveListingsState({
    this.isLoading = false,
    this.items = const [],
    this.error,
  });

  final bool isLoading;
  final List<ListingMine> items;
  final Object? error;

  MyActiveListingsState copyWith({
    bool? isLoading,
    List<ListingMine>? items,
    Object? error,
    bool clearError = false,
  }) {
    return MyActiveListingsState(
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final myActiveListingsProvider =
    StateNotifierProvider<MyActiveListingsController, MyActiveListingsState>((
      ref,
    ) {
      return MyActiveListingsController(ref.watch(postingRepositoryProvider));
    });

class MyActiveListingsController extends StateNotifier<MyActiveListingsState> {
  MyActiveListingsController(this._repo) : super(const MyActiveListingsState());

  final PostingRepository _repo;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _repo.myListings(
        status: 'active',
        page: 1,
        pageSize: 20,
      );
      state = state.copyWith(isLoading: false, items: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }
}
