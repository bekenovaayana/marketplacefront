import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
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
    final response = await _dio.post('/listings/drafts', data: payload.toJson());
    return (response.data['id'] as num?)?.toInt() ?? 0;
  }

  Future<void> updateDraft(int draftId, PostingDraftPayload payload) async {
    await _dio.put('/listings/drafts/$draftId', data: payload.toJson());
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
        await _dio.put(
          '/listings/$listingId/images/reorder',
          data: payload,
        );
        return;
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> preview(int listingId) async {
    final response = await _dio.get('/listings/$listingId/preview');
    return response.data as Map<String, dynamic>;
  }

  Future<void> publish(int listingId) async {
    try {
      await _dio.post('/listings/$listingId/publish');
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        final data = e.response?.data;
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
      throw ApiException('Publish failed', statusCode: e.response?.statusCode);
    }
  }

  Future<void> unpublish(int listingId) async {
    await _dio.post('/listings/$listingId/unpublish');
  }

  Future<List<ListingMine>> myListings({
    required String status,
    int? categoryId,
    String sort = 'newest',
    int page = 1,
    int pageSize = 20,
  }) async {
    final params = <String, dynamic>{
      'status': status,
      'page': page,
      'page_size': pageSize,
      'sort': sort,
    };
    if (categoryId != null) {
      params['category_id'] = categoryId;
    }
    final response = await _dio.get('/listings/me', queryParameters: params);
    final data = response.data;
    final items = data is List<dynamic>
        ? data
        : ((data as Map<String, dynamic>)['items'] as List<dynamic>? ?? []);
    return items.map((e) => ListingMine.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Map<String, dynamic>> getById(int id) async {
    try {
      final preview = await _dio.get('/listings/$id/preview');
      return preview.data as Map<String, dynamic>;
    } catch (_) {
      final response = await _dio.get('/listings/$id');
      return response.data as Map<String, dynamic>;
    }
  }

  Future<PostingImage> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final multipart = MultipartFile.fromBytes(
      bytes,
      filename: file.name,
      contentType: _resolveContentType(file.mimeType),
    );
    try {
      final response = await _dio.post(
        '/uploads/images',
        data: FormData.fromMap({'file': multipart}),
        options: Options(contentType: 'multipart/form-data'),
      );
      return PostingImage(
        url: (response.data['url'] as String?) ?? '',
        sortOrder: 0,
      );
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 413) {
        throw const ApiException('Image is too large. Max size is 64MB.', statusCode: 413);
      }
      if (code == 415) {
        throw const ApiException(
          'Unsupported image format. Use jpg, png, webp.',
          statusCode: 415,
        );
      }
      throw ApiException('Upload failed', statusCode: code);
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
    return MediaType('application', 'octet-stream');
  }
}
