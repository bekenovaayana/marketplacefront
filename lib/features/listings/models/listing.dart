class Listing {
  const Listing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.city,
    required this.ownerId,
    this.isFavorite = false,
  });

  final int id;
  final String title;
  final String description;
  final double price;
  final String city;
  final int ownerId;
  final bool isFavorite;

  factory Listing.fromJson(Map<String, dynamic> json) {
    return Listing(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      city: json['city'] as String? ?? '',
      ownerId: (json['owner_id'] as num?)?.toInt() ?? 0,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  Listing copyWith({bool? isFavorite}) {
    return Listing(
      id: id,
      title: title,
      description: description,
      price: price,
      city: city,
      ownerId: ownerId,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }
}
