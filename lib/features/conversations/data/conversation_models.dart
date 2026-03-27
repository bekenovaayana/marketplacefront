class Conversation {
  const Conversation({
    required this.id,
    required this.title,
    required this.lastMessagePreview,
    required this.lastMessageAt,
    required this.unreadCount,
    this.listingTitle,
    this.listingPrice,
    this.listingImageUrl,
  });

  final int id;
  final String title;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;
  final String? listingTitle;
  final double? listingPrice;
  final String? listingImageUrl;

  factory Conversation.fromJson(Map<String, dynamic> json) {
    final userA = json['participant_a_name']?.toString();
    final userB = json['participant_b_name']?.toString();
    return Conversation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title'] as String? ?? userA ?? userB ?? 'Conversation',
      lastMessagePreview: json['last_message_text'] as String? ??
          json['last_message_preview'] as String? ??
          json['last_message'] as String? ??
          '',
      lastMessageAt: DateTime.tryParse(json['last_message_at'] as String? ?? ''),
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      listingTitle: json['listing_title'] as String?,
      listingPrice: (json['listing_price'] as num?)?.toDouble(),
      listingImageUrl: json['listing_image_url'] as String?,
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
      listingImageUrl: listingImageUrl,
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
  });

  final int id;
  final int senderId;
  final String text;
  final DateTime sentAt;
  final List<MessageAttachment> attachments;

  factory ConversationMessage.fromJson(Map<String, dynamic> json) {
    return ConversationMessage(
      id: (json['id'] as num?)?.toInt() ?? 0,
      senderId: (json['sender_id'] as num?)?.toInt() ?? 0,
      text: json['text_body'] as String? ??
          json['content'] as String? ??
          json['text'] as String? ??
          '',
      sentAt: DateTime.tryParse(json['sent_at'] as String? ?? '') ?? DateTime.now(),
      attachments: (json['attachments'] as List<dynamic>? ?? [])
          .map((e) => MessageAttachment.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      url: json['url'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      contentType: json['content_type'] as String? ?? '',
      sizeBytes: (json['size_bytes'] as num?)?.toInt() ?? 0,
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
      id: (json['id'] as num?)?.toInt() ?? 0,
      messageId: (json['message_id'] as num?)?.toInt() ?? 0,
      fileName: json['file_name'] as String? ?? '',
      originalName: json['original_name'] as String? ?? '',
      mimeType: json['mime_type'] as String? ?? '',
      fileSize: (json['file_size'] as num?)?.toInt() ?? 0,
      fileUrl: json['file_url'] as String? ?? '',
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
      conversationId: (json['conversation_id'] as num?)?.toInt() ?? 0,
      unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class UnreadSummaryDto {
  const UnreadSummaryDto({
    required this.totalUnread,
    required this.byConversation,
  });

  final int totalUnread;
  final List<UnreadConversationItem> byConversation;

  factory UnreadSummaryDto.fromJson(Map<String, dynamic> json) {
    return UnreadSummaryDto(
      totalUnread: (json['total_unread'] as num?)?.toInt() ?? 0,
      byConversation: (json['by_conversation'] as List<dynamic>? ?? [])
          .map((e) => UnreadConversationItem.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      detail: json['detail'] as String? ?? '',
      updatedCount: (json['updated_count'] as num?)?.toInt() ?? 0,
    );
  }
}
