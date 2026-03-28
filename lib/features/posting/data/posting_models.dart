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
    this.currency = 'USD',
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
    final imageList = (json['images'] as List<dynamic>? ?? [])
        .map((e) => PostingImage(
              url: (e as Map<String, dynamic>)['url'] as String? ?? '',
              sortOrder: ((e)['sort_order'] as num?)?.toInt() ?? 0,
            ))
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return ListingMine(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      status: json['status'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      city: json['city'] as String? ?? '',
      images: imageList,
      isBoosted: json['is_boosted'] as bool? ?? false,
      // Backend field is view_count (Listing model); also accept views_count /
      // views aliases from older API versions.
      viewsCount: (json['view_count'] as num?)?.toInt() ??
          (json['views_count'] as num?)?.toInt() ??
          (json['views'] as num?)?.toInt() ??
          0,
      savesCount: (json['favorites_count'] as num?)?.toInt() ??
          (json['favourites_count'] as num?)?.toInt() ??
          (json['saved_count'] as num?)?.toInt() ??
          0,
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
    final root = json['listing'] is Map<String, dynamic>
        ? json['listing'] as Map<String, dynamic>
        : json;
    final id = (root['id'] as num?)?.toInt() ?? fallbackListingId;
    final images = root['images'] as List<dynamic>? ?? [];
    String url = '';
    if (images.isNotEmpty && images.first is Map<String, dynamic>) {
      url = (images.first as Map<String, dynamic>)['url'] as String? ?? '';
    }
    final primary = root['primary_image'] as String?;
    if (url.isEmpty && primary != null) {
      url = primary;
    }
    return ListingPreviewCard(
      listingId: id,
      title: root['title'] as String? ?? '',
      price: (root['price'] as num?)?.toDouble() ?? 0,
      currency: root['currency'] as String? ?? 'USD',
      city: root['city'] as String? ?? '',
      imageUrl: url,
      isBoosted: root['is_boosted'] as bool? ?? false,
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
