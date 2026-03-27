import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';

final promotionsApiProvider = Provider<PromotionsApi>((ref) {
  return PromotionsApi(ref.watch(dioProvider));
});

class PromotionDto {
  const PromotionDto({required this.id, required this.status});

  final int id;
  final String status;

  factory PromotionDto.fromJson(Map<String, dynamic> json) {
    return PromotionDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

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
      currency: json['currency'] as String? ?? 'USD',
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

  Future<PromotionDto> createPromotion({
    required int listingId,
    required String promotionType,
    required String targetCity,
    required int durationDays,
  }) async {
    final response = await _dio.post(
      '/promotions',
      data: {
        'listing_id': listingId,
        'promotion_type': promotionType,
        'target_city': targetCity,
        'duration_days': durationDays,
      },
    );
    return PromotionDto.fromJson(response.data as Map<String, dynamic>);
  }
}
