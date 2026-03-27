import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class ListingDetail {
  const ListingDetail({
    required this.listing,
    required this.ownerName,
    required this.ownerPhone,
  });

  final ListingPublic listing;
  final String ownerName;
  final String ownerPhone;

  factory ListingDetail.fromJson(Map<String, dynamic> json) {
    return ListingDetail(
      listing: ListingPublic.fromJson(json),
      ownerName: json['owner_name'] as String? ??
          json['owner']?['full_name']?.toString() ??
          'Unknown',
      ownerPhone: json['contact_phone'] as String? ??
          json['owner']?['phone']?.toString() ??
          '',
    );
  }
}
