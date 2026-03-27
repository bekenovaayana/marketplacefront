import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing.dart';

final favoritesApiProvider = Provider<FavoritesApi>((ref) {
  return FavoritesApi(ref.watch(dioProvider));
});

class FavoritesApi {
  FavoritesApi(this._dio);

  final Dio _dio;

  Future<void> addFavorite(int listingId) {
    return _dio.post('/favorites', data: {'listing_id': listingId});
  }

  Future<void> removeFavorite(int listingId) {
    return _dio.delete('/favorites/$listingId');
  }

  Future<List<Listing>> getFavorites({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final json = response.data as Map<String, dynamic>;
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
    return items;
  }
}
