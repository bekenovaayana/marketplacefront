import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/listings/data/listing_details_repository.dart';
import 'package:marketplace_frontend/features/listings/models/listing_detail.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  const ListingDetailPage({super.key, required this.listingId});

  final int listingId;

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  late Future<ListingDetail> _future;
  bool _contactBusy = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingDetailsRepositoryProvider).getById(widget.listingId);
  }

  String t(String key) => AppStrings.of(context, key);

  Future<void> _onRequestContact(ListingDetail data) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      final from = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      if (mounted) context.push('/auth-gate?from=$from');
      return;
    }
    setState(() => _contactBusy = true);
    try {
      await ref
          .read(listingDetailsRepositoryProvider)
          .postContactIntent(widget.listingId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('contactIntentSent'))),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = e.statusCode == 429
          ? t('contactIntentThrottle')
          : ErrorMapper.friendly(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(e.toString()))),
      );
    } finally {
      if (mounted) setState(() => _contactBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ListingDetail>(
      future: _future,
      builder: (context, snapshot) {
        final data = snapshot.data;
        final auth = ref.watch(authControllerProvider);
        final isOwner = auth.isAuthenticated &&
            data?.ownerUserId != null &&
            data!.ownerUserId == auth.user!.id;
        final showContactButton = data != null && !isOwner;

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
                        if (showContactButton) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _contactBusy
                                  ? null
                                  : () => _onRequestContact(data),
                              icon: _contactBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.mail_outline),
                              label: Text(t('contactSeller')),
                            ),
                          ),
                        ],
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
