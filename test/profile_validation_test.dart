import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/profile/state/profile_validation.dart';

void main() {
  group('ProfileValidation.validatePhone', () {
    test('accepts KG format only', () {
      expect(ProfileValidation.validatePhone('+996500123456'), isNull);
      expect(
        ProfileValidation.validatePhone('996500123456'),
        'Phone must match +996XXXXXXXXX',
      );
      expect(
        ProfileValidation.validatePhone('+99650012345'),
        'Phone must match +996XXXXXXXXX',
      );
    });
  });

  group('ProfileValidation.validatePhoneOptional', () {
    test('allows empty and prefix-only', () {
      expect(ProfileValidation.validatePhoneOptional(null), isNull);
      expect(ProfileValidation.validatePhoneOptional(''), isNull);
      expect(ProfileValidation.validatePhoneOptional('+996'), isNull);
      expect(ProfileValidation.validatePhoneOptional('+996 '), isNull);
    });

    test('requires full number when digits started', () {
      expect(
        ProfileValidation.validatePhoneOptional('+996500'),
        'Phone must match +996XXXXXXXXX',
      );
      expect(ProfileValidation.validatePhoneOptional('+996500123456'), isNull);
    });
  });

  group('ProfileValidation.validatePreferredLanguage', () {
    test('accepts en and ru only', () {
      expect(ProfileValidation.validatePreferredLanguage('en'), isNull);
      expect(ProfileValidation.validatePreferredLanguage('ru'), isNull);
      expect(
        ProfileValidation.validatePreferredLanguage('kg'),
        'Language must be en or ru',
      );
    });
  });

  group('ProfileValidation.validateNewPassword', () {
    test('requires minimum 8 chars', () {
      final result = ProfileValidation.validateNewPassword(
        current: 'old-pass-123',
        next: 'short',
        confirm: 'short',
      );
      expect(result, 'New password must be at least 8 characters.');
    });

    test('requires confirm match', () {
      final result = ProfileValidation.validateNewPassword(
        current: 'old-pass-123',
        next: 'new-password',
        confirm: 'different',
      );
      expect(result, 'Password confirmation does not match.');
    });

    test('requires new password differ from current', () {
      final result = ProfileValidation.validateNewPassword(
        current: 'same-password',
        next: 'same-password',
        confirm: 'same-password',
      );
      expect(result, 'New password must be different from current.');
    });
  });
}
