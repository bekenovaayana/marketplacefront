import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.listingsCount,
  });

  final int id;
  final String name;
  final String slug;
  final int listingsCount;

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      listingsCount: (json['listings_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class HomeResponse {
  const HomeResponse({
    required this.categories,
    required this.recommended,
    required this.latest,
  });

  final List<HomeCategory> categories;
  final List<ListingPublic> recommended;
  final List<ListingPublic> latest;

  factory HomeResponse.fromJson(Map<String, dynamic> json) {
    return HomeResponse(
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => HomeCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommended: (json['recommended'] as List<dynamic>? ?? [])
          .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
      latest: (json['latest'] as List<dynamic>? ?? [])
          .map((e) => ListingPublic.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class FacetCity {
  const FacetCity({
    required this.city,
    required this.count,
  });

  final String city;
  final int count;

  factory FacetCity.fromJson(Map<String, dynamic> json) {
    return FacetCity(
      city: json['city'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class FacetCategory {
  const FacetCategory({
    required this.id,
    required this.slug,
    required this.count,
  });

  final int id;
  final String slug;
  final int count;

  factory FacetCategory.fromJson(Map<String, dynamic> json) {
    return FacetCategory(
      id: (json['id'] as num?)?.toInt() ?? 0,
      slug: json['slug'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class ListingsFacets {
  const ListingsFacets({
    required this.priceMin,
    required this.priceMax,
    required this.cities,
    required this.categories,
  });

  final double? priceMin;
  final double? priceMax;
  final List<FacetCity> cities;
  final List<FacetCategory> categories;

  factory ListingsFacets.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ListingsFacets(
        priceMin: null,
        priceMax: null,
        cities: [],
        categories: [],
      );
    }
    return ListingsFacets(
      priceMin: (json['price_min'] as num?)?.toDouble(),
      priceMax: (json['price_max'] as num?)?.toDouble(),
      cities: (json['cities'] as List<dynamic>? ?? [])
          .map((e) => FacetCity.fromJson(e as Map<String, dynamic>))
          .toList(),
      categories: (json['categories'] as List<dynamic>? ?? [])
          .map((e) => FacetCategory.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
