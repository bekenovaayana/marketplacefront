import 'package:json_annotation/json_annotation.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';

/// Optional nested user on a notification (`actor` may be null).
class NotificationActor {
  const NotificationActor({this.id, this.avatarUrl, this.fullName});

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'avatar_url')
  final String? avatarUrl;
  @JsonKey(name: 'full_name')
  final String? fullName;

  factory NotificationActor.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationActor();
    final av = JsonRead.string(json['avatar_url']);
    final fn = JsonRead.string(json['full_name']);
    return NotificationActor(
      id: JsonRead.intNullable(json['id']),
      avatarUrl: av.isEmpty ? null : av,
      fullName: fn.isEmpty ? null : fn,
    );
  }
}

/// Optional `listing` payload on notification (id / title may be null).
class NotificationListingRef {
  const NotificationListingRef({this.id, this.title});

  @JsonKey(name: 'id')
  final int? id;
  @JsonKey(name: 'title')
  final String? title;

  factory NotificationListingRef.fromJson(dynamic raw) {
    final m = JsonRead.map(raw);
    if (m == null) return const NotificationListingRef();
    final t = JsonRead.string(m['title']);
    return NotificationListingRef(
      id: JsonRead.intNullable(m['id']),
      title: t.isEmpty ? null : t,
    );
  }
}

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
    this.actorId,
    this.actor,
    this.listing,
  });

  @JsonKey(name: 'id')
  final int id;
  @JsonKey(name: 'user_id')
  final int userId;
  @JsonKey(name: 'notification_type')
  final String notificationType;
  @JsonKey(name: 'title')
  final String title;
  @JsonKey(name: 'body')
  final String body;
  @JsonKey(name: 'entity_type')
  final String? entityType;
  @JsonKey(name: 'entity_id')
  final int? entityId;
  @JsonKey(name: 'is_read')
  final bool isRead;
  @JsonKey(name: 'read_at')
  final DateTime? readAt;
  @JsonKey(name: 'created_at')
  final DateTime createdAt;
  @JsonKey(name: 'actor_id')
  final int? actorId;
  final NotificationActor? actor;
  final NotificationListingRef? listing;

  bool get isActionable => entityType != null && entityId != null;

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    final readAtRaw = json['read_at'];
    DateTime? readAt;
    if (readAtRaw is String) readAt = DateTime.tryParse(readAtRaw);

    final createdRaw = json['created_at'];
    DateTime createdAt = DateTime.now();
    if (createdRaw is String) {
      createdAt = DateTime.tryParse(createdRaw) ?? createdAt;
    }

    final actorMap = JsonRead.map(json['actor']);

    return NotificationModel(
      id: JsonRead.intVal(json['id']),
      userId: JsonRead.intVal(json['user_id']),
      notificationType: JsonRead.string(json['notification_type']),
      title: JsonRead.string(json['title']),
      body: JsonRead.string(json['body']),
      entityType: () {
        final s = JsonRead.string(json['entity_type']);
        return s.isEmpty ? null : s;
      }(),
      entityId: JsonRead.intNullable(json['entity_id']),
      isRead: JsonRead.boolVal(json['is_read']),
      readAt: readAt,
      createdAt: createdAt,
      actorId: JsonRead.intNullable(json['actor_id']),
      actor: actorMap == null ? null : NotificationActor.fromJson(actorMap),
      listing: NotificationListingRef.fromJson(json['listing']),
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
      actorId: actorId,
      actor: actor,
      listing: listing,
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
