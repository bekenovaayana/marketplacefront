class ErrorMapper {
  static String friendly(Object? error) {
    final text = (error ?? '').toString();
    final lower = text.toLowerCase();

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
    if (lower.contains('apiexception(')) {
      return text
          .replaceFirst(RegExp(r'^.*message:\s*'), '')
          .replaceAll(')', '')
          .trim();
    }
    return 'Something went wrong. Please try again.';
  }
}
