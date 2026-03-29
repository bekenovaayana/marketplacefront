import 'package:json_annotation/json_annotation.dart';
import 'package:marketplace_frontend/core/constants/listing_currency.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';

/// Listing image object from API `images[]` (`url`, `sort_order`).
class ListingImage {
  const ListingImage({
    required this.url,
    required this.sortOrder,
  });

  @JsonKey(name: 'url')
  final String url;
  @JsonKey(name: 'sort_order')
  final int sortOrder;

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      url: JsonRead.string(json['url']),
      sortOrder: JsonRead.intVal(json['sort_order']),
    );
  }
}

/// Feed / card listing. Wire names are snake_case on the server.
class ListingPublic {
  const ListingPublic({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.city,
    required this.createdAt,
    required this.images,
    required this.isFavorite,
    this.isOwner,
    this.userId,
    this.categoryId,
    this.favoritesCount = 0,
    this.viewsCount = 0,
    this.status,
    this.isPromoted = false,
  });

  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'title')
  final String title;
  @JsonKey(name: 'description')
  final String description;
  @JsonKey(name: 'price')
  final double price;
  @JsonKey(name: 'currency')
  final String currency;
  @JsonKey(name: 'city')
  final String city;
  @JsonKey(name: 'created_at')
  final DateTime? createdAt;
  /// Prefer `image_urls` when present (see [fromJson]); same order as API.
  final List<ListingImage> images;
  @JsonKey(name: 'is_favorite')
  final bool isFavorite;
  @JsonKey(name: 'is_owner')
  final bool? isOwner;
  @JsonKey(name: 'user_id')
  final int? userId;
  @JsonKey(name: 'category_id')
  final int? categoryId;
  @JsonKey(name: 'favorites_count')
  final int favoritesCount;
  @JsonKey(name: 'view_count')
  final int viewsCount;
  /// e.g. `active` — when absent, treat as active for public cards.
  final String? status;
  @JsonKey(name: 'is_promoted')
  final bool isPromoted;

  String get primaryImage => images.isEmpty ? '' : images.first.url;

  bool get isListingActive =>
      status == null || status!.isEmpty || status == 'active';

  factory ListingPublic.fromJson(Map<String, dynamic> json) {
    final List<ListingImage> images;
    final urls = json['image_urls'];
    if (urls is List<dynamic> && urls.isNotEmpty) {
      images = urls
          .asMap()
          .entries
          .map((e) {
            final v = e.value;
            final s = v is String ? v : JsonRead.string(v);
            return ListingImage(url: s, sortOrder: e.key);
          })
          .toList();
    } else {
      final raw = json['images'];
      if (raw is List<dynamic>) {
        images = raw
            .map((e) => JsonRead.map(e))
            .whereType<Map<String, dynamic>>()
            .map(ListingImage.fromJson)
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } else {
        images = [];
      }
    }

    DateTime? createdAt;
    final createdRaw = json['created_at'];
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw);
    }

    return ListingPublic(
      id: JsonRead.intVal(json['id']),
      title: JsonRead.string(json['title']),
      description: JsonRead.string(json['description']),
      price: JsonRead.price(json['price']),
      currency: JsonRead.string(
        json['currency'],
        ListingCurrency.backendDefault,
      ),
      city: JsonRead.string(json['city']),
      createdAt: createdAt,
      images: images,
      isFavorite: JsonRead.boolVal(json['is_favorite']),
      isOwner: json['is_owner'] == null
          ? null
          : JsonRead.boolVal(json['is_owner']),
      userId: JsonRead.intNullable(json['user_id']),
      categoryId: JsonRead.intNullable(json['category_id']),
      favoritesCount: JsonRead.intVal(
        json['favorites_count'] ?? json['favourites_count'],
      ),
      viewsCount: JsonRead.intVal(
        json['view_count'] ?? json['views_count'] ?? json['views'],
      ),
      status: () {
        final s = JsonRead.string(json['status']).trim();
        return s.isEmpty ? null : s;
      }(),
      isPromoted: JsonRead.boolVal(json['is_promoted'] ?? json['isPromoted']),
    );
  }

  ListingPublic copyWith({
    bool? isFavorite,
    bool? isOwner,
    int? userId,
    int? categoryId,
    int? favoritesCount,
    int? viewsCount,
    String? status,
    bool? isPromoted,
  }) {
    return ListingPublic(
      id: id,
      title: title,
      description: description,
      price: price,
      currency: currency,
      city: city,
      createdAt: createdAt,
      images: images,
      isFavorite: isFavorite ?? this.isFavorite,
      isOwner: isOwner ?? this.isOwner,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
      favoritesCount: favoritesCount ?? this.favoritesCount,
      viewsCount: viewsCount ?? this.viewsCount,
      status: status ?? this.status,
      isPromoted: isPromoted ?? this.isPromoted,
    );
  }
}
