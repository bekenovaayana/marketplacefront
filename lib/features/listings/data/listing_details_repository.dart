import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/listings/models/listing_detail.dart';

final listingDetailsRepositoryProvider = Provider<ListingDetailsRepository>((ref) {
  return ListingDetailsRepository(ref.watch(dioProvider));
});

class ListingDetailsRepository {
  ListingDetailsRepository(this._dio);

  final Dio _dio;

  Future<ListingDetail> getById(int id) async {
    final response = await _dio.get('/listings/$id');
    return ListingDetail.fromJson(response.data as Map<String, dynamic>);
  }

  Future<void> postContactIntent(int listingId) async {
    try {
      await _dio.post('/listings/$listingId/contact-intent');
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status == 429) {
        throw ApiException(
          _contactIntentDetail(e) ??
              'You have already sent a contact request for this listing. Try again later.',
          statusCode: 429,
        );
      }
      throw ApiException(
        _contactIntentDetail(e) ?? 'Could not send contact request.',
        statusCode: status,
      );
    }
  }

  static String? _contactIntentDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }
}
