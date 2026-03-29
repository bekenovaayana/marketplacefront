import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/api_field_errors.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';

final postingRepositoryProvider = Provider<PostingRepository>((ref) {
  return PostingRepository(ref.watch(dioProvider));
});

class PostingRepository {
  PostingRepository(this._dio);

  final Dio _dio;

  Future<List<HomeCategory>> categories() async {
    final response = await _dio.get(
      '/categories',
      options: Options(extra: {'publicEndpoint': true}),
      queryParameters: {'limit': 500},
    );
    final data = response.data;
    if (data is List<dynamic>) {
      return data.map((e) => HomeCategory.fromJson(e as Map<String, dynamic>)).toList();
    }
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items.map((e) => HomeCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<int> createDraft(PostingDraftPayload payload) async {
    Response<dynamic> response;
    try {
      response = await _dio.post('/listings', data: payload.toJson());
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final shouldFallbackToDrafts =
          code == 404 ||
          code == 405 ||
          // Some older backends validate POST /listings strictly and return 422.
          // Fallback to draft endpoint keeps creation flow working.
          code == 422;
      if (shouldFallbackToDrafts) {
        try {
          response = await _dio.post('/listings/drafts', data: payload.toJson());
        } on DioException catch (e2) {
          throw _mapDio(e2, fallbackMessage: 'Draft creation failed');
        }
      } else {
        throw _mapDio(e, fallbackMessage: 'Draft creation failed');
      }
    }
    final data = response.data;
    if (data is Map<String, dynamic>) {
      final id = data['id'];
      if (id is num) return id.toInt();
      final listing = data['listing'];
      if (listing is Map<String, dynamic> && listing['id'] is num) {
        return (listing['id'] as num).toInt();
      }
    }
    throw const ApiException('Invalid draft response from server');
  }

  Future<void> updateDraft(int draftId, PostingDraftPayload payload) async {
    try {
      await _dio.patch('/listings/$draftId', data: payload.toJson());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404 || e.response?.statusCode == 405) {
        try {
          await _dio.put('/listings/drafts/$draftId', data: payload.toJson());
        } on DioException catch (e2) {
          throw _mapDio(e2, fallbackMessage: 'Draft update failed');
        }
        return;
      }
      throw _mapDio(e, fallbackMessage: 'Draft update failed');
    }
  }

  Future<void> reorderImages(int listingId, List<PostingImage> images) async {
    final payload = images.map((e) => e.toJson()).toList();
    try {
      await _dio.put(
        '/listings/$listingId/images/reorder',
        data: {'images': payload},
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 422 || e.response?.statusCode == 400) {
        try {
          await _dio.put(
            '/listings/$listingId/images/reorder',
            data: payload,
          );
        } on DioException catch (e2) {
          throw _mapDio(e2, fallbackMessage: 'Failed to reorder images');
        }
        return;
      }
      throw _mapDio(e, fallbackMessage: 'Failed to reorder images');
    }
  }

  Future<Map<String, dynamic>> preview(int listingId) async {
    try {
      final response = await _dio.get('/listings/$listingId/preview');
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _mapDio(e, fallbackMessage: 'Failed to load preview');
    }
  }

  Future<void> publish(int listingId) async {
    try {
      await _dio.post('/listings/$listingId/publish');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
        final fe = tryApiFieldErrorsFromResponse(data);
        if (fe != null) {
          throw fe;
        }
        if (data is Map<String, dynamic> && data['detail'] is Map<String, dynamic>) {
          final detail = data['detail'] as Map<String, dynamic>;
          final missing = (detail['missing_fields'] as List<dynamic>? ?? [])
              .map((e) => e.toString())
              .toList();
          throw DraftIncompleteException(
            message: detail['message']?.toString() ?? 'Draft is incomplete',
            missingFields: missing,
          );
        }
      }
      throw _mapDio(e, fallbackMessage: 'Publish failed');
    }
  }

  Future<void> unpublish(int listingId) async {
    try {
      await _dio.post('/listings/$listingId/unpublish');
    } on DioException catch (e) {
      throw _mapDio(e, fallbackMessage: 'Unpublish failed');
    }
  }

