import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';

class ListingCard extends StatelessWidget {
  const ListingCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.onFavoriteTap,
  });

  final ListingPublic item;
  final VoidCallback onTap;
  final VoidCallback onFavoriteTap;

  @override
  Widget build(BuildContext context) {
    final date = item.createdAt == null
        ? ''
        : DateFormat('dd MMM').format(item.createdAt!.toLocal());
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: item.primaryImage.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.image_not_supported_outlined),
                          )
                        : Image.network(
                            item.primaryImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Colors.grey.shade200,
                                child: const Icon(Icons.broken_image_outlined),
                              );
                            },
                          ),
                  ),
                  Positioned(
                    right: 6,
                    top: 6,
                    child: CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.white,
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: onFavoriteTap,
                        icon: Icon(
                          item.isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: item.isFavorite ? Colors.red : Colors.black87,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 2),
              child: Text(
                '${item.price.toStringAsFixed(0)} ${item.currency}',
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 10),
              child: Text(
                [item.city, date].where((e) => e.isNotEmpty).join(' • '),
                style: TextStyle(color: Colors.grey.shade600, fontSize: 11.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
