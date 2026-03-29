import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/json/json_read.dart';
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

  /// Optional: existing thread for this listing (buyer). **404** → no thread yet.
  Future<ConversationOpenResult?> getConversationByListing(int listingId) async {
    try {
      final response = await _dio.get<dynamic>('/conversations/by-listing/$listingId');
      final data = response.data;
      if (data is Map<String, dynamic>) {
        return ConversationOpenResult.fromJson(data);
      }
      return null;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      rethrow;
    }
  }

  /// Create or resume buyer↔seller chat for a listing (**not** for the owner’s own ad — **400**).
  Future<ConversationOpenResult> createConversationFromListing(int listingId) async {
    try {
      final response = await _dio.post<dynamic>(
        '/conversations/from-listing',
        data: {
          'listing_id': listingId,
          'listingId': listingId,
        },
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const ApiException('Invalid conversation response');
      }
      final result = ConversationOpenResult.fromJson(data);
      if (result.conversationId <= 0) {
        throw const ApiException('Invalid conversation response');
      }
      return result;
    } on DioException catch (e) {
      final msg = _extractDetail(e);
      throw ApiException(
        msg ?? 'Could not open chat',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Classifieds flow: **GET by-listing** then **POST from-listing** on **404**.
  Future<ConversationOpenResult> openConversationForListingAsBuyer(int listingId) async {
    final existing = await getConversationByListing(listingId);
    if (existing != null && existing.conversationId > 0) {
      return existing;
    }
    return createConversationFromListing(listingId);
  }

  static String? _extractDetail(DioException e) {
    final data = e.response?.data;
    if (data is Map<String, dynamic>) {
      final detail = data['detail'];
      if (detail is String && detail.isNotEmpty) return detail;
    }
    return null;
  }

  Future<List<Conversation>> listConversations({
    int page = 1,
    int pageSize = 20,
  }) async {
    final response = await _dio.get<dynamic>(
      '/conversations',
      queryParameters: {
        'page': page,
        'page_size': pageSize,
      },
    );
    final raw = response.data;
    if (raw is! Map<String, dynamic>) return [];
    final items = raw['items'] ?? raw['results'] ?? raw['conversations'];
    return JsonRead.listOfMap(items, Conversation.fromJson);
  }

  /// Latest chunk: **order=desc**; reversed to chronological **[oldest → newest]** for UI.
  /// Tries **GET /messages/{id}** first, then **GET /conversations/{id}/messages** (same query).
  Future<List<ConversationMessage>> listMessages(
    int conversationId, {
    int page = 1,
    int pageSize = 50,
  }) async {
    final qp = <String, dynamic>{
      'order': 'desc',
      'page_size': pageSize,
      if (page > 1) 'page': page,
    };
    Response<dynamic> response;
    try {
      response = await _dio.get<dynamic>(
        '/messages/$conversationId',
        queryParameters: qp,
      );
    } on DioException catch (e) {
      final c = e.response?.statusCode;
      if (c == 404 || c == 405) {
        response = await _dio.get<dynamic>(
          '/conversations/$conversationId/messages',
          queryParameters: qp,
        );
      } else {
        rethrow;
      }
    }
    final data = response.data;
    final items = _messageItemsPayload(data);
    final parsed = JsonRead.listOfMap(items, ConversationMessage.fromJson);
    if (parsed.length <= 1) return parsed;
    return parsed.reversed.toList();
  }

  static dynamic _messageItemsPayload(dynamic data) {
    if (data is List<dynamic>) return data;
    if (data is Map<String, dynamic>) {
      return data['items'] ?? data['messages'] ?? data['results'];
    }
    return const [];
  }

  String buildIdempotencyKey() => _uuid.v4();

  /// Returns the created message when the response body includes it (with `is_mine`).
  Future<ConversationMessage?> sendMessage({
    required int conversationId,
    String? text,
    List<MessageAttachmentCreate> attachments = const [],
    String? idempotencyKey,
  }) async {
    final requestId = idempotencyKey ?? buildIdempotencyKey();
    final normalized = text?.trim();
    final body = <String, dynamic>{
      'conversation_id': conversationId,
      if (normalized != null && normalized.isNotEmpty) 'text_body': normalized,
      if (attachments.isNotEmpty) 'attachments': attachments.map((e) => e.toJson()).toList(),
      'client_message_id': requestId,
    };
    final response = await _dio.post<dynamic>(
      '/messages',
      data: body,
      options: Options(headers: {'Idempotency-Key': requestId}),
    );
    return parseMessageFromPostResponse(response.data);
  }

  /// Accepts raw message JSON or `{ "message": { ... } }` / similar wrappers.
  static ConversationMessage? parseMessageFromPostResponse(dynamic data) {
    if (data == null) return null;
    if (data is! Map) return null;
    final root = JsonRead.map(data);
    if (root == null) return null;
    final hasBody = root.containsKey('text_body') ||
        root.containsKey('content') ||
        root.containsKey('text');
    final id = JsonRead.intVal(root['id']);
    if (hasBody && (id != 0 || root.containsKey('is_mine') || root.containsKey('isMine'))) {
      return ConversationMessage.fromJson(root);
    }
    for (final key in ['message', 'data', 'item', 'payload']) {
      final nested = JsonRead.map(root[key]);
      if (nested == null) continue;
      final nHas = nested.containsKey('text_body') ||
          nested.containsKey('content') ||
          nested.containsKey('text');
      final nid = JsonRead.intVal(nested['id']);
      if (nHas && (nid != 0 || nested.containsKey('is_mine') || nested.containsKey('isMine'))) {
        return ConversationMessage.fromJson(nested);
      }
    }
    return null;
  }

  /// **204** / empty body is OK.
  Future<void> markConversationRead(int conversationId) async {
    final response = await _dio.post<dynamic>('/messages/$conversationId/mark-read');
    final data = response.data;
    if (data is Map<String, dynamic>) {
      MarkReadResponseDto.fromJson(data);
    }
  }

  Future<UnreadSummaryDto> getUnreadSummary() async {
    final response = await _dio.get<dynamic>('/chats/unread-summary');
    final raw = response.data;
    if (raw is! Map<String, dynamic>) {
      return const UnreadSummaryDto(totalUnread: 0, byConversation: []);
    }
    return UnreadSummaryDto.fromJson(raw);
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
