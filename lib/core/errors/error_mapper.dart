class ErrorMapper {
  static String friendly(Object? error) {
    final text = (error ?? '').toString();
    final lower = text.toLowerCase();

    // Dio бросает многострочное описание; `^.*message:` не срабатывает — ловим 500 раньше.
    if (lower.contains('status code of 500') ||
        lower.contains('status: 500') ||
        (lower.contains('apiexception') && lower.contains('500'))) {
      return 'Сервер временно недоступен. Попробуйте позже.';
    }

    if (lower.contains('socketexception') ||
        lower.contains('failed host lookup') ||
        lower.contains('connection error')) {
      return 'No internet connection. Please check network and retry.';
    }
    if (lower.contains('timeout')) {
      return 'Request timed out. Please try again.';
    }
    if (lower.contains('401') || lower.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }
    if (lower.contains('403')) {
      return 'You do not have permission for this action.';
    }
    if (lower.contains('404')) {
      return 'Requested data was not found.';
    }
    if (lower.contains('409')) {
      return 'Request conflict. Please review and try again.';
    }
    if (lower.contains('413')) {
      return 'File is too large. Maximum size is 64MB.';
    }
    if (lower.contains('415')) {
      return 'Unsupported file format. Use jpg, png, or webp.';
    }
    if (lower.contains('422')) {
      return 'Validation failed. Please check the entered data.';
    }
    if (lower.contains('apiexception')) {
      final m =
          RegExp(r'message:\s*([^\)\n]+)', caseSensitive: false).firstMatch(text);
      if (m != null) {
        final inner = m.group(1)?.trim();
        if (inner != null && inner.isNotEmpty) {
          return inner;
        }
      }
    }
    return 'Something went wrong. Please try again.';
  }
}
