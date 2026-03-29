import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

/// One row from **GET /favorites** (metadata + nested listing).  
/// Use for list UIs with dates / availability — not for the same grid as [GET /favorites/listings].
class FavoriteRecord {
  const FavoriteRecord({
    required this.id,
    required this.userId,
    required this.listingId,
    this.createdAt,
    this.listingIsAvailable = true,
    this.listing,
  });

  /// Favorite row id (not listing id).
  final int id;
  final int userId;
  final int listingId;
  final DateTime? createdAt;
  final bool listingIsAvailable;
  final ListingPublic? listing;

  factory FavoriteRecord.fromJson(Map<String, dynamic> json) {
    DateTime? createdAt;
    final ca = json['created_at'];
    if (ca is String) {
      createdAt = DateTime.tryParse(ca);
    }
    final nested = JsonRead.map(json['listing']);
    return FavoriteRecord(
      id: JsonRead.intVal(json['id']),
      userId: JsonRead.intVal(json['user_id']),
      listingId: JsonRead.intVal(json['listing_id']),
      createdAt: createdAt,
      listingIsAvailable: JsonRead.boolVal(
        json['listing_is_available'] ?? json['listingIsAvailable'],
        true,
      ),
      listing: nested != null ? ListingPublic.fromJson(nested) : null,
    );
  }
}
