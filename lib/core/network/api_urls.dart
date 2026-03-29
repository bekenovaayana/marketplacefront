import 'package:marketplace_frontend/core/config/env.dart';

class ApiUrls {
  ApiUrls._();

  /// Configured API origin without trailing slash (same host the app uses for
  /// JSON). Use for legacy relative media paths only; prefer absolute URLs from
  /// the backend when available.
  static String get apiBaseOrigin =>
      Env.baseUrl.replaceAll(RegExp(r'/$'), '');

  /// Resolves a media URL for [Image.network] / [NetworkImage].
  ///
  /// - Absolute `http://` / `https://` from the API → returned unchanged (no
  ///   `file://`, no extra base).
  /// - Legacy relative paths (e.g. `/uploads/...`) → joined with
  ///   [apiBaseOrigin] without duplicating slashes.
  /// - `file:` → empty (invalid for network images).
  static String resolveMediaUrl(String? path) {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.toLowerCase().startsWith('file:')) return '';
    // Absolute URL: `http://` / `https://` (case-insensitive; `https` matches `http` prefix check too).
    if (trimmed.toLowerCase().startsWith('http')) return trimmed;
    final base = apiBaseOrigin;
    final suffix = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$suffix';
  }

  /// Same as [resolveMediaUrl]; kept for call-site clarity.
  static String networkImageUrl(String? path) => resolveMediaUrl(path);

  /// Same as [resolveMediaUrl]; use for avatars from `avatar_url`.
  static String avatarUrlForDisplay(String? url) => resolveMediaUrl(url);

  /// Alias for [resolveMediaUrl] (e.g. opening files in the browser).
  static String absoluteUrl(String? path) => resolveMediaUrl(path);
}
