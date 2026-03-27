import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorage {
  TokenStorage(this._storage);

  static const _tokenKey = 'access_token';
  final FlutterSecureStorage _storage;

  Future<void> saveAccessToken(String token) {
    return _storage.write(key: _tokenKey, value: token);
  }

  Future<String?> readAccessToken() {
    return _storage.read(key: _tokenKey);
  }

  Future<void> clear() {
    return _storage.delete(key: _tokenKey);
  }
}
