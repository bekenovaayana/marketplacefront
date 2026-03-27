import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/profile/data/profile_repository.dart';

void main() {
  group('ProfileRepository.mapProfileError', () {
    test('maps 400 current password error', () {
      expect(
        ProfileRepository.mapProfileError(400, null),
        'Current password is incorrect.',
      );
    });

    test('maps 413 avatar size error', () {
      expect(
        ProfileRepository.mapProfileError(413, null),
        'Avatar is too large. Maximum is 5MB.',
      );
    });

    test('maps 422 detail list', () {
      final result = ProfileRepository.mapProfileError(422, {
        'errors': [
          {'field': 'phone', 'message': 'Invalid phone'},
        ],
      });
      expect(result, 'Invalid phone');
    });
  });
}
