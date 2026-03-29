import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/auth/models/auth_user.dart';

final authApiProvider = Provider<AuthApi>((ref) {
  return AuthApi(ref.watch(dioProvider));
});

class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/login',
      data: {
        'email': email,
        'password': password,
      },
      options: Options(extra: {'publicEndpoint': true}),
    );
    return response.data as Map<String, dynamic>;
  }

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final response = await _dio.post(
      '/auth/register',
      data: {
        'full_name': fullName,
        'email': email,
        'password': password,
      },
      options: Options(extra: {'publicEndpoint': true}),
    );
    return AuthUser.fromJson(response.data as Map<String, dynamic>);
  }

  /// Backend canonical profile: [GET /users/me]. Tries [GET /auth/me] only if 404 (older servers).
  Future<AuthUser> me() async {
    try {
      final response = await _dio.get('/users/me');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw StateError('GET /users/me: expected JSON object, got ${data.runtimeType}');
      }
      return AuthUser.fromJson(data);
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final response = await _dio.get('/auth/me');
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw StateError('GET /auth/me: expected JSON object');
        }
        return AuthUser.fromJson(data);
      }
      rethrow;
    }
  }
}
