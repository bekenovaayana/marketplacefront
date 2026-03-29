/// FastAPI `detail`: string, or list of `{ loc, msg, type }`.
String? messageFromFastApiDetail(dynamic detail) {
  if (detail == null) return null;
  if (detail is String && detail.trim().isNotEmpty) return detail.trim();
  if (detail is List<dynamic>) {
    final parts = <String>[];
    for (final e in detail) {
      if (e is Map<String, dynamic>) {
        final msg = e['msg']?.toString().trim();
        if (msg != null && msg.isNotEmpty) parts.add(msg);
      }
    }
    if (parts.isNotEmpty) return parts.join('\n');
  }
  if (detail is Map<String, dynamic>) {
    final m = detail['message']?.toString().trim();
    if (m != null && m.isNotEmpty) return m;
  }
  return null;
}
