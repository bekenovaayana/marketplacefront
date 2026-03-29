import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
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
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return PaginatedResponse<NotificationModel>(
        items: [],
        page: page,
        pageSize: pageSize,
        totalPages: page,
        totalItems: 0,
      );
    }
    final data = raw;
    final items = JsonRead.listOfMap(data['items'], NotificationModel.fromJson);
    final src = JsonRead.paginationSource(data);
    return PaginatedResponse<NotificationModel>(
      items: items,
      page: JsonRead.intVal(src['page'], page),
      pageSize: JsonRead.intVal(src['page_size'], pageSize),
      totalPages: JsonRead.intVal(src['total_pages'], page),
      totalItems: JsonRead.intVal(src['total_items'], items.length),
    );
  }

  Future<int> fetchUnreadCount() async {
    final response = await _dio.get('/notifications/unread-count');
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return 0;
    return JsonRead.intVal(raw['unread_count']);
  }

  Future<void> markRead(int notificationId) async {
    await _dio.post('/notifications/$notificationId/read');
  }

  Future<int> markAllRead() async {
    final response = await _dio.post('/notifications/read-all');
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return 0;
    return JsonRead.intVal(raw['updated_count']);
  }
}
