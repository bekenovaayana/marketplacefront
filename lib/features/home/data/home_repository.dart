import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
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
    this.latitude,
    this.longitude,
  });

  final String? q;
  final int? categoryId;
  final String? city;
  final double? minPrice;
  final double? maxPrice;
  /// API: `newest` | `price_asc` | `price_desc` | `distance` (with lat/lng).
  final String sort;
  final int page;
  final int pageSize;
  final bool includeFacets;
  /// Required with [sort] == `distance` when API expects coordinates.
  final double? latitude;
  final double? longitude;

  bool get hasQuery => (q?.trim().isNotEmpty ?? false);
  String get effectiveSort => hasQuery ? 'relevance' : sort;

  /// Backend accepts both [category_id] and [categoryId]; omit when null or invalid
  /// so the request is not polluted (empty = no category filter).
  int? get _categoryFilter =>
      categoryId != null && categoryId! > 0 ? categoryId : null;

  Map<String, dynamic> toMap() {
    final cat = _categoryFilter;
    return {
      'q': q,
      ...?(cat == null ? null : {'category_id': cat, 'categoryId': cat}),
      'city': city,
      'min_price': minPrice,
      'max_price': maxPrice,
      'sort': effectiveSort,
      'page': page,
      'page_size': pageSize,
      'include_facets': includeFacets ? true : null,
      if (sort == 'distance' && latitude != null && longitude != null) ...{
        'lat': latitude,
        'lng': longitude,
      },
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
    double? latitude,
    double? longitude,
    bool clearCategory = false,
    bool clearCity = false,
    bool clearPrice = false,
    bool clearQuery = false,
    bool clearGeo = false,
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
      latitude: clearGeo ? null : (latitude ?? this.latitude),
      longitude: clearGeo ? null : (longitude ?? this.longitude),
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
      latitude?.toString() ?? '',
      longitude?.toString() ?? '',
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

  /// Первая загрузка главного экрана: **GET /home** (не сырой GET /listings).
  /// Блоки `recommended` / `latest` приходят в ответе; лента на вкладке «Главная»
  /// строится из них до тех пор, пока пользователь не включит поиск/фильтры
  /// ([searchListings] → GET /listings).
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
      queryParameters: query.toMap(),
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return ListingPageResult(
        items: [],
        page: query.page,
        totalPages: query.page,
        totalItems: 0,
        pageSize: query.pageSize,
      );
    }
    final data = raw;
    final items = JsonRead.listOfMap(data['items'], ListingPublic.fromJson);
    final src = JsonRead.paginationSource(data);
    return ListingPageResult(
      items: items,
      page: JsonRead.intVal(src['page'], query.page),
      totalPages: JsonRead.intVal(src['total_pages'], query.page),
      totalItems: JsonRead.intVal(src['total_items'], items.length),
      pageSize: JsonRead.intVal(src['page_size'], query.pageSize),
      facets: data.containsKey('facets')
          ? ListingsFacets.fromJson(JsonRead.map(data['facets']))
          : null,
    );
  }

  Future<ListingPageResult> getListingsWithFacets(ListingQuery query) {
    return searchListings(query.copyWith(includeFacets: true));
  }
}
