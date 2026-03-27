import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/home/data/home_repository.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/home/state/home_controller.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

void main() {
  test('query with text enforces relevance sort', () {
    const query = ListingQuery(q: 'iphone', sort: 'newest');
    final map = query.toMap();
    expect(map['sort'], 'relevance');
  });

  test('filter serialization includes expected params', () {
    const query = ListingQuery(
      q: null,
      categoryId: 3,
      city: 'Bishkek',
      minPrice: 1000,
      maxPrice: 5000,
      sort: 'price_desc',
      page: 2,
      pageSize: 30,
      includeFacets: true,
    );
    final map = query.toMap();
    expect(map['category_id'], 3);
    expect(map['city'], 'Bishkek');
    expect(map['min_price'], 1000);
    expect(map['max_price'], 5000);
    expect(map['sort'], 'price_desc');
    expect(map['include_facets'], true);
  });

  test('facets parsing handles null and missing keys', () {
    final empty = ListingsFacets.fromJson(null);
    expect(empty.cities, isEmpty);
    expect(empty.categories, isEmpty);

    final partial = ListingsFacets.fromJson({'cities': null});
    expect(partial.cities, isEmpty);
    expect(partial.categories, isEmpty);
  });

  test('pagination append behavior keeps previous items', () async {
    final repo = _FakeHomeRepository();
    final controller = HomeController(repo);
    await controller.applyFilters(const ListingQuery(q: 'a'));
    expect(controller.state.feed.length, 2);
    await controller.loadMore();
    expect(controller.state.feed.length, 3);
    expect(controller.state.page, 2);
  });
}

class _FakeHomeRepository extends HomeRepository {
  _FakeHomeRepository() : super(Dio());

  @override
  Future<ListingPageResult> searchListings(ListingQuery query) async {
    final items = query.page == 1
        ? [_item(1), _item(2)]
        : [_item(3)];
    return ListingPageResult(
      items: items,
      page: query.page,
      totalPages: 2,
      totalItems: 3,
      pageSize: query.pageSize,
      facets: const ListingsFacets(
        priceMin: null,
        priceMax: null,
        cities: [],
        categories: [],
      ),
    );
  }

  static ListingPublic _item(int id) {
    return ListingPublic(
      id: id,
      title: 'Item$id',
      description: '',
      price: 1,
      currency: 'USD',
      city: 'B',
      createdAt: null,
      images: const [],
      isFavorite: false,
    );
  }
}
