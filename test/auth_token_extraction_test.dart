import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/auth/data/auth_repository.dart';

void main() {
  group('AuthRepository.extractAccessToken', () {
    test('uses access_token when present', () {
      final token = AuthRepository.extractAccessToken({
        'access_token': 'primary',
        'token': 'fallback',
      });
      expect(token, 'primary');
    });

    test('falls back to token alias', () {
      final token = AuthRepository.extractAccessToken({
        'token': 'alias-token',
      });
      expect(token, 'alias-token');
    });
  });
}
