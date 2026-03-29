import 'package:flutter/foundation.dart';

/// API base URL. Задаётся при сборке:
/// `flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000`
///
/// Без `--dart-define`: **Android (эмулятор)** → `http://10.0.2.2:8000`,
/// iOS / desktop / web → `http://127.0.0.1:8000`.
///
/// Другие среды (iOS-симулятор, desktop, браузер на этой же машине) при необходимости:
/// `--dart-define=API_BASE_URL=http://127.0.0.1:8000`
///
/// Физическое устройство в Wi‑Fi:
/// `--dart-define=API_BASE_URL=http://<LAN_IP_ПК>:8000`
///
/// Media URLs from the API must use a host reachable from this device (same as
/// the server’s public/base URL); otherwise [Image.network] will fail even if
/// paths are correct.
///
/// **Пустая главная / ошибка сети:** убедитесь, что по этому же origin отвечает
/// бэкенд (`GET /home`, `GET /listings`), в БД есть объявления со статусом
/// `active`, и с **физического телефона** задан LAN-IP ПК, а не только
/// `10.0.2.2` / `127.0.0.1`.
class Env {
  static const String _androidEmulatorHost = 'http://10.0.2.2:8000';
  static const String _loopbackHost = 'http://127.0.0.1:8000';

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
      return _loopbackHost;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidEmulatorHost;
      default:
        return _loopbackHost;
    }
  }
}
