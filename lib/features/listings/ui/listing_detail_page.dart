import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/listings/data/listing_details_repository.dart';
import 'package:marketplace_frontend/features/listings/models/listing_detail.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class ListingDetailPage extends ConsumerWidget {
  const ListingDetailPage({super.key, required this.listingId});

  final int listingId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String t(String key) => AppStrings.of(context, key);
    return FutureBuilder<ListingDetail>(
      future: ref.read(listingDetailsRepositoryProvider).getById(listingId),
      builder: (context, snapshot) {
        final data = snapshot.data;
        return Scaffold(
          appBar: AppBar(title: Text(t('listingDetails'))),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : data == null
                  ? const Center(child: Text('Listing not found'))
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        if (data.listing.primaryImage.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: AspectRatio(
                              aspectRatio: 1.45,
                              child: Image.network(
                                data.listing.primaryImage,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey.shade200,
                                  child: const Icon(Icons.broken_image_outlined),
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          '${data.listing.price.toStringAsFixed(0)} ${data.listing.currency}',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          data.listing.title,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 6),
                        Text(data.listing.city),
                        const SizedBox(height: 14),
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t('owner'),
                                  style: const TextStyle(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 6),
                                Text(data.ownerName),
                                if (data.ownerPhone.isNotEmpty)
                                  Text('${t('contact')}: ${data.ownerPhone}'),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          t('description'),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(data.listing.description),
                      ],
                    ),
        );
      },
    );
  }
}
