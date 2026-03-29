import 'package:dio/dio.dart';

/// Coalesces overlapping profile fetches (login + profile tab) onto one HTTP round-trip.
class UsersMeDedupe {
  static Future<Map<String, dynamic>>? _inFlight;

  static Future<Map<String, dynamic>> fetch(Dio dio) {
    final existing = _inFlight;
    if (existing != null) return existing;
    final flight = _fetchImpl(dio);
    _inFlight = flight;
    flight.whenComplete(() {
      if (identical(_inFlight, flight)) {
        _inFlight = null;
      }
    });
    return flight;
  }

  static Future<Map<String, dynamic>> _fetchImpl(Dio dio) async {
    try {
      final response = await dio.get<dynamic>('/users/me');
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw StateError('GET /users/me: expected JSON object');
      }
      return data;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        final response = await dio.get<dynamic>('/auth/me');
        final data = response.data;
        if (data is! Map<String, dynamic>) {
          throw StateError('GET /auth/me: expected JSON object');
        }
        return data;
      }
      rethrow;
    }
  }
}
