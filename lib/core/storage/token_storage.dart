import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  static const _tokenKey = 'access_token';
  static const _refreshKey = 'refresh_token';
  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _tokenKey);
  }

  /// Persist refresh token when the login response includes it; clears stored
  /// refresh when [token] is null or empty.
  Future<void> saveRefreshToken(String? token) async {
    final t = token?.trim();
    if (t == null || t.isEmpty) {
      await _storage.delete(key: _refreshKey);
      return;
    }
    await _storage.write(key: _refreshKey, value: t);
  }

  Future<String?> readRefreshToken() {
    return _storage.read(key: _refreshKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshKey);
  }
}
