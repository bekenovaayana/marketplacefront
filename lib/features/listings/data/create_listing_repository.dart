import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';

final createListingRepositoryProvider = Provider<CreateListingRepository>((ref) {
  return CreateListingRepository(ref.watch(dioProvider));
});

class UploadedImage {
  const UploadedImage({
    required this.url,
    required this.contentType,
    required this.sizeBytes,
  });

  final String url;
  final String contentType;
  final int sizeBytes;

  factory UploadedImage.fromJson(Map<String, dynamic> json) {
    return UploadedImage(
      url: json['url'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

class CreateListingInput {
  const CreateListingInput({
    required this.categoryId,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.city,
    required this.contactPhone,
    this.latitude,
    this.longitude,
    this.imageUrls = const [],
  });

  final int categoryId;
  final String title;
  final String description;
  final double price;
  final String currency;
  final String city;
  final String contactPhone;
  final double? latitude;
  final double? longitude;
  final List<String> imageUrls;

  Map<String, dynamic> toJson() {
    return {
      'category_id': categoryId,
      'title': title,
      'description': description,
      'price': price,
      'currency': currency,
      'city': city,
      'contact_phone': contactPhone,
      'latitude': latitude,
      'longitude': longitude,
      'images': imageUrls.asMap().entries
          .map((e) => {'url': e.value, 'sort_order': e.key})
          .toList(),
    };
  }
}

class CreateListingRepository {
  CreateListingRepository(this._dio);

  final Dio _dio;

  Future<List<HomeCategory>> categories() async {
    final response = await _dio.get('/categories', queryParameters: {'limit': 100});
    final data = response.data;
    if (data is List<dynamic>) {
      return data.map((e) => HomeCategory.fromJson(e as Map<String, dynamic>)).toList();
    }
    final items = (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items.map((e) => HomeCategory.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<UploadedImage> uploadImage(XFile file) async {
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
      return UploadedImage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 413) {
        throw const ApiException('Image is too large. Max size is 64MB.', statusCode: 413);
      }
      if (code == 415) {
        throw const ApiException(
          'Unsupported image type. Use jpg, png, or webp.',
          statusCode: 415,
        );
      }
      throw ApiException('Upload failed', statusCode: code);
    }
  }

  Future<void> createListing(CreateListingInput input) async {
    await _dio.post('/listings', data: input.toJson());
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
