import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.watch(dioProvider));
});

class ListingQuery {
  const ListingQuery({
    this.q,
    this.categoryId,
    this.city,
    this.minPrice,
    this.maxPrice,
    this.sort = 'newest',
    this.page = 1,
    this.pageSize = 20,
    this.includeFacets = false,
  });

  final String? q;
  final int? categoryId;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  final String sort;
  final int page;
  final int pageSize;
  final bool includeFacets;

  bool get hasQuery => (q?.trim().isNotEmpty ?? false);
  String get effectiveSort => hasQuery ? 'relevance' : sort;

  Map<String, dynamic> toMap() {
    return {
      'q': q,
      'category_id': categoryId,
      'city': city,
      'min_price': minPrice,
      'max_price': maxPrice,
      'sort': effectiveSort,
      'page': page,
      'page_size': pageSize,
      'include_facets': includeFacets ? true : null,
    }..removeWhere((key, value) => value == null || value == '');
  }

  ListingQuery copyWith({
    String? q,
    int? categoryId,
    String? city,
    double? minPrice,
    double? maxPrice,
    String? sort,
    int? page,
    int? pageSize,
    bool? includeFacets,
    bool clearCategory = false,
    bool clearCity = false,
    bool clearPrice = false,
    bool clearQuery = false,
  }) {
    return ListingQuery(
      q: clearQuery ? null : (q ?? this.q),
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      city: clearCity ? null : (city ?? this.city),
      minPrice: clearPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearPrice ? null : (maxPrice ?? this.maxPrice),
      sort: sort ?? this.sort,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      includeFacets: includeFacets ?? this.includeFacets,
    );
  }

  String get cacheKey {
    return [
      q ?? '',
      categoryId?.toString() ?? '',
      city ?? '',
      minPrice?.toString() ?? '',
      maxPrice?.toString() ?? '',
      sort,
      page.toString(),
      pageSize.toString(),
      includeFacets.toString(),
    ].join('|');
  }
}

class ListingPageResult {
  const ListingPageResult({
    required this.items,
    required this.page,
    required this.totalPages,
    required this.totalItems,
    required this.pageSize,
    this.facets,
  });

  final List<ListingPublic> items;
  final int page;
  final int totalPages;
  final int totalItems;
  final int pageSize;
  final ListingsFacets? facets;
}

class HomeRepository {
  HomeRepository(this._dio);

  final Dio _dio;

  Future<HomeResponse> getHome({
    int categoriesLimit = 20,
    int itemsLimit = 20,
    String? city,
    int? categoryId,
  }) async {
    final response = await _dio.get(
      '/home',
      options: Options(extra: {'publicEndpoint': true}),
      queryParameters: {
        'categories_limit': categoriesLimit,
        'items_limit': itemsLimit,
        'city': city,
        'category_id': categoryId,
      },
    );
    return HomeResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<HomeCategory>> getCategories() async {
    final response = await _dio.get(
      '/categories',
      options: Options(extra: {'publicEndpoint': true}),
      queryParameters: {'limit': 500},
    );
    final data = response.data;
    if (data is List) {
      return data
          .map((e) => HomeCategory.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items
        .map((e) => HomeCategory.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<ListingPageResult> searchListings(ListingQuery query) async {
    final response = await _dio.get(
      '/listings',
      options: Options(extra: {'publicEndpoint': true}),
      queryParameters: query.toMap(),
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
        .toList();
    return ListingPageResult(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? query.page,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? query.page,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
      pageSize: (data['page_size'] as num?)?.toInt() ?? query.pageSize,
      facets: data.containsKey('facets')
          ? ListingsFacets.fromJson(data['facets'] as Map<String, dynamic>?)
          : null,
    );
  }

  Future<ListingPageResult> getListingsWithFacets(ListingQuery query) {
    return searchListings(query.copyWith(includeFacets: true));
  }
}
