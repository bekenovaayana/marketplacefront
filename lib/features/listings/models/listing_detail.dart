import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class ListingDetail {
  const ListingDetail({
    required this.listing,
    required this.ownerName,
    required this.ownerPhone,
    this.ownerUserId,
  });

  final ListingPublic listing;
  final String ownerName;
  final String ownerPhone;
  /// Owner id from `owner_id` / nested `owner.id` when `user_id` is absent on listing.
  final int? ownerUserId;

  /// Flattens `{ "listing": { ... }, ... }` preview envelopes into one map for parsing.
  static Map<String, dynamic> normalizeListingJson(Map<String, dynamic> json) {
    final nested = json['listing'];
    if (nested is Map<String, dynamic>) {
      final merged = Map<String, dynamic>.from(json);
      merged.remove('listing');
      merged.addAll(nested);
      return merged;
    }
    return json;
  }

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    final root = normalizeListingJson(json);
    final owner = root['owner'];
    return ListingDetail(
      listing: ListingPublic.fromJson(root),
      ownerName: root['owner_name'] as String? ??
          (owner is Map<String, dynamic> ? owner['full_name']?.toString() : null) ??
          'Unknown',
      ownerPhone: root['contact_phone'] as String? ??
          (owner is Map<String, dynamic> ? owner['phone']?.toString() : null) ??
          '',
      ownerUserId: (root['owner_id'] as num?)?.toInt() ??
          (root['user_id'] as num?)?.toInt() ??
          (owner is Map<String, dynamic>
              ? (owner['id'] as num?)?.toInt()
              : null),
    );
  }
}
