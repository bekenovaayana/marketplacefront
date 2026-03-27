import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';

final paymentsApiProvider = Provider<PaymentsApi>((ref) {
  return PaymentsApi(ref.watch(dioProvider));
});

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.status,
    required this.amount,
  });

  final int id;
  final String status;
  final double amount;

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: (json['id'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'pending',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

class PaymentsApi {
  PaymentsApi(this._dio);

  final Dio _dio;

  Future<PaymentDto> createPayment({
    required int listingId,
    required double amount,
  }) async {
    final response = await _dio.post(
      '/payments',
      data: {'listing_id': listingId, 'amount': amount},
    );
    return PaymentDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<PaymentDto> simulateSuccess(int paymentId) async {
    final response = await _dio.post('/payments/$paymentId/simulate-success');
    return PaymentDto.fromJson(response.data as Map<String, dynamic>);
  }
}
