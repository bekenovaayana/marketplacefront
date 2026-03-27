import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

final favoritesRepositoryProvider = Provider<FavoritesRepository>((ref) {
  return FavoritesRepository(ref.watch(dioProvider));
});

class FavoritesRepository {
  FavoritesRepository(this._dio);

  final Dio _dio;

  Future<void> add(int listingId) async {
    await _dio.post('/favorites/$listingId');
  }

  Future<void> remove(int listingId) async {
    await _dio.delete('/favorites/$listingId');
  }

  Future<List<ListingPublic>> list({int page = 1, int pageSize = 20}) async {
    final response = await _dio.get(
      '/favorites',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
