import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing.dart';
import 'package:marketplace_frontend/features/listings/models/listing_page.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

final listingsApiProvider = Provider<ListingsApi>((ref) {
  return ListingsApi(ref.watch(dioProvider));
});

class ListingsApi {
  ListingsApi(this._dio);

  final Dio _dio;

  Future<ListingPage> fetchListings({required int page, int pageSize = 10}) async {
    final response = await _dio.get(
      '/listings',
      queryParameters: {'page': page, 'page_size': pageSize},
    );
    final json = response.data as Map<String, dynamic>;
    final items = ((json['items'] ?? json['results']) as List<dynamic>? ?? [])
        .map((e) => Listing.fromJson(e as Map<String, dynamic>))
        .toList();
    return ListingPage(
      items: items,
      page: (json['page'] as num?)?.toInt() ?? page,
      totalPages: (json['total_pages'] as num?)?.toInt() ?? page,
    );
  }

  Future<Listing> fetchListingDetail(int id) async {
    final response = await _dio.get('/listings/$id');
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }

  /// **GET /listings** filtered by seller and active status (public seller page).
  Future<List<ListingPublic>> fetchActiveListingsForUser({
    required int userId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      '/listings',
      queryParameters: {
        'user_id': userId,
        'status': 'active',
        'page': page,
        'page_size': pageSize,
      },
    );
    final raw = response.data;
    final items = JsonRead.paginatedListItems(raw);
    return JsonRead.listOfMap(items, ListingPublic.fromJson);
  }

  Future<Listing> createListing({
    required String title,
    required String description,
    required double price,
    required String city,
  }) async {
    final response = await _dio.post(
      '/listings',
      data: {
        'title': title,
        'description': description,
        'price': price,
        'city': city,
      },
    );
    return Listing.fromJson(response.data as Map<String, dynamic>);
  }
}
