import 'package:marketplace_frontend/core/constants/listing_currency.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';

class PostingImage {
  const PostingImage({
    required this.url,
    required this.sortOrder,
  });

  final String url;
  final int sortOrder;

  Map<String, dynamic> toJson() => {
        'url': url,
        'sort_order': sortOrder,
      };
}

class PostingDraftPayload {
  const PostingDraftPayload({
    this.categoryId,
    this.title,
    this.description,
    this.price,
    this.currency = ListingCurrency.backendDefault,
    this.city,
    this.contactPhone,
    this.latitude,
    this.longitude,
    this.images = const [],
  });

  final num? categoryId;
  final String? title;
  final String? description;
  final num? price;
  final String currency;
  final String? city;
  final String? contactPhone;
  final double? latitude;
  final double? longitude;
  final List<PostingImage> images;

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'city': city,
      'contact_phone': contactPhone,
      'latitude': latitude,
      'longitude': longitude,
      'images': images.map((e) => e.toJson()).toList(),
    }..removeWhere((key, value) => value == null);
  }

  PostingDraftPayload copyWith({
    num? categoryId,
    String? title,
    String? description,
    num? price,
    String? currency,
    String? city,
    String? contactPhone,
    double? latitude,
    double? longitude,
    List<PostingImage>? images,
  }) {
    return PostingDraftPayload(
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      city: city ?? this.city,
      contactPhone: contactPhone ?? this.contactPhone,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      images: images ?? this.images,
    );
  }
}

class ListingMine {
  const ListingMine({
    required this.id,
    required this.title,
    required this.status,
    required this.price,
    required this.currency,
    required this.city,
    required this.images,
    required this.isBoosted,
    required this.viewsCount,
    required this.savesCount,
  });

  final int id;
  final String title;
  final String status;
  final double price;
  final String currency;
  final String city;
  final List<PostingImage> images;
  final bool isBoosted;
  final int viewsCount;
  final int savesCount;

  String get cover => images.isEmpty ? '' : images.first.url;

  factory ListingMine.fromJson(Map<String, dynamic> json) {
    List<PostingImage> imageList;
    final urls = json['image_urls'];
    if (urls is List<dynamic> && urls.isNotEmpty) {
      imageList = urls
          .asMap()
          .entries
          .map((e) {
            final v = e.value;
            final s = v is String ? v : JsonRead.string(v);
            return PostingImage(url: s, sortOrder: e.key);
          })
          .toList();
    } else {
      final raw = json['images'];
      if (raw is List<dynamic>) {
        imageList = raw
            .map((e) => JsonRead.map(e))
            .whereType<Map<String, dynamic>>()
            .map(
              (m) => PostingImage(
                url: JsonRead.string(m['url']),
                sortOrder: JsonRead.intVal(m['sort_order']),
              ),
            )
            .toList()
          ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      } else {
        imageList = [];
      }
    }
    return ListingMine(
      id: JsonRead.intVal(json['id']),
      title: JsonRead.string(json['title']),
      status: JsonRead.string(json['status']),
      price: JsonRead.price(json['price']),
      currency: JsonRead.string(json['currency'], ListingCurrency.backendDefault),
      city: JsonRead.string(json['city']),
      images: imageList,
      isBoosted: JsonRead.boolVal(json['is_boosted']),
      viewsCount: JsonRead.intVal(
        json['view_count'] ?? json['views_count'] ?? json['views'],
      ),
      savesCount: JsonRead.intVal(
        json['favorites_count'] ??
            json['favourites_count'] ??
            json['saved_count'],
      ),
    );
  }
}

/// Minimal listing card data from GET /listings/{id}/preview.
class ListingPreviewCard {
  const ListingPreviewCard({
    required this.listingId,
    required this.title,
    required this.price,
    required this.currency,
    required this.city,
    required this.imageUrl,
    required this.isBoosted,
  });

  final int listingId;
  final String title;
  final double price;
  final String currency;
  final String city;
  final String imageUrl;
  final bool isBoosted;

  factory ListingPreviewCard.fromPreviewJson(
    Map<String, dynamic> json,
    int fallbackListingId,
  ) {
    final nested = JsonRead.map(json['listing']);
    final root = nested ?? json;
    final id = JsonRead.intVal(root['id'], fallbackListingId);
    String url = '';
    final imageUrls = root['image_urls'];
    if (imageUrls is List<dynamic> && imageUrls.isNotEmpty) {
      final first = imageUrls.first;
      url = first is String ? first : JsonRead.string(first);
    }
    if (url.isEmpty) {
      final images = root['images'];
      if (images is List<dynamic> && images.isNotEmpty) {
        final m = JsonRead.map(images.first);
        if (m != null) url = JsonRead.string(m['url']);
      }
    }
    if (url.isEmpty) {
      url = JsonRead.string(root['primary_image']);
    }
    return ListingPreviewCard(
      listingId: id,
      title: JsonRead.string(root['title']),
      price: JsonRead.price(root['price']),
      currency: JsonRead.string(root['currency'], ListingCurrency.backendDefault),
      city: JsonRead.string(root['city']),
      imageUrl: url,
      isBoosted: JsonRead.boolVal(root['is_boosted']),
    );
  }
}

class DraftIncompleteException implements Exception {
  const DraftIncompleteException({
    required this.message,
    required this.missingFields,
  });

  final String message;
  final List<String> missingFields;
}
