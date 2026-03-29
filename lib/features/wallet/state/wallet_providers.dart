import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/wallet/data/wallet_model.dart';
import 'package:marketplace_frontend/features/wallet/data/wallet_repository.dart';

/// Данные кошелька: [WalletRepository.getWallet] **всегда** возвращает успешный [Wallet]
/// (в т.ч. [Wallet.fallback]), поэтому здесь ожидается `AsyncData`, не ошибка сети.
///
/// Обновление: `ref.invalidate(walletProvider)` (например pull-to-refresh).
final walletProvider = FutureProvider<Wallet>((ref) {
  return ref.watch(walletRepositoryProvider).getWallet();
});
