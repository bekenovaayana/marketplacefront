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
  final int? ownerUserId;

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    final owner = json['owner'];
    return ListingDetail(
      listing: ListingPublic.fromJson(json),
      ownerName: json['owner_name'] as String? ??
          (owner is Map<String, dynamic> ? owner['full_name']?.toString() : null) ??
          'Unknown',
      ownerPhone: json['contact_phone'] as String? ??
          (owner is Map<String, dynamic> ? owner['phone']?.toString() : null) ??
          '',
      ownerUserId: (json['owner_id'] as num?)?.toInt() ??
          (owner is Map<String, dynamic>
              ? (owner['id'] as num?)?.toInt()
              : null),
    );
  }
}
