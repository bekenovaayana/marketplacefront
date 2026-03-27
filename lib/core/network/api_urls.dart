import 'package:marketplace_frontend/core/config/env.dart';

class ApiUrls {
  ApiUrls._();

  /// Resolves listing/media paths from API relative to absolute URL.
  static String absoluteUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final base = Env.baseUrl.replaceAll(RegExp(r'/$'), '');
    final suffix = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$suffix';
  }
}
