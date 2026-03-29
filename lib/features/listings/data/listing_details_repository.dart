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

  /// Public card: [GET /listings/:id]. Owner preview (drafts / inactive): [GET /listings/:id/preview].
  Future<ListingDetail> fetchDetail(int id, {bool ownerPreview = false}) async {
    final path =
        ownerPreview ? '/listings/$id/preview' : '/listings/$id';
    final response = await _dio.get(path);
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid listing response');
    }
    return ListingDetail.fromJson(data);
  }

  Future<ListingDetail> getById(int id) => fetchDetail(id);

  /// **POST /listings/:id/promote** — шорткат boost 7 дн.; тело полного объявления (owner read).
  Future<ListingDetail> promoteListingShortcut(int id) async {
    final response = await _dio.post<dynamic>('/listings/$id/promote');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw const ApiException('Invalid listing response');
    }
    return ListingDetail.fromJson(data);
  }

  /// [DELETE /listings/:id] — 204 success; 403 not owner; 404 missing or removed.
  Future<void> deleteListing(int id) async {
    try {
      await _dio.delete<void>('/listings/$id');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final detail = _deleteDetailMessage(e);
      if (detail != null && detail.isNotEmpty) {
        throw ApiException(detail, statusCode: code);
      }
      if (code == 403) {
        throw const ApiException(
          'You can delete only your own listings.',
          statusCode: 403,
        );
      }
      if (code == 404) {
        throw const ApiException(
          'Listing not found or already removed.',
          statusCode: 404,
        );
      }
      throw ApiException(
        e.message ?? 'Could not delete listing.',
        statusCode: code,
      );
    }
  }

  static String? _deleteDetailMessage(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }

  /// POST /listings/:id/contact-intent — **200** for both first and repeat (detail text varies).
  /// Do not treat **429** as a hard error (legacy throttle); same UX as success.
  Future<void> postContactIntent(int listingId) async {
    try {
      final response = await _dio.post<dynamic>('/listings/$listingId/contact-intent');
      final code = response.statusCode;
      if (code != null && code >= 200 && code < 300) return;
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      if (status != null && status >= 200 && status < 300) return;
      if (status == 429) return;
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
