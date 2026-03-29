import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';
import 'package:marketplace_frontend/features/conversations/state/conversations_controller.dart';
import 'package:marketplace_frontend/features/conversations/ui/conversation_detail_page.dart';
import 'package:marketplace_frontend/features/favorites/state/favorite_stale_guard.dart';
import 'package:marketplace_frontend/core/routing/app_router.dart';
import 'package:marketplace_frontend/features/listings/data/listing_details_repository.dart';
import 'package:marketplace_frontend/features/listings/models/listing_detail.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class ListingDetailPage extends ConsumerStatefulWidget {
  const ListingDetailPage({
    super.key,
    required this.listingId,
    this.useOwnerPreview = false,
  });

  final int listingId;
  /// Use [GET /listings/:id/preview] (drafts / owner view) instead of public [GET /listings/:id].
  final bool useOwnerPreview;

  @override
  ConsumerState<ListingDetailPage> createState() => _ListingDetailPageState();
}

class _ListingDetailPageState extends ConsumerState<ListingDetailPage> {
  late Future<ListingDetail> _future;
  bool _messageBusy = false;
  bool _deleteBusy = false;
  bool _promoteBusy = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(listingDetailsRepositoryProvider).fetchDetail(
          widget.listingId,
          ownerPreview: widget.useOwnerPreview,
        );
  }

  String t(String key) => AppStrings.of(context, key);

  static bool _isListingOwner(ListingDetail? data, AuthState auth) {
    if (data == null) return false;
    if (data.listing.isOwner == true) return true;
    if (!auth.isAuthenticated) return false;
    final uid = auth.user?.id;
    if (uid == null) return false;
    final ownerId = data.listing.userId ?? data.ownerUserId;
    return ownerId != null && ownerId == uid;
  }

  /// Image order follows API: [image_urls] or sorted [images] (full URLs as returned).
  List<String> _resolvedImageUrls(ListingDetail data) {
    return data.listing.images
        .map((e) => ApiUrls.networkImageUrl(e.url))
        .where((u) => u.isNotEmpty)
        .toList();
  }

  Future<void> _onMessageSeller(ListingDetail data) async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      final from = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      if (mounted) context.push('/auth-gate?from=$from');
      return;
    }
    final sellerId = data.listing.userId ?? data.ownerUserId;
    if (sellerId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('messageSellerNoSeller'))),
      );
      return;
    }
    setState(() => _messageBusy = true);
    try {
      final open = await ref
          .read(conversationsApiProvider)
          .openConversationForListingAsBuyer(widget.listingId);
      if (open.conversationId <= 0) {
        throw const ApiException('Invalid conversation response');
      }
      await ref.read(conversationsControllerProvider.notifier).load(refresh: true);
      if (!mounted) return;
      final title = open.peer?.displayName;
      await Navigator.of(context).push<void>(
        MaterialPageRoute<void>(
          builder: (_) => ConversationDetailPage(
            conversationId: open.conversationId,
            peerTitle: title != 'Chat' ? title : null,
            peerUserId: open.peer?.id ?? sellerId,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('messageSellerFailed'))),
      );
    } finally {
      if (mounted) setState(() => _messageBusy = false);
    }
  }

  Future<void> _quickPromoteFromWallet() async {
    setState(() => _promoteBusy = true);
    try {
      final detail = await ref
          .read(listingDetailsRepositoryProvider)
          .promoteListingShortcut(widget.listingId);
      if (!mounted) return;
      setState(() {
        _future = Future.value(detail);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Объявление поднято (boost 7 дн.)')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(e.message))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(e))),
      );
    } finally {
      if (mounted) setState(() => _promoteBusy = false);
    }
  }

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t('deleteListingTitle')),
        content: Text(t('deleteListingMessage')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(t('deleteListingCancel')),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(ctx).colorScheme.error,
              foregroundColor: Theme.of(ctx).colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(t('deleteListingConfirm')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() => _deleteBusy = true);
    try {
      await ref
          .read(listingDetailsRepositoryProvider)
          .deleteListing(widget.listingId);
      await ref.read(myActiveListingsProvider.notifier).refresh();
      await ref.read(postingControllerProvider.notifier).refreshMyListingsOnly();
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      if (!mounted) return;
      final msg = switch (e.statusCode) {
        403 => t('listingDeleteForbidden'),
        404 => t('listingDeleteNotFound'),
        _ => ErrorMapper.friendly(e.message),
      };
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('listingDeleteFailed'))),
      );
    } finally {
      if (mounted) setState(() => _deleteBusy = false);
    }
  }

  Widget _buildImageGallery(List<String> urls) {
    if (urls.isEmpty) return const SizedBox.shrink();
    Widget imageBox(String url) {
      return Image.network(
        url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image_outlined),
        ),
      );
    }

    final gallery = urls.length == 1
        ? imageBox(urls.first)
        : PageView.builder(
            itemCount: urls.length,
            itemBuilder: (context, i) => imageBox(urls[i]),
          );

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AspectRatio(
        aspectRatio: 1.45,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            Positioned.fill(child: gallery),
            if (urls.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '${urls.length} ${t('listingPhotosLabel')}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    shadows: [Shadow(blurRadius: 4, color: Colors.black54)],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<ListingDetail>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: Text(t('listingDetails'))),
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  ErrorMapper.friendly(snapshot.error.toString()),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final raw = snapshot.data;
        ref.watch(favoriteStaleGuardProvider);
        final ListingDetail? data = raw == null
            ? null
            : ListingDetail(
                listing: ref
                    .read(favoriteStaleGuardProvider.notifier)
                    .mergeListingPublic(raw.listing),
                ownerName: raw.ownerName,
                ownerPhone: raw.ownerPhone,
                ownerUserId: raw.ownerUserId,
              );
        final auth = ref.watch(authControllerProvider);
        final isOwner = _isListingOwner(data, auth);
        final sellerId = data?.listing.userId ?? data?.ownerUserId;
        final showMessageSeller = data != null &&
            !isOwner &&
            auth.isAuthenticated &&
            sellerId != null;

        final imageUrls = data != null ? _resolvedImageUrls(data) : <String>[];

        return Scaffold(
          appBar: AppBar(title: Text(t('listingDetails'))),
          body: snapshot.connectionState == ConnectionState.waiting
              ? const Center(child: CircularProgressIndicator())
              : data == null
                  ? Center(child: Text(t('listingNotFound')))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        _buildImageGallery(imageUrls),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              '${data.listing.price.toStringAsFixed(0)} ${data.listing.currency}',
                              style: Theme.of(context)
                                  .textTheme
                                  .headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            if (data.listing.isPromoted)
                              Chip(
                                label: const Text('Промо'),
                                visualDensity: VisualDensity.compact,
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                          ],
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
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(data.ownerName),
                                if (data.ownerPhone.isNotEmpty)
                                  Text('${t('contact')}: ${data.ownerPhone}'),
                              ],
                            ),
                          ),
                        ),
                        if (!isOwner && !auth.isAuthenticated) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                final from = Uri.encodeComponent(
                                  GoRouterState.of(context).uri.toString(),
                                );
                                context.push('/auth-gate?from=$from');
                              },
                              icon: const Icon(Icons.chat_bubble_outline),
                              label: Text(t('signInToMessage')),
                            ),
                          ),
                        ],
                        if (showMessageSeller) ...[
                          const SizedBox(height: 14),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: _messageBusy
                                  ? null
                                  : () => _onMessageSeller(data),
                              icon: _messageBusy
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.chat_bubble_outline),
                              label: Text(t('messageSeller')),
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
          bottomNavigationBar:
              isOwner && data != null && auth.isAuthenticated
                  ? SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (data.listing.isListingActive) ...[
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton.icon(
                                  onPressed: _promoteBusy
                                      ? null
                                      : () => ref
                                          .read(appRouterProvider)
                                          .push('/promote'),
                                  icon: const Icon(Icons.trending_up_outlined),
                                  label: const Text('Промо (кошелёк)'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.tonal(
                                  onPressed: _promoteBusy
                                      ? null
                                      : _quickPromoteFromWallet,
                                  child: _promoteBusy
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Быстро поднять (7 дн.)'),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            SizedBox(
                              width: double.infinity,
                              child: FilledButton(
                                style: FilledButton.styleFrom(
                                  backgroundColor:
                                      Theme.of(context).colorScheme.error,
                                  foregroundColor:
                                      Theme.of(context).colorScheme.onError,
                                ),
                                onPressed: _deleteBusy ? null : _confirmAndDelete,
                                child: _deleteBusy
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(t('deleteListingButton')),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
        );
      },
    );
  }
}
