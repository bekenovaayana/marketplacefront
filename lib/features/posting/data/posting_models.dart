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

  final int? categoryId;
  final String? title;
  final String? description;
  final double? price;
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
    int? categoryId,
    String? title,
    String? description,
    double? price,
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
    required this.city,
    required this.images,
  });

  final int id;
  final String title;
  final String status;
  final double price;
  final String city;
  final List<PostingImage> images;

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
      city: json['city'] as String? ?? '',
      images: imageList,
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
