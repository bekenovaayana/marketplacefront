import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/core/storage/token_storage.dart';
import 'package:marketplace_frontend/features/auth/data/auth_api.dart';
import 'package:marketplace_frontend/features/auth/models/auth_session.dart';
import 'package:marketplace_frontend/features/auth/models/auth_user.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    api: ref.watch(authApiProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository({
    required AuthApi api,
    required TokenStorage tokenStorage,
  })  : _api = api,
        _tokenStorage = tokenStorage;

  final AuthApi _api;
  final TokenStorage _tokenStorage;

  static String extractAccessToken(Map<String, dynamic> data) {
    return data['access_token'] as String? ?? data['token'] as String? ?? '';
  }

  static String? extractRefreshToken(Map<String, dynamic> data) {
    final r = data['refresh_token'] ?? data['refreshToken'];
    if (r is String && r.trim().isNotEmpty) return r.trim();
    return null;
  }

  String _extractErrorMessage(Object? data, String fallback) {
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) {
        return detail;
      }
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map<String, dynamic>) {
          final msg = first['msg']?.toString();
          if (msg != null && msg.isNotEmpty) {
            return msg;
          }
        }
      }
    }
    return fallback;
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final data = await _api.login(email: email, password: password);
      final token = extractAccessToken(data);
      if (token.isEmpty) {
        throw const ApiException('Access token is missing');
      }
      final userJson = (data['user'] as Map<String, dynamic>?) ?? <String, dynamic>{};
      final user = AuthUser.fromJson(userJson);
      await _tokenStorage.saveAccessToken(token);
      await _tokenStorage.saveRefreshToken(extractRefreshToken(data));
      return AuthSession(accessToken: token, user: user);
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data, 'Login failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    try {
      return await _api.register(
        fullName: fullName,
        email: email,
        password: password,
      );
    } on DioException catch (e) {
      throw ApiException(
        _extractErrorMessage(e.response?.data, 'Registration failed'),
        statusCode: e.response?.statusCode,
      );
    }
  }

  Future<AuthUser?> restoreSession() async {
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        return null;
      }
      return await _api.me();
    } on DioException catch (e) {
      final code = e.response?.statusCode;
      if (code == 401 || code == 403) {
        await _tokenStorage.clear();
      }
      return null;
    }
  }

  Future<void> logout() => _tokenStorage.clear();
}
