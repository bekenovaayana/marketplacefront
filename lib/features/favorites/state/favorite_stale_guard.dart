import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/listings/models/listing.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

/// IDs the user has favorited locally while a stale GET may still return
/// `is_favorite: false`. Merged into list/detail payloads until the server
/// catches up or the user unfavorites.
final favoriteStaleGuardProvider =
    StateNotifierProvider<FavoriteStaleGuard, Set<int>>((ref) {
  return FavoriteStaleGuard();
});

class FavoriteStaleGuard extends StateNotifier<Set<int>> {
  FavoriteStaleGuard() : super({});

  void clear() => state = <int>{};

  void markExpectFavoriteTrue(int listingId) {
    state = <int>{...state, listingId};
  }

  void clearExpectFavoriteTrue(int listingId) {
    if (!state.contains(listingId)) return;
    state = <int>{...state}..remove(listingId);
  }

  ListingPublic mergeListingPublic(ListingPublic item) {
    if (!state.contains(item.id)) return item;
    if (item.isFavorite) return item;
    return item.copyWith(isFavorite: true);
  }

  Listing mergeListing(Listing item) {
    if (!state.contains(item.id)) return item;
    if (item.isFavorite) return item;
    return item.copyWith(isFavorite: true);
  }

  List<ListingPublic> mergeListingPublicList(List<ListingPublic> items) {
    return items.map(mergeListingPublic).toList();
  }

  List<Listing> mergeListingList(List<Listing> items) {
    return items.map(mergeListing).toList();
  }
}
