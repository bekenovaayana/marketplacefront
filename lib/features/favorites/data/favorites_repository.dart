import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/favorites/data/favorite_record.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(dioProvider));
});

class FavoritesRepository {
  FavoritesRepository(this._dio);

  final Dio _dio;

  /// POST /favorites/{listing_id} — any **2xx** is success (200 or 201). Legacy **409** = ok.
  Future<void> add(int listingId) async {
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

  /// DELETE /favorites/{listing_id} — **204**, empty body (no JSON).
  Future<void> remove(int listingId) async {
    await _dio.delete<void>('/favorites/$listingId');
  }

  /// Grid / same card as feed: **GET /favorites/listings** → [ListingPublic], `is_favorite` true.
  Future<List<ListingPublic>> listListingsForGrid({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/favorites/listings',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];
    return JsonRead.listOfMap(raw['items'], ListingPublic.fromJson);
  }

  /// Rows with favorite metadata — **GET /favorites** (do not use for the home-style grid).
  Future<List<FavoriteRecord>> listFavoriteRecords({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];
    return JsonRead.listOfMap(raw['items'], FavoriteRecord.fromJson);
  }

  Future<List<ListingPublic>> list({int page = 1, int pageSize = 20}) =>
      listListingsForGrid(page: page, pageSize: pageSize);
}
