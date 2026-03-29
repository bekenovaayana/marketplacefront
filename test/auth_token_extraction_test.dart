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

  group('AuthRepository.extractRefreshToken', () {
    test('reads refresh_token', () {
      expect(
        AuthRepository.extractRefreshToken({
          'refresh_token': ' r1 ',
        }),
        'r1',
      );
    });

    test('reads refreshToken alias', () {
      expect(
        AuthRepository.extractRefreshToken({'refreshToken': 'r2'}),
        'r2',
      );
    });

    test('returns null when absent', () {
      expect(AuthRepository.extractRefreshToken({}), isNull);
    });
  });
}
