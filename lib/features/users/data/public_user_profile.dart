import 'package:marketplace_frontend/core/json/json_read.dart';

/// Public seller profile from **GET /users/{id}** (subset of fields; snake_case from API).
class PublicUserProfile {
  const PublicUserProfile({
    required this.id,
    required this.fullName,
    this.avatarUrl,
  });

  final int id;
  final String fullName;
  final String? avatarUrl;

  factory PublicUserProfile.fromJson(Map<String, dynamic> json) {
    return PublicUserProfile(
      id: JsonRead.intVal(json['id']),
      fullName: () {
        final name = JsonRead.string(
          json['full_name'] ?? json['fullName'] ?? json['name'],
        ).trim();
        return name.isEmpty ? '—' : name;
      }(),
      avatarUrl: _optionalUrl(json['avatar_url'] ?? json['avatarUrl']),
    );
  }

  static String? _optionalUrl(dynamic v) {
    final s = JsonRead.string(v).trim();
    return s.isEmpty ? null : s;
  }
}