  Future<List<ListingMine>> myListings({
    String? status,
    int? categoryId,
    String sort = 'newest',
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };
    if (status != null && status.isNotEmpty) {
      params['status'] = status;
    }
    if (categoryId != null) {
      params['category_id'] = categoryId;
    }
    Response<dynamic> response;
    if (kDebugMode) {
      debugPrint('[PostingRepository.myListings] GET /listings/me params=$params');
    }
    try {
      // Use canonical /listings/me endpoint directly.
      // Previously the code tried /listings/my first, but that path matches
      // /{listing_id} with a non-integer value and FastAPI returns 422 instead
      // of 404, so the fallback was never triggered.
      response = await _dio.get('/listings/me', queryParameters: params);
    } on DioException catch (e) {
      throw _mapDio(e, fallbackMessage: 'Failed to load my listings');
    }
    final data = response.data;
    final items = data is List<dynamic>
        ? data
        : ((data as Map<String, dynamic>)['items'] as List<dynamic>? ?? []);
    if (kDebugMode) {
      debugPrint(
        '[PostingRepository.myListings] items=${items.length} (status=$status sort=$sort)',
      );
    }
    return items.map((e) => ListingMine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getById(int id) async {
    try {
      final preview = await _dio.get('/listings/$id/preview');
      return preview.data as Map<String, dynamic>;
    } on DioException catch (e) {
      try {
        final response = await _dio.get('/listings/$id');
        return response.data as Map<String, dynamic>;
      } on DioException {
        throw _mapDio(e, fallbackMessage: 'Failed to load listing');
      }
    }
  }

  Future<PostingImage> uploadImage(XFile file) async {
    Future<Response<dynamic>> postTo(String path) async {
      final mimeType = _effectiveMimeType(file);
      final multipart = await MultipartFile.fromFile(
        file.path,
        filename: file.name,
        contentType: _resolveContentType(mimeType),
      );
      return _dio.post(
        path,
        data: FormData.fromMap({'file': multipart}),
        options: Options(contentType: 'multipart/form-data'),
      );
    }

    try {
      Response<dynamic> response;
      try {
        response = await postTo('/uploads');
      } on DioException catch (e) {
        final code = e.response?.statusCode;
        if (code == 404 || code == 405) {
          response = await postTo('/uploads/images');
        } else {
          rethrow;
        }
      }
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PostingImage(
          url: (data['url'] as String?) ?? '',
          sortOrder: 0,
        );
      }
      throw const ApiException('Upload response missing url');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final fe = tryApiFieldErrorsFromResponse(e.response?.data);
      if (fe != null) throw fe;
      if (code == 413) {
        throw const ApiException('Image is too large. Max size is 64MB.', statusCode: 413);
      }
      if (code == 415) {
        throw const ApiException(
          'Unsupported image format.',
          statusCode: 415,
        );
      }
      throw _mapDio(e, fallbackMessage: 'Upload failed');
    }
  }

  Future<PostingImage> uploadListingMedia({
    required int listingId,
    required XFile file,
  }) async {
    final mimeType = _effectiveMimeType(file);
    final multipart = await MultipartFile.fromFile(
      file.path,
      filename: file.name,
      contentType: _resolveContentType(mimeType),
    );
    try {
      final response = await _dio.post(
        '/listing-media',
        data: FormData.fromMap({
          'listing_id': listingId.toString(),
          'file': multipart,
        }),
        options: Options(contentType: 'multipart/form-data'),
      );
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return PostingImage(
          url: (data['url'] as String?) ?? '',
          sortOrder: (data['sort_order'] as num?)?.toInt() ?? 0,
        );
      }
      throw const ApiException('Upload response missing url');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final fe = tryApiFieldErrorsFromResponse(e.response?.data);
      if (fe != null) throw fe;
      if (code == 413) {
        throw const ApiException('File is too large.', statusCode: 413);
      }
      if (code == 415) {
        throw const ApiException(
          'Unsupported format. Use jpg, png, webp, mp4, webm, or mov.',
          statusCode: 415,
        );
      }
      final payload = e.response?.data;
      if (payload is Map<String, dynamic> && payload['detail'] is String) {
        throw ApiException(payload['detail'] as String, statusCode: code);
      }
      throw _mapDio(e, fallbackMessage: 'Upload failed');
    }
  }

  Future<void> deleteListing(int id) async {
    try {
      await _dio.delete<void>('/listings/$id');
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      final data = e.response?.data;
      if (data is Map<String, dynamic>) {
        final detail = data['detail'];
        if (detail is String && detail.isNotEmpty) {
          throw ApiException(detail, statusCode: code);
        }
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
      throw _mapDio(e, fallbackMessage: 'Delete failed');
    }
  }

  MediaType _resolveContentType(String? mimeType) {
    final mime = (mimeType ?? '').toLowerCase();
    if (mime == 'image/jpeg' || mime == 'image/jpg') {
      return MediaType('image', 'jpeg');
    }
    if (mime == 'image/png') {
      return MediaType('image', 'png');
    }
    if (mime == 'image/webp') {
      return MediaType('image', 'webp');
    }
    if (mime == 'image/heic' || mime == 'image/heif') {
      return MediaType('image', 'heic');
    }
    if (mime == 'video/mp4') {
      return MediaType('video', 'mp4');
    }
    if (mime == 'video/webm') {
      return MediaType('video', 'webm');
    }
    if (mime == 'video/quicktime') {
      return MediaType('video', 'quicktime');
    }
    return MediaType('application', 'octet-stream');
  }

  String? _effectiveMimeType(XFile file) {
    final direct = (file.mimeType ?? '').trim().toLowerCase();
    if (direct.isNotEmpty) return direct;
    final guessed = (lookupMimeType(file.path) ?? '').trim().toLowerCase();
    if (guessed.isNotEmpty) return guessed;
    return null;
  }

  Object _mapDio(
    DioException e, {
    required String fallbackMessage,
  }) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 422) {
      final fe = tryApiFieldErrorsFromResponse(data);
      if (fe != null) return fe;
    }
    if (data is Map<String, dynamic>) {
      final detail = parseApiDetailString(data);
      if (detail != null && detail.isNotEmpty) {
        return ApiException(detail, statusCode: status);
      }
    }
    return ApiException(e.message ?? fallbackMessage, statusCode: status);
  }
}
