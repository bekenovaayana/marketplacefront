/// Defensive reads for FastAPI / older backends (null, wrong types, stringified numbers).
///
/// Prefer matching API snake_case keys at the call site; this file does not use
/// code generation — see field comments on models for `@JsonKey`-equivalent names.
class JsonRead {
  JsonRead._();

  static int intVal(dynamic v, [int fallback = 0]) {
    if (v == null) return fallback;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static int? intNullable(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v.trim());
    return null;
  }

  static double doubleVal(dynamic v, [double fallback = 0]) {
    if (v == null) return fallback;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim()) ?? fallback;
    return fallback;
  }

  static double? doubleNullable(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v.trim());
    return null;
  }

  /// `price` may be int or double from JSON.
  static double price(dynamic v, [double fallback = 0]) => doubleVal(v, fallback);

  static String string(dynamic v, [String fallback = '']) {
    if (v == null) return fallback;
    if (v is String) return v;
    return v.toString();
  }

  static bool boolVal(dynamic v, [bool fallback = false]) {
    if (v == null) return fallback;
    if (v is bool) return v;
    if (v is String) {
      final s = v.toLowerCase().trim();
      if (s == 'true' || s == '1') return true;
      if (s == 'false' || s == '0') return false;
    }
    if (v is num) return v != 0;
    return fallback;
  }

  static Map<String, dynamic>? map(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static List<T> listOfMap<T>(
    dynamic raw,
    T Function(Map<String, dynamic> m) parse,
  ) {
    if (raw is! List<dynamic>) return [];
    final out = <T>[];
    for (final e in raw) {
      final m = map(e);
      if (m != null) out.add(parse(m));
    }
    return out;
  }

  /// Paged envelope or a raw JSON array (`items` / `results` / `data` / nested maps).
  static List<dynamic> paginatedListItems(dynamic raw) {
    if (raw is List<dynamic>) return raw;
    if (raw is! Map<String, dynamic>) return const [];
    dynamic items =
        raw['items'] ?? raw['results'] ?? raw['data'] ?? raw['conversations'];
    if (items is List<dynamic>) return items;
    if (items is Map<String, dynamic>) {
      final inner = items['items'] ?? items['results'];
      if (inner is List<dynamic>) return inner;
    }
    final data = raw['data'];
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      final inner = data['items'] ?? data['results'];
      if (inner is List<dynamic>) return inner;
    }
    return const [];
  }

  /// Pagination: read `meta` first, else same keys on the root object.
  static Map<String, dynamic> paginationSource(Map<String, dynamic> data) {
    return map(data['meta']) ?? data;
  }
}
