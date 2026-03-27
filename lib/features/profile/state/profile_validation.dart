class ProfileValidation {
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Name is required';
    if (value.trim().length < 2) return 'Too short';
    return null;
  }

  /// Bio is optional: empty or whitespace only is valid.
  static String? validateBioOptional(String? value) => null;

  static String? validatePreferredLanguage(String? value) {
    final v = (value ?? '').trim().toLowerCase();
    if (v.isEmpty) return 'Language is required';
    if (v != 'en' && v != 'ru') return 'Language must be en or ru';
    return null;
  }

  static String normalizeKgPhoneInput(String input) {
    final digits = input.replaceAll(RegExp(r'\D'), '');
    var rest = digits;
    if (rest.startsWith('996')) {
      rest = rest.substring(3);
    }
    if (rest.length > 9) {
      rest = rest.substring(0, 9);
    }
    return '+996$rest';
  }

  /// Empty or prefix-only [+996] is allowed. If any national digits are present,
  /// full 9 digits after +996 are required.
  static String? validatePhoneOptional(String? value) {
    final raw = (value ?? '').trim();
    if (raw.isEmpty) return null;
    final normalized = normalizeKgPhoneInput(raw);
    final digitsAfter = normalized.length > 4 ? normalized.substring(4) : '';
    if (digitsAfter.isEmpty) return null;
    if (!RegExp(r'^\+996\d{9}$').hasMatch(normalized)) {
      return 'Phone must match +996XXXXXXXXX';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone is required';
    final v = value.trim();
    final ok = RegExp(r'^\+996\d{9}$').hasMatch(v);
    if (!ok) return 'Phone must match +996XXXXXXXXX';
    return null;
  }

  static String? validateNewPassword({
    required String current,
    required String next,
    required String confirm,
  }) {
    if (next.length < 8) return 'New password must be at least 8 characters.';
    if (next != confirm) return 'Password confirmation does not match.';
    if (next == current) return 'New password must be different from current.';
    return null;
  }
}
