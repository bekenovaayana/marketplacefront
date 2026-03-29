import 'package:marketplace_frontend/core/json/json_read.dart';

/// Баланс кошелька. Безопасный разбор `balance` (int / double / string) из JSON.
class Wallet {
  const Wallet({
    required this.balance,
    required this.currency,
  });

  final double balance;
  final String currency;

  /// Когда оба пути API недоступны — UI всё равно показывает валидный объект.
  static const Wallet fallback = Wallet(balance: 0, currency: 'KGS');

  factory Wallet.fromJson(Map<String, dynamic> json) {
    final cur = JsonRead.string(json['currency'], 'KGS');
    return Wallet(
      balance: JsonRead.doubleVal(json['balance']),
      currency: cur.isEmpty ? 'KGS' : cur,
    );
  }
}
