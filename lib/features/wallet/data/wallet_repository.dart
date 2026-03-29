import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/wallet/data/wallet_model.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository(ref.watch(dioProvider));
});

/// Репозиторий кошелька: Bearer через [dioProvider] / [AuthInterceptor], без хардкода токена.
class WalletRepository {
  WalletRepository(this._dio);

  final Dio _dio;

  static const String pathWallet = '/wallet';
  static const String pathWalletApi = '/api/wallet';
  static const String pathTopUp = '/wallet/top-up';
  static const String pathTopUpApi = '/api/wallet/top-up';

  /// Сначала [pathWallet], при любой ошибке — [pathWalletApi].
  /// **Не бросает** из‑за «нет кошелька» / 404 / сети: в конце — [Wallet.fallback].
  Future<Wallet> getWallet() async {
    try {
      return await _fetchWallet(pathWallet);
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WALLET GET $pathWallet failed: $e\n$st');
      }
      try {
        return await _fetchWallet(pathWalletApi);
      } catch (e2, st2) {
        if (kDebugMode) {
          debugPrint('WALLET GET $pathWalletApi failed: $e2\n$st2');
        }
        return Wallet.fallback;
      }
    }
  }

  Future<Wallet> _fetchWallet(String path) async {
    final response = await _dio.get<dynamic>(path);
    final data = response.data;
    if (kDebugMode) {
      // ignore: avoid_print
      print('WALLET RAW RESPONSE ($path): $data');
    }
    final parsed = parseWalletBodyOrNull(data);
    if (parsed != null) {
      return parsed;
    }
    throw StateError('Invalid wallet response body');
  }

  /// Плоское тело или `{ "data": { ... } }`.
  static Wallet? parseWalletBodyOrNull(dynamic responseData) {
    final map = JsonRead.map(responseData);
    if (map == null) {
      return null;
    }
    final walletJson = JsonRead.map(map['data']) ?? map;
    try {
      return Wallet.fromJson(walletJson);
    } on Object {
      return null;
    }
  }

  /// Пробует [pathTopUp], затем [pathTopUpApi]. Пробрасывает ошибку второго запроса, если оба неуспешны.
  Future<void> topUp({required double amount}) async {
    try {
      await _dio.post<dynamic>(pathTopUp, data: {'amount': amount});
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('WALLET POST $pathTopUp failed: $e\n$st');
      }
      await _dio.post<dynamic>(pathTopUpApi, data: {'amount': amount});
    }
  }

  static String? extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
    }
    return null;
  }
}
