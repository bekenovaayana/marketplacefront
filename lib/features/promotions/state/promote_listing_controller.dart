import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_repository.dart';
import 'package:marketplace_frontend/features/promotions/data/promotions_api.dart';

class PromoteListingState {
  const PromoteListingState({
    this.isLoading = false,
    this.isPaying = false,
    this.activeListings = const [],
    this.options = const [],
    this.selectedListingId,
    this.selectedDays,
    this.checkout,
    this.error,
  });

  final bool isLoading;
  final bool isPaying;
  final List<ListingMine> activeListings;
  final List<PromotionOptionDto> options;
  final int? selectedListingId;
  final int? selectedDays;
  final PromotionsCheckoutResponse? checkout;
  final Object? error;

  PromoteListingState copyWith({
    bool? isLoading,
    bool? isPaying,
    List<ListingMine>? activeListings,
    List<PromotionOptionDto>? options,
    int? selectedListingId,
    int? selectedDays,
    PromotionsCheckoutResponse? checkout,
    Object? error,
    bool clearError = false,
    bool clearCheckout = false,
  }) {
    return PromoteListingState(
      isLoading: isLoading ?? this.isLoading,
      isPaying: isPaying ?? this.isPaying,
      activeListings: activeListings ?? this.activeListings,
      options: options ?? this.options,
      selectedListingId: selectedListingId ?? this.selectedListingId,
      selectedDays: selectedDays ?? this.selectedDays,
      checkout: clearCheckout ? null : (checkout ?? this.checkout),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final promoteListingProvider =
    StateNotifierProvider<PromoteListingController, PromoteListingState>((ref) {
      return PromoteListingController(
        ref.watch(postingRepositoryProvider),
        ref.watch(promotionsApiProvider),
      );
    });

class PromoteListingController extends StateNotifier<PromoteListingState> {
  PromoteListingController(this._postingRepo, this._promotionsApi)
    : super(const PromoteListingState());

  final PostingRepository _postingRepo;
  final PromotionsApi _promotionsApi;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearCheckout: true,
    );
    try {
      final results = await Future.wait([
        _postingRepo.myListings(status: 'active', page: 1, pageSize: 20),
        _promotionsApi.getOptions(),
      ]);
      final listings = results[0] as List<ListingMine>;
      final options = results[1] as List<PromotionOptionDto>;
      final nextListingId =
          state.selectedListingId ??
          (listings.isEmpty ? null : listings.first.id);
      final nextDays = state.selectedDays ?? _defaultDays(options);

      state = state.copyWith(
        isLoading: false,
        activeListings: listings,
        options: options,
        selectedListingId: nextListingId,
        selectedDays: nextDays,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  int? _defaultDays(List<PromotionOptionDto> options) {
    if (options.isEmpty) return null;
    final days = options.map((e) => e.days).toList()..sort();
    return days.first;
  }

  void selectListing(int? id) {
    state = state.copyWith(
      selectedListingId: id,
      clearError: true,
      clearCheckout: true,
    );
  }

  void selectDays(int? days) {
    state = state.copyWith(
      selectedDays: days,
      clearError: true,
      clearCheckout: true,
    );
  }

  PromotionOptionDto? get selectedOption {
    final days = state.selectedDays;
    if (days == null) return null;
    for (final o in state.options) {
      if (o.days == days) return o;
    }
    return null;
  }

  Future<void> pay() async {
    final listingId = state.selectedListingId;
    final days = state.selectedDays;
    if (listingId == null || days == null) {
      state = state.copyWith(
        error: const ApiException('Select listing and duration'),
      );
      return;
    }
    state = state.copyWith(
      isPaying: true,
      clearError: true,
      clearCheckout: true,
    );
    try {
      final checkout = await _promotionsApi.checkout(
        listingId: listingId,
        days: days,
      );
      state = state.copyWith(isPaying: false, checkout: checkout);
    } catch (e) {
      state = state.copyWith(isPaying: false, error: e);
    }
  }
}
