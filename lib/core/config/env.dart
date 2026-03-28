import 'package:flutter/foundation.dart';

/// API base URL. Set at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
class Env {
  static const String _apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  // Backward-compatible fallback for older local commands.
  static const String _legacyViteApiUrl = String.fromEnvironment(
    'VITE_API_URL',
    defaultValue: '',
  );

  static String get baseUrl {
    final fromDefine = _apiBaseUrl.trim().isNotEmpty ? _apiBaseUrl.trim() : _legacyViteApiUrl.trim();
    if (fromDefine.isNotEmpty) {
      return fromDefine.replaceAll(RegExp(r'/$'), '');
    }
    if (kIsWeb) {
      return 'http://127.0.0.1:8000';
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'http://10.0.2.2:8000';
      default:
        return 'http://127.0.0.1:8000';
    }
  }
}
