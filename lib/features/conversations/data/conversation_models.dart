import 'package:marketplace_frontend/core/json/json_read.dart';

/// Counterparty for chat header / list row (API `peer` on open-from-listing).
class ConversationPeer {
  const ConversationPeer({
    this.id,
    this.fullName,
    this.avatarUrl,
  });

  final int? id;
  final String? fullName;
  final String? avatarUrl;

  String get displayName =>
      (fullName != null && fullName!.trim().isNotEmpty) ? fullName!.trim() : 'Chat';

  factory ConversationPeer.fromJson(Map<String, dynamic> json) {
    final name = JsonRead.string(json['full_name'] ?? json['fullName'] ?? json['name']).trim();
    final av = JsonRead.string(json['avatar_url'] ?? json['avatarUrl']).trim();
    return ConversationPeer(
      id: JsonRead.intNullable(json['id']),
      fullName: name.isEmpty ? null : name,
      avatarUrl: av.isEmpty ? null : av,
    );
  }
}

/// Result of [GET /conversations/by-listing] or [POST /conversations/from-listing].
class ConversationOpenResult {
  const ConversationOpenResult({
    required this.conversationId,
    this.peer,
  });

  final int conversationId;
  final ConversationPeer? peer;

  factory ConversationOpenResult.fromJson(Map<String, dynamic> json) {
    var id = JsonRead.intVal(json['id']);
    if (id == 0) {
      id = JsonRead.intVal(json['conversation_id']);
    }
    if (id == 0) {
      final nested = JsonRead.map(json['conversation']);
      if (nested != null) {
        id = JsonRead.intVal(nested['id']);
      }
    }
    final peerMap = JsonRead.map(json['peer']);
    return ConversationOpenResult(
      conversationId: id,
      peer: peerMap != null ? ConversationPeer.fromJson(peerMap) : null,
    );
  }
}

class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    this.listingTitle,
    this.listingPrice,
    this.listingCurrency,
    this.listingImageUrl,
    this.peerName,
    this.peerAvatarUrl,
  });

  final int id;
  final String title;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? listingTitle;
  final double? listingPrice;
  final String? listingCurrency;
  final String? listingImageUrl;
  final String? peerName;
  final String? peerAvatarUrl;

  String get displayTitle {
    if (peerName != null && peerName!.trim().isNotEmpty) {
      return peerName!.trim();
    }
    return title.trim().isEmpty ? 'Chat' : title;
  }

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final peerMap = JsonRead.map(json['peer']);
    final peer = peerMap != null ? ConversationPeer.fromJson(peerMap) : null;
    final peerName = peer?.fullName ??
        (JsonRead.string(json['peer_name'] ?? json['peerName']).trim().isEmpty
            ? null
            : JsonRead.string(json['peer_name'] ?? json['peerName']));
    final peerAvatarUrl = peer?.avatarUrl ??
        (JsonRead.string(json['peer_avatar_url'] ?? json['peerAvatarUrl']).trim().isEmpty
            ? null
            : JsonRead.string(json['peer_avatar_url'] ?? json['peerAvatarUrl']));

    final userA = JsonRead.string(json['participant_a_name']);
    final userB = JsonRead.string(json['participant_b_name']);
    final fallbackTitle = JsonRead.string(json['title']);
    final title = (peerName != null && peerName.isNotEmpty)
        ? peerName
        : (fallbackTitle.isNotEmpty
            ? fallbackTitle
            : (userA.isNotEmpty ? userA : userB));

    String? listingTitle;
    double? listingPrice;
    String? listingCurrency;
    String? listingImageUrl;
    final listing = JsonRead.map(json['listing']);
    if (listing != null) {
      listingTitle = JsonRead.string(listing['title']).trim().isEmpty
          ? null
          : JsonRead.string(listing['title']);
      listingPrice = JsonRead.doubleNullable(listing['price']);
      listingCurrency = JsonRead.string(listing['currency']).trim().isEmpty
          ? null
          : JsonRead.string(listing['currency']);
      listingImageUrl = JsonRead.string(
        listing['image_url'] ?? listing['primary_image'] ?? listing['cover_url'],
      ).trim().isEmpty
          ? null
          : JsonRead.string(
              listing['image_url'] ?? listing['primary_image'] ?? listing['cover_url'],
            );
    }
    listingTitle ??= JsonRead.string(json['listing_title'] ?? json['listingTitle']).trim().isEmpty
        ? null
        : JsonRead.string(json['listing_title'] ?? json['listingTitle']);
    listingPrice ??= JsonRead.doubleNullable(json['listing_price'] ?? json['listingPrice']);
    listingCurrency ??=
        JsonRead.string(json['listing_currency'] ?? json['listingCurrency']).trim().isEmpty
            ? null
            : JsonRead.string(json['listing_currency'] ?? json['listingCurrency']);
    listingImageUrl ??=
        JsonRead.string(json['listing_image_url'] ?? json['listing_image'] ?? json['listingImageUrl'])
                .trim()
                .isEmpty
            ? null
            : JsonRead.string(
                json['listing_image_url'] ?? json['listing_image'] ?? json['listingImageUrl'],
              );

    return Conversation(
      id: JsonRead.intVal(json['id']),
      title: title.isEmpty ? 'Chat' : title,
      lastMessagePreview: JsonRead.string(
        json['last_message_text'] ??
            json['last_message_preview'] ??
            json['last_message_body'] ??
            json['last_message'] ??
            json['last_message_content'],
      ),
      lastMessageAt: DateTime.tryParse(
        JsonRead.string(json['last_message_at'] ?? json['last_message_created_at']),
      ),
      unreadCount: JsonRead.intVal(json['unread_count'] ?? json['unreadCount']),
      listingTitle: listingTitle,
      listingPrice: listingPrice,
      listingCurrency: listingCurrency,
      listingImageUrl: listingImageUrl,
      peerName: peerName,
      peerAvatarUrl: peerAvatarUrl,
    );
  }

  Conversation copyWith({
    int? unreadCount,
  }) {
    return Conversation(
      id: id,
      title: title,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      listingTitle: listingTitle,
      listingPrice: listingPrice,
      listingCurrency: listingCurrency,
      listingImageUrl: listingImageUrl,
      peerName: peerName,
      peerAvatarUrl: peerAvatarUrl,
    );
  }
}

