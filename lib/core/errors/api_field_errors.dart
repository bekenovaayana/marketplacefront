/// Represents field-level validation errors returned by the API
/// (FastAPI 422 Unprocessable Entity format).
class ApiFieldErrorsException implements Exception {
  const ApiFieldErrorsException(
    this.errors, {
    this.rawMessage,
  });

  /// Map of field path → error message.
  final Map<String, String> errors;

  /// Optional top-level message from the API (e.g. draft incomplete).
  final String? rawMessage;

  /// Alias expected by [PostingController] / UI layers.
  Map<String, String> get fieldErrors => errors;

  @override
  String toString() => 'ApiFieldErrorsException($errors)';
}

/// Attempts to parse a FastAPI 422 `detail` payload (list of `loc`/`msg`
/// objects) into an [ApiFieldErrorsException].  Returns `null` if the
/// response body does not match that format.
ApiFieldErrorsException? tryApiFieldErrorsFromResponse(dynamic data) {
  if (data is! Map<String, dynamic>) return null;
  final detail = data['detail'];
  if (detail is! List<dynamic>) return null;
  final errors = <String, String>{};
  for (final item in detail) {
    if (item is! Map<String, dynamic>) continue;
    final loc = item['loc'];
    final msg = item['msg'];
    if (loc is! List<dynamic> || msg is! String) continue;
    // Skip generic "body" / "value" prefixes; keep the last meaningful key.
    final field = loc
        .where((e) => e != 'body' && e != 'value')
        .map((e) => e.toString())
        .join('.');
    if (field.isEmpty) continue;
    errors[field] = msg;
  }
  if (errors.isEmpty) return null;
  return ApiFieldErrorsException(errors);
}

/// Extracts a human-readable error string from common FastAPI error shapes.
///
/// Handles:
///  * `{ "detail": "string message" }`
///  * `{ "detail": { "message": "..." } }`
///  * `{ "message": "string message" }`
String? parseApiDetailString(Map<String, dynamic> data) {
  final detail = data['detail'];
  if (detail is String) return detail;
  if (detail is Map<String, dynamic>) {
    final msg = detail['message'];
    if (msg is String) return msg;
  }
  final msg = data['message'];
  if (msg is String) return msg;
  return null;
}
