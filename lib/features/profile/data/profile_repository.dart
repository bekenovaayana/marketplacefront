import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/core/network/users_me_dedupe.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(dioProvider));
});

class ProfileRepository {
  ProfileRepository(this._dio);

  final Dio _dio;

  Future<UserMeResponse> getMe() async {
    final data = await UsersMeDedupe.fetch(_dio);
    return UserMeResponse.fromJson(data);
  }

  Future<ProfileCompletenessDto> getProfileCompleteness() async {
    final response = await _dio.get('/users/me/completeness');
    return ProfileCompletenessDto.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<UserMeResponse> updateMe(UpdateUserMeRequest request) async {
    try {
      final response = await _dio.patch('/users/me', data: request.toJson());
      return UserMeResponse.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.response?.statusCode == 422) {
        throw ProfileValidationException(
          _mapValidationErrors(e.response?.data),
        );
      }
      throw ApiException(
        mapProfileError(e.response?.statusCode, e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<List<String>> searchKgCities(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final response = await _dio.get(
      '/meta/cities',
      queryParameters: {'country': 'KG', 'q': trimmed},
    );
    final data = response.data;
    if (data is List) {
      return data.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
    }
    if (data is Map<String, dynamic>) {
      final cities = data['cities'];
      if (cities is List) {
        return cities
            .map((e) {
              if (e is Map<String, dynamic>) return e['name']?.toString() ?? '';
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    return const [];
  }

  Future<AvatarUploadResponse> uploadAvatar(XFile file) async {
    final bytes = await file.readAsBytes();
    final multipart = MultipartFile.fromBytes(
      bytes,
      filename: file.name,
      contentType: _contentType(file.mimeType, file.name),
    );
    try {
      final response = await _dio.post(
        '/users/me/avatar',
        data: FormData.fromMap({'file': multipart}),
        options: Options(contentType: 'multipart/form-data'),
      );
      return AvatarUploadResponse.fromJson(
        response.data as Map<String, dynamic>,
      );
    } on DioException catch (e) {
      throw ApiException(
        mapProfileError(e.response?.statusCode, e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<void> changePassword(
    String currentPassword,
    String newPassword,
  ) async {
    final payload = ChangePasswordRequest(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );
    try {
      await _dio.post('/users/change-password', data: payload.toJson());
    } on DioException catch (e) {
      throw ApiException(
        mapProfileError(e.response?.statusCode, e.response?.data),
        statusCode: e.response?.statusCode,
      );
    }
  }

  static String mapProfileError(int? statusCode, Object? data) {
    if (statusCode == 400) return 'Current password is incorrect.';
    if (statusCode == 413) return 'Avatar is too large. Maximum is 5MB.';
    if (statusCode == 415) return 'Unsupported avatar format. Use jpg/png.';
    if (statusCode == 422) {
      final errors = _mapValidationErrors(data);
      if (errors.isNotEmpty) {
        return errors.values.first;
      }
      return 'Validation failed.';
    }
    return 'Request failed. Please try again.';
  }

  MediaType _contentType(String? mimeType, String filename) {
    final resolvedMime = (mimeType ?? '').isNotEmpty
        ? mimeType
        : lookupMimeType(filename);
    switch ((resolvedMime ?? '').toLowerCase()) {
      case 'image/jpeg':
      case 'image/jpg':
        return MediaType('image', 'jpeg');
      case 'image/png':
        return MediaType('image', 'png');
      default:
        return MediaType('application', 'octet-stream');
    }
  }

  static Map<String, String> _mapValidationErrors(Object? data) {
    final result = <String, String>{};
    if (data is! Map<String, dynamic>) return result;
    final errors = data['errors'];
    if (errors is! List) return result;
    for (final item in errors) {
      if (item is! Map<String, dynamic>) continue;
      final dto = FieldValidationError.fromJson(item);
      if (dto.field.isEmpty || dto.message.isEmpty) continue;
      result[dto.field] = dto.message;
    }
    return result;
  }
}

class ProfileValidationException extends ApiException {
  ProfileValidationException(this.fieldErrors)
    : super(
        fieldErrors.values.isNotEmpty
            ? fieldErrors.values.first
            : 'Validation failed.',
        statusCode: 422,
      );

  final Map<String, String> fieldErrors;
}
