import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/promotions/data/promotions_api.dart';
import 'package:marketplace_frontend/features/promotions/state/promote_listing_controller.dart';
import 'package:marketplace_frontend/features/wallet/data/wallet_model.dart';
import 'package:marketplace_frontend/features/wallet/state/wallet_providers.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class PromoteListingScreen extends ConsumerStatefulWidget {
  const PromoteListingScreen({super.key});

  @override
  ConsumerState<PromoteListingScreen> createState() =>
      _PromoteListingScreenState();
}

class _PromoteListingScreenState extends ConsumerState<PromoteListingScreen> {
  bool _requestedLoad = false;
  final _daysController = TextEditingController(text: '7');

  @override
  void dispose() {
    _daysController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(promoteListingProvider);
    final controller = ref.read(promoteListingProvider.notifier);

    if (!_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(() async {
        await Future.wait<void>([
          controller.load(),
          ref.read(walletProvider.future),
        ]);
        if (!mounted) return;
        _daysController.text = '${ref.read(promoteListingProvider).selectedDays}';
      });
    }

    final walletAsync = ref.watch(walletProvider);

    return AppScaffold(
      title: 'Продвижение',
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            walletAsync.maybeWhen(
              data: (wb) => Card(
                child: ListTile(
                  title: const Text('Кошелёк'),
                  trailing: Text(
                    _walletAmountLabel(wb),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  onTap: () => context.push('/wallet'),
                ),
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            if (state.error != null)
              Card(
                child: ListTile(
                  title: Text(
                    _friendlyPromoteError(state.error),
                    style: const TextStyle(color: Colors.red),
                  ),
                  trailing: TextButton(
                    onPressed: state.isLoading ? null : controller.load,
                    child: const Text('Повторить'),
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
                  child: Center(child: Text('Нет активных объявлений')),
                )
              else ...[
                DropdownButtonFormField<int>(
                  value: () {
                    final id = state.selectedListingId;
                    if (id != null &&
                        state.activeListings.any((e) => e.id == id)) {
                      return id;
                    }
                    return state.activeListings.isEmpty
                        ? null
                        : state.activeListings.first.id;
                  }(),
                  items: state.activeListings
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.id,
                          child: Text(e.title, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: controller.selectListing,
                  decoration: const InputDecoration(labelText: 'Объявление'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: state.selectedType,
                  items: const [
                    DropdownMenuItem(value: 'boost', child: Text('Boost')),
                    DropdownMenuItem(value: 'top', child: Text('Top')),
                    DropdownMenuItem(value: 'vip', child: Text('VIP')),
                  ],
                  onChanged: (v) {
                    if (v != null) controller.selectType(v);
                  },
                  decoration: const InputDecoration(labelText: 'Тип'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _daysController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Дней (1–365)',
                  ),
                  onChanged: (s) {
                    final d = int.tryParse(s.trim()) ?? state.selectedDays;
                    controller.selectDays(d);
                  },
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Ориентир по тарифу',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'от ${controller.estimatedTotalKgs.toStringAsFixed(0)} KGS '
                          '(${PromotionWalletPricing.estimateKgsPerDay(state.selectedType).toStringAsFixed(0)} × ${state.selectedDays} дн.)',
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Точная сумма списывается на сервере.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: (state.isPurchasing || state.activeListings.isEmpty)
                      ? null
                      : () => _purchase(context, controller),
                  child: state.isPurchasing
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Оплатить с кошелька'),
                ),
              ],
            ],
            if (state.lastPurchase != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Colors.green.shade50,
                child: ListTile(
                  title: const Text('Промо активировано'),
                  subtitle: Text(
                    'Тип: ${state.lastPurchase!.type}'
                    '${state.lastPurchase!.expiresAt != null ? '\nДо: ${state.lastPurchase!.expiresAt}' : ''}',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _purchase(
    BuildContext context,
    PromoteListingController controller,
  ) async {
    final days = int.tryParse(_daysController.text.trim());
    if (days != null) {
      controller.selectDays(days);
    }
    try {
      final result = await controller.purchaseFromWallet();
      if (!context.mounted) return;
      if (result != null) {
        ref.invalidate(walletProvider);
        await ref.read(walletProvider.future);
        if (!context.mounted) return;
        showAppNotification(context, 'Промо оформлено');
      }
    } on ApiException catch (e) {
      if (!context.mounted) return;
      if (e.statusCode == 400) {
        final go = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Недостаточно средств'),
            content: Text(ErrorMapper.friendly(e.message)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Закрыть'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Кошелёк'),
              ),
            ],
          ),
        );
        if (!context.mounted) return;
        if (go == true) {
          context.push('/wallet');
        }
      } else {
        showAppNotification(context, _friendlyPromoteError(e));
      }
    } catch (e) {
      if (!context.mounted) return;
      showAppNotification(context, _friendlyPromoteError(e));
    }
  }

  static String _walletAmountLabel(Wallet wb) {
    final b = wb.balance;
    final t = b % 1 == 0 ? b.toStringAsFixed(0) : b.toStringAsFixed(2);
    return '$t ${wb.currency}';
  }

  String _friendlyPromoteError(Object? error) {
    if (error is ApiException) {
      final code = error.statusCode;
      if (code == 403) return 'Можно продвигать только свои объявления';
      if (code == 409) return 'Объявление должно быть активным';
      return ErrorMapper.friendly(error.message);
    }
    return ErrorMapper.friendly(error);
  }
}
