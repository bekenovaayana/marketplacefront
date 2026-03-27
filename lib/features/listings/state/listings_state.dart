import 'package:marketplace_frontend/features/listings/models/listing.dart';

class ListingsState {
  const ListingsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.page = 1,
    this.totalPages = 1,
    this.error,
  });

  final List<Listing> items;
  final bool isLoading;
  final bool isLoadingMore;
  final int page;
  final int totalPages;
  final String? error;

  bool get hasMore => page < totalPages;

  ListingsState copyWith({
    List<Listing>? items,
    bool? isLoading,
    bool? isLoadingMore,
    int? page,
    int? totalPages,
    String? error,
    bool clearError = false,
  }) {
    return ListingsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      error: clearError ? null : (error ?? this.error),
    );
  }
}
