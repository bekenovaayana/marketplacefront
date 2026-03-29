import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/users/data/public_user_profile.dart';

final usersApiProvider = Provider<UsersApi>((ref) {
  return UsersApi(ref.watch(dioProvider));
});

class UsersApi {
  UsersApi(this._dio);

  final Dio _dio;

  Future<PublicUserProfile> getUser(int id) async {
    final response = await _dio.get<dynamic>('/users/$id');
    final data = response.data;
    if (data is! Map<String, dynamic>) {
      throw StateError('GET /users/$id: expected JSON object');
    }
    return PublicUserProfile.fromJson(data);
  }

  /// Block user (**POST** /users/{id}/block).
  Future<void> blockUser(int userId) async {
    await _dio.post<void>('/users/$userId/block');
  }
}
