import 'package:flutter/foundation.dart';

/// API base URL. Set at build time, e.g.
/// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
///
/// Typical values:
/// - Android emulator → `http://10.0.2.2:8000` (default here)
/// - iOS simulator / desktop → `http://127.0.0.1:8000`
/// - Physical device on LAN → `http://<your_PC_LAN_IP>:8000`
///
/// Media URLs from the API must use a host reachable from this device (same as
/// the server’s public/base URL); otherwise [Image.network] will fail even if
/// paths are correct.
///
/// **Пустая главная / ошибка сети:** убедитесь, что по этому же origin отвечает
/// бэкенд (`GET /home`, `GET /listings`), в БД есть объявления со статусом
/// `active`, и с **физического телефона** задан LAN-IP ПК, а не `127.0.0.1` /
/// `10.0.2.2`.
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
