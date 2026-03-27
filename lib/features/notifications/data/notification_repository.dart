import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_models.dart';

final notificationRepositoryProvider = Provider<NotificationRepository>((ref) {
  return NotificationRepository(ref.watch(dioProvider));
});

class NotificationRepository {
  NotificationRepository(this._dio);

  final Dio _dio;

  Future<PaginatedResponse<NotificationModel>> fetchNotifications({
    int page = 1,
    int pageSize = 20,
    bool unreadOnly = false,
  }) async {
    final response = await _dio.get(
      '/notifications',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
        'unread_only': unreadOnly,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaginatedResponse<NotificationModel>(
      items: items,
      page: (data['page'] as num?)?.toInt() ?? page,
      pageSize: (data['page_size'] as num?)?.toInt() ?? pageSize,
      totalPages: (data['total_pages'] as num?)?.toInt() ?? page,
      totalItems: (data['total_items'] as num?)?.toInt() ?? items.length,
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    final data = response.data as Map<String, dynamic>;
    return (data['unread_count'] as num?)?.toInt() ?? 0;
  }

  Future<void> markRead(int notificationId) async {
    await _dio.post('/notifications/$notificationId/read');
  }

  Future<int> markAllRead() async {
    final response = await _dio.post('/notifications/read-all');
    final data = response.data as Map<String, dynamic>;
    return (data['updated_count'] as num?)?.toInt() ?? 0;
  }
}
