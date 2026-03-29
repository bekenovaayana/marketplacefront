import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing.dart';

final favoritesApiProvider = Provider<FavoritesApi>((ref) {
  return FavoritesApi(ref.watch(dioProvider));
});

class FavoritesApi {
  FavoritesApi(this._dio);

  final Dio _dio;

  /// POST /favorites/{listing_id} — success is any **2xx** (200 duplicate or 201 created).
  /// Legacy servers may still return **409** for duplicate; treat as success.
  Future<void> addFavorite(int listingId) async {
    try {
      final response = await _dio.post<void>('/favorites/$listingId');
      final code = response.statusCode;
      if (code != null && code >= 200 && code < 300) return;
    } on DioException catch (e) {
      final c = e.response?.statusCode;
      if (c != null && c >= 200 && c < 300) return;
      if (c == 409) return;
      rethrow;
    }
  }

  /// DELETE /favorites/{listing_id} → 204.
  Future<void> removeFavorite(int listingId) {
    return _dio.delete<void>('/favorites/$listingId');
  }

  Future<List<Listing>> getFavorites({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];
    return JsonRead.listOfMap(raw['items'], Listing.fromJson);
  }
}