class ConversationMessage {
  const ConversationMessage({
    required this.id,
    required this.senderId,
    required this.text,
    required this.sentAt,
    this.attachments = const [],
    /// From API `is_mine` / `isMine` (false when the key is absent).
    required this.isMine,
    /// Whether the JSON included `is_mine` / `isMine`. If true, [isMine] wins over sender heuristics.
    this.serverSentIsMineFlag = false,
  });

  final int id;
  final int senderId;
  final String text;
  final DateTime sentAt;
  final List<MessageAttachment> attachments;
  final bool isMine;
  final bool serverSentIsMineFlag;

  /// Row alignment: optimistic id; else explicit server [isMine]; else [senderId] vs [currentUserId].
  bool layoutIsMine(int? currentUserId) {
    if (id < 0) return true;
    if (serverSentIsMineFlag) return isMine;
    if (currentUserId != null && senderId != 0 && senderId == currentUserId) {
      return true;
    }
    return false;
  }

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    final hasFlag = json.containsKey('is_mine') || json.containsKey('isMine');
    return ConversationMessage(
      id: JsonRead.intVal(json['id']),
      senderId: JsonRead.intVal(json['sender_id'] ?? json['senderId']),
      text: JsonRead.string(
        json['text_body'] ?? json['content'] ?? json['text'],
      ),
      sentAt: DateTime.tryParse(JsonRead.string(json['sent_at'] ?? json['created_at'])) ??
          DateTime.now(),
      attachments: JsonRead.listOfMap(json['attachments'], MessageAttachment.fromJson),
      isMine: JsonRead.boolVal(json['is_mine'] ?? json['isMine']),
      serverSentIsMineFlag: hasFlag,
    );
  }
}

class AttachmentUploadResult {
  const AttachmentUploadResult({
    required this.url,
    required this.originalName,
    required this.contentType,
    required this.sizeBytes,
  });

  final String url;
  final String originalName;
  final String contentType;
  final int sizeBytes;

  factory AttachmentUploadResult.fromJson(Map<String, dynamic> json) {
    return AttachmentUploadResult(
      url: JsonRead.string(json['url']),
      originalName: JsonRead.string(json['original_name']),
      contentType: JsonRead.string(json['content_type']),
      sizeBytes: JsonRead.intVal(json['size_bytes']),
    );
  }
}

class MessageAttachment {
  const MessageAttachment({
    required this.id,
    required this.messageId,
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.fileUrl,
  });

  final int id;
  final int messageId;
  final String fileName;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final String fileUrl;

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: JsonRead.intVal(json['id']),
      messageId: JsonRead.intVal(json['message_id']),
      fileName: JsonRead.string(json['file_name']),
      originalName: JsonRead.string(json['original_name']),
      mimeType: JsonRead.string(json['mime_type']),
      fileSize: JsonRead.intVal(json['file_size']),
      fileUrl: JsonRead.string(json['file_url']),
    );
  }
}

class MessageAttachmentCreate {
  const MessageAttachmentCreate({
    required this.fileName,
    required this.originalName,
    required this.mimeType,
    required this.fileSize,
    required this.fileUrl,
  });

  final String fileName;
  final String originalName;
  final String mimeType;
  final int fileSize;
  final String fileUrl;

  Map<String, dynamic> toJson() {
    return {
      'file_name': fileName,
      'original_name': originalName,
      'mime_type': mimeType,
      'file_size': fileSize,
      'file_url': fileUrl,
    };
  }
}

class UnreadConversationItem {
  const UnreadConversationItem({
    required this.conversationId,
    required this.unreadCount,
  });

  final int conversationId;
  final int unreadCount;

  factory UnreadConversationItem.fromJson(Map<String, dynamic> json) {
    return UnreadConversationItem(
      conversationId: JsonRead.intVal(json['conversation_id'] ?? json['conversationId']),
      unreadCount: JsonRead.intVal(json['unread_count'] ?? json['unreadCount']),
    );
  }
}

class UnreadSummaryDto {
  const UnreadSummaryDto({
    required this.totalUnread,
    this.byConversation = const [],
  });

  final int totalUnread;
  final List<UnreadConversationItem> byConversation;

  factory UnreadSummaryDto.fromJson(Map<String, dynamic> json) {
    final rawList = json['by_conversation'] ??
        json['byConversation'] ??
        json['conversations'] ??
        json['items'];
    return UnreadSummaryDto(
      totalUnread: JsonRead.intVal(
        json['total_unread'] ?? json['totalUnread'] ?? json['unread_total'],
      ),
      byConversation: JsonRead.listOfMap(rawList, UnreadConversationItem.fromJson),
    );
  }
}

class MarkReadResponseDto {
  const MarkReadResponseDto({
    required this.detail,
    required this.updatedCount,
  });

  final String detail;
  final int updatedCount;

  factory MarkReadResponseDto.fromJson(Map<String, dynamic> json) {
    return MarkReadResponseDto(
      detail: JsonRead.string(json['detail']),
      updatedCount: JsonRead.intVal(json['updated_count'] ?? json['updatedCount']),
    );
  }
}
