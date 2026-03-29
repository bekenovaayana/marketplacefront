import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_repository.dart';
import 'package:marketplace_frontend/features/promotions/data/promotions_api.dart';

class PromoteListingState {
  const PromoteListingState({
    this.isLoading = false,
    this.isPurchasing = false,
    this.activeListings = const [],
    this.selectedListingId,
    this.selectedType = 'boost',
    this.selectedDays = 7,
    this.lastPurchase,
    this.error,
  });

  final bool isLoading;
  final bool isPurchasing;
  final List<ListingMine> activeListings;
  final int? selectedListingId;
  /// `boost` | `top` | `vip`
  final String selectedType;
  final int selectedDays;
  final WalletPromotionPurchaseResult? lastPurchase;
  final Object? error;

  PromoteListingState copyWith({
    bool? isLoading,
    bool? isPurchasing,
    List<ListingMine>? activeListings,
    int? selectedListingId,
    String? selectedType,
    int? selectedDays,
    WalletPromotionPurchaseResult? lastPurchase,
    Object? error,
    bool clearError = false,
    bool clearPurchase = false,
  }) {
    return PromoteListingState(
      isLoading: isLoading ?? this.isLoading,
      isPurchasing: isPurchasing ?? this.isPurchasing,
      activeListings: activeListings ?? this.activeListings,
      selectedListingId: selectedListingId ?? this.selectedListingId,
      selectedType: selectedType ?? this.selectedType,
      selectedDays: selectedDays ?? this.selectedDays,
      lastPurchase: clearPurchase ? null : (lastPurchase ?? this.lastPurchase),
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
      clearPurchase: true,
    );
    try {
      final listings = await _postingRepo.myListings(
        status: 'active',
        page: 1,
        pageSize: 20,
      );
      final nextListingId =
          state.selectedListingId ??
          (listings.isEmpty ? null : listings.first.id);
      state = state.copyWith(
        isLoading: false,
        activeListings: listings,
        selectedListingId: nextListingId,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e);
    }
  }

  void selectListing(int? id) {
    state = state.copyWith(
      selectedListingId: id,
      clearError: true,
      clearPurchase: true,
    );
  }

  void selectType(String type) {
    state = state.copyWith(
      selectedType: type,
      clearError: true,
      clearPurchase: true,
    );
  }

  void selectDays(int days) {
    final clamped = days.clamp(1, 365);
    state = state.copyWith(
      selectedDays: clamped,
      clearError: true,
      clearPurchase: true,
    );
  }

  double get estimatedTotalKgs =>
      PromotionWalletPricing.estimateTotal(state.selectedType, state.selectedDays);

  /// **POST /promotions** (wallet). **400** = insufficient funds (message from API).
  Future<WalletPromotionPurchaseResult?> purchaseFromWallet() async {
    final listingId = state.selectedListingId;
    if (listingId == null) {
      state = state.copyWith(
        error: const ApiException('Выберите объявление'),
      );
      return null;
    }
    state = state.copyWith(
      isPurchasing: true,
      clearError: true,
      clearPurchase: true,
    );
    try {
      final result = await _promotionsApi.purchasePromotionFromWallet(
        listingId: listingId,
        type: state.selectedType,
        days: state.selectedDays,
      );
      state = state.copyWith(
        isPurchasing: false,
        lastPurchase: result,
      );
      return result;
    } catch (e) {
      state = state.copyWith(isPurchasing: false, error: e);
      rethrow;
    }
  }
}
