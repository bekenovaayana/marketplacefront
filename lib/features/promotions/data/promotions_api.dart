import 'package:dio/dio.dart';
import 'package:marketplace_frontend/core/constants/listing_currency.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';

final promotionsApiProvider = Provider<PromotionsApi>((ref) {
  return PromotionsApi(ref.watch(dioProvider));
});

class PromotionOptionDto {
  const PromotionOptionDto({
    required this.days,
    required this.price,
    required this.currency,
  });

  final int days;
  final double price;
  final String currency;

  factory PromotionOptionDto.fromJson(Map<String, dynamic> json) {
    return PromotionOptionDto(
      days: (json['days'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? ListingCurrency.backendDefault,
    );
  }
}

class PromotionsCheckoutResponse {
  const PromotionsCheckoutResponse({
    this.clientSecret,
    this.checkoutUrl,
    this.price,
    this.currency,
  });

  final String? clientSecret;
  final String? checkoutUrl;
  final double? price;
  final String? currency;

  factory PromotionsCheckoutResponse.fromJson(Map<String, dynamic> json) {
    return PromotionsCheckoutResponse(
      clientSecret: json['client_secret'] as String?,
      checkoutUrl: json['checkout_url'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

/// Successful wallet purchase: **POST /promotions** (201).
class WalletPromotionPurchaseResult {
  const WalletPromotionPurchaseResult({
    required this.id,
    required this.type,
    this.expiresAt,
  });

  final int id;
  final String type;
  final DateTime? expiresAt;

  factory WalletPromotionPurchaseResult.fromJson(Map<String, dynamic> json) {
    return WalletPromotionPurchaseResult(
      id: JsonRead.intVal(json['id']),
      type: JsonRead.string(json['type']),
      expiresAt: DateTime.tryParse(
        JsonRead.string(json['expires_at'] ?? json['expiresAt']),
      ),
    );
  }
}

/// UI hint only — server charges the real amount (**boost/top/vip KGS × days**).
class PromotionWalletPricing {
  PromotionWalletPricing._();

  static const double boostPerDay = 20;
  static const double topPerDay = 40;
  static const double vipPerDay = 100;

  static double estimateKgsPerDay(String type) {
    switch (type) {
      case 'top':
        return topPerDay;
      case 'vip':
        return vipPerDay;
      case 'boost':
      default:
        return boostPerDay;
    }
  }

  static double estimateTotal(String type, int days) =>
      estimateKgsPerDay(type) * days;
}

class PromotionListItem {
  const PromotionListItem({
    required this.id,
    required this.listingId,
    required this.status,
    this.price,
    this.currency,
  });

  final int id;
  final int listingId;
  final String status;
  final double? price;
  final String? currency;

  factory PromotionListItem.fromJson(Map<String, dynamic> json) {
    final listingRaw = json['listing'];
    final listingId = (json['listing_id'] as num?)?.toInt() ??
        (listingRaw is Map<String, dynamic>
            ? (listingRaw['id'] as num?)?.toInt()
            : null) ??
        0;
    return PromotionListItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      listingId: listingId,
      status: json['status'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ??
          (json['amount'] as num?)?.toDouble(),
      currency: json['currency'] as String?,
    );
  }
}

class PromotionsApi {
  PromotionsApi(this._dio);

  final Dio _dio;

  Future<List<PromotionListItem>> fetchPromotions({String? status}) async {
    final response = await _dio.get(
      '/promotions',
      queryParameters: {
        if (status != null && status.isNotEmpty) 'status': status,
      },
    );
    final data = response.data;
    final items = data is List<dynamic>
        ? data
        : ((data as Map<String, dynamic>)['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => PromotionListItem.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<PromotionOptionDto>> getOptions() async {
    final response = await _dio.get('/promotions/options');
    final data = response.data;
    final items = data is List<dynamic>
        ? data
        : ((data as Map<String, dynamic>)['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => PromotionOptionDto.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<PromotionsCheckoutResponse> checkout({
    required int listingId,
    required int days,
  }) async {
    final response = await _dio.post(
      '/promotions/checkout',
      data: {'listing_id': listingId, 'days': days},
    );
    return PromotionsCheckoutResponse.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  /// Wallet promo (**POST /promotions**) — not checkout. **400** = insufficient balance (detail from API).
  Future<WalletPromotionPurchaseResult> purchasePromotionFromWallet({
    required int listingId,
    required String type,
    int days = 7,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        '/promotions',
        data: {
          'listing_id': listingId,
          'type': type,
          'days': days,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Invalid promotion response');
      }
      return WalletPromotionPurchaseResult.fromJson(data);
    } on DioException catch (e) {
      final msg = _extractDetail(e) ?? e.message ?? 'Promotion failed';
      throw ApiException(msg, statusCode: e.response?.statusCode);
    }
  }

  static String? _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}
