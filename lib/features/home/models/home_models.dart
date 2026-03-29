import 'package:json_annotation/json_annotation.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class HomeCategory {
  const HomeCategory({
    required this.id,
    required this.name,
    required this.slug,
    required this.listingsCount,
  });

  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'name')
  final String name;
  @JsonKey(name: 'slug')
  final String slug;
  @JsonKey(name: 'listings_count')
  final int listingsCount;

  factory HomeCategory.fromJson(Map<String, dynamic> json) {
    return HomeCategory(
      id: JsonRead.intVal(json['id']),
      name: JsonRead.string(json['name']),
      slug: JsonRead.string(json['slug']),
      listingsCount: JsonRead.intVal(json['listings_count']),
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
      categories: JsonRead.listOfMap(json['categories'], HomeCategory.fromJson),
      recommended: JsonRead.listOfMap(json['recommended'], ListingPublic.fromJson),
      latest: JsonRead.listOfMap(json['latest'], ListingPublic.fromJson),
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
      city: JsonRead.string(json['city']),
      count: JsonRead.intVal(json['count']),
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
      id: JsonRead.intVal(json['id']),
      slug: JsonRead.string(json['slug']),
      count: JsonRead.intVal(json['count']),
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
      priceMin: JsonRead.doubleNullable(json['price_min']),
      priceMax: JsonRead.doubleNullable(json['price_max']),
      cities: JsonRead.listOfMap(json['cities'], FacetCity.fromJson),
      categories:
          JsonRead.listOfMap(json['categories'], FacetCategory.fromJson),
    );
  }
}
