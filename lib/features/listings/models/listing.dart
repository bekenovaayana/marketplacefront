import 'package:marketplace_frontend/core/json/json_read.dart';

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
      id: JsonRead.intVal(json['id']),
      title: JsonRead.string(json['title']),
      description: JsonRead.string(json['description']),
      price: JsonRead.price(json['price']),
      city: JsonRead.string(json['city']),
      ownerId: JsonRead.intVal(json['owner_id']),
      isFavorite: JsonRead.boolVal(json['is_favorite']),
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
