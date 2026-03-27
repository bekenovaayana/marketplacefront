import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/promotions/state/promote_listing_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class PromoteListingScreen extends ConsumerStatefulWidget {
  const PromoteListingScreen({super.key});

  @override
  ConsumerState<PromoteListingScreen> createState() =>
      _PromoteListingScreenState();
}

class _PromoteListingScreenState extends ConsumerState<PromoteListingScreen> {
  bool _requestedLoad = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promoteListingProvider);
    final controller = ref.read(promoteListingProvider.notifier);

    if (!_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(() => controller.load());
    }

    final option = controller.selectedOption;

    return AppScaffold(
      title: 'Promote listing',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (state.error != null)
              Card(
                child: ListTile(
                  title: Text(
                    _friendlyPromoteError(state.error),
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: TextButton(
                    onPressed: state.isLoading ? null : controller.load,
                    child: const Text('Retry'),
                  ),
                ),
              ),
            if (state.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else ...[
              if (state.activeListings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Center(child: Text('You have no active listings')),
                )
              else
                DropdownButtonFormField<int>(
                  initialValue: state.selectedListingId,
                  items: state.activeListings
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectListing,
                  decoration: const InputDecoration(labelText: 'Listing'),
                ),
              const SizedBox(height: 12),
              DropdownButtonFormField<int>(
                initialValue: state.selectedDays,
                items:
                    (state.options.toList()
                          ..sort((a, b) => a.days.compareTo(b.days)))
                        .map(
                          (o) => DropdownMenuItem(
                            value: o.days,
                            child: Text('${o.days} days'),
                          ),
                        )
                        .toList(),
                onChanged: controller.selectDays,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Price summary',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        option == null
                            ? '—'
                            : '${option.price.toStringAsFixed(2)} ${option.currency}',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: (state.isPaying || state.activeListings.isEmpty)
                    ? null
                    : () async => _pay(controller),
                child: state.isPaying
                    ? const CircularProgressIndicator()
                    : const Text('Pay'),
              ),
              if (state.checkout != null) ...[
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Checkout created',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        if (state.checkout!.checkoutUrl != null &&
                            state.checkout!.checkoutUrl!.isNotEmpty)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _openCheckoutUrl(state.checkout!.checkoutUrl!),
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Open payment page'),
                          )
                        else
                          const Text('Payment flow is mocked for now.'),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pay(PromoteListingController controller) async {
    await controller.pay();
    if (!mounted) return;
    final error = ref.read(promoteListingProvider).error;
    if (error == null) {
      showAppNotification(context, 'Checkout created');
    } else {
      showAppNotification(context, _friendlyPromoteError(error));
    }
  }

  String _friendlyPromoteError(Object? error) {
    if (error is ApiException) {
      final code = error.statusCode;
      if (code == 403) return 'You can promote only your listings';
      if (code == 409) return 'Listing must be active to promote';
      return error.message;
    }
    final text = (error ?? '').toString();
    if (text.contains('403')) return 'You can promote only your listings';
    if (text.contains('409')) return 'Listing must be active to promote';
    return ErrorMapper.friendly(error);
  }

  Future<void> _openCheckoutUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      showAppNotification(context, 'Invalid checkout URL');
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      showAppNotification(context, 'Unable to open payment link');
    }
  }
}
