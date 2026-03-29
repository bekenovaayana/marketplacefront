import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/wallet/data/wallet_repository.dart';
import 'package:marketplace_frontend/features/wallet/state/wallet_providers.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

/// После входа токен подставляет [AuthInterceptor] на общем Dio.
/// Загрузка баланса устойчива к 404/сети: см. [walletRepositoryProvider.getWallet].
class WalletScreen extends ConsumerStatefulWidget {
  const WalletScreen({super.key});

  @override
  ConsumerState<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends ConsumerState<WalletScreen> {
  final _amountController = TextEditingController(text: '100');
  bool _toppingUp = false;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String _formatBalance(double balance, String currency) {
    final text = balance % 1 == 0
        ? balance.toStringAsFixed(0)
        : balance.toStringAsFixed(2);
    return '$text $currency';
  }

  Future<void> _showTopUpDialog() async {
    _amountController.text = '100';
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Пополнить кошелёк'),
        content: TextField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Сумма (KGS)',
            hintText: '100',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Отмена'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Пополнить'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    final amount =
        double.tryParse(_amountController.text.trim().replaceAll(',', '.')) ??
            0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите положительную сумму')),
      );
      return;
    }
    setState(() => _toppingUp = true);
    try {
      await ref.read(walletRepositoryProvider).topUp(amount: amount);
      ref.invalidate(walletProvider);
      await ref.read(walletProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Баланс обновлён')),
      );
    } on DioException catch (e) {
      if (!mounted) return;
      final detail = WalletRepository.extractDetail(e);
      final message = detail != null && detail.isNotEmpty
          ? detail
          : ErrorMapper.friendly(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(e))),
      );
    } finally {
      if (mounted) {
        setState(() => _toppingUp = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final walletAsync = ref.watch(walletProvider);

    return AppScaffold(
      title: 'Кошелёк',
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(walletProvider);
          await ref.read(walletProvider.future);
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            walletAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, st) => ListTile(
                title: Text(
                  ErrorMapper.friendly(e),
                  style: const TextStyle(color: Colors.red),
                ),
                subtitle: const Text(
                  'Неожиданная ошибка провайдера (getWallet не должен сюда попадать).',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: TextButton(
                  onPressed: () => ref.invalidate(walletProvider),
                  child: const Text('Повторить'),
                ),
              ),
              data: (w) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Баланс',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _formatBalance(w.balance, w.currency),
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _toppingUp ? null : _showTopUpDialog,
                      icon: _toppingUp
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Пополнить'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Пополнение — демо (без реального эквайринга). Баланс после пополнения обновляется через GET /wallet или /api/wallet. Списание за промо — только на сервере.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
