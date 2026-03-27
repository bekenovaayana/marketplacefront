class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.notificationType,
    required this.title,
    required this.body,
    required this.entityType,
    required this.entityId,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  final int id;
  final int userId;
  final String notificationType;
  final String title;
  final String body;
  final String? entityType;
  final int? entityId;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  bool get isActionable => entityType != null && entityId != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      userId: (json['user_id'] as num?)?.toInt() ?? 0,
      notificationType: json['notification_type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      entityType: json['entity_type'] as String?,
      entityId: (json['entity_id'] as num?)?.toInt(),
      isRead: json['is_read'] as bool? ?? false,
      readAt: DateTime.tryParse(json['read_at'] as String? ?? ''),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  NotificationModel copyWith({
    bool? isRead,
    DateTime? readAt,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      notificationType: notificationType,
      title: title,
      body: body,
      entityType: entityType,
      entityId: entityId,
      isRead: isRead ?? this.isRead,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt,
    );
  }
}

class PaginatedResponse<T> {
  const PaginatedResponse({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.totalPages,
    required this.totalItems,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int totalPages;
  final int totalItems;
}
