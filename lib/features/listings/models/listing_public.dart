class ListingImage {
  const ListingImage({
    required this.url,
    required this.sortOrder,
  });

  final String url;
  final int sortOrder;

  factory ListingImage.fromJson(Map<String, dynamic> json) {
    return ListingImage(
      url: json['url'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
    );
  }
}

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
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String city;
  final DateTime? createdAt;
  final List<ListingImage> images;
  final bool isFavorite;

  String get primaryImage => images.isEmpty ? '' : images.first.url;

  factory ListingPublic.fromJson(Map<String, dynamic> json) {
    final imageJson = (json['images'] as List<dynamic>? ?? []);
    return ListingPublic(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'USD',
      city: json['city'] as String? ?? '',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      images: imageJson
          .map((e) => ListingImage.fromJson(e as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  ListingPublic copyWith({bool? isFavorite}) {
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
    );
  }
}
