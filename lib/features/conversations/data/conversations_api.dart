import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:uuid/uuid.dart';

final conversationsApiProvider = Provider<ConversationsApi>((ref) {
  return ConversationsApi(ref.watch(dioProvider));
});

class ConversationsApi {
  ConversationsApi(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  Future<int> createConversation({
    required int otherUserId,
    int? listingId,
  }) async {
    final response = await _dio.post(
      '/conversations',
      data: {
        'other_user_id': otherUserId,
        'recipient_id': otherUserId,
        'listing_id': listingId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return (data['id'] as num?)?.toInt() ?? 0;
  }

  Future<List<Conversation>> listConversations({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get(
      '/conversations',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items.map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<ConversationMessage>> listMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final response = await _dio.get(
      '/messages/$conversationId',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final data = response.data as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? []);
    return items
        .map((e) => ConversationMessage.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  String buildIdempotencyKey() => _uuid.v4();

  Future<void> sendMessage({
    required int conversationId,
    String? text,
    List<MessageAttachmentCreate> attachments = const [],
    String? idempotencyKey,
  }) async {
    final requestId = idempotencyKey ?? buildIdempotencyKey();
    final normalized = text?.trim();
    await _dio.post(
      '/messages',
      data: {
        'conversation_id': conversationId,
        'content': normalized,
        'text_body': normalized,
        'attachments': attachments.map((e) => e.toJson()).toList(),
        'client_message_id': requestId,
      },
      options: Options(headers: {'Idempotency-Key': requestId}),
    );
  }

  Future<MarkReadResponseDto> markConversationRead(int conversationId) async {
    final response = await _dio.post('/messages/$conversationId/mark-read');
    return MarkReadResponseDto.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UnreadSummaryDto> getUnreadSummary() async {
    final response = await _dio.get('/chats/unread-summary');
    return UnreadSummaryDto.fromJson(response.data as Map<String, dynamic>);
  }

  String mapAttachmentUploadError(DioException e) {
    final code = e.response?.statusCode;
    if (code == 413) return 'File too large (max 20 MB)';
    if (code == 415) return 'Unsupported file type';
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
      if (detail is Map<String, dynamic>) {
        final message = detail['message']?.toString();
        if (message != null && message.isNotEmpty) return message;
      }
    } else if (data is String && data.isNotEmpty) {
      try {
        final parsed = jsonDecode(data);
        if (parsed is Map<String, dynamic>) {
          final detail = parsed['detail']?.toString();
          if (detail != null && detail.isNotEmpty) return detail;
        }
      } catch (_) {}
    }
    return 'Upload failed, tap to retry';
  }
}
