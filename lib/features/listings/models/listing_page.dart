import 'package:marketplace_frontend/features/listings/models/listing.dart';

class ListingPage {
  const ListingPage({
    required this.items,
    required this.page,
    required this.totalPages,
  });

  final List<Listing> items;
  final int page;
  final int totalPages;

  bool get hasMore => page < totalPages;
}
