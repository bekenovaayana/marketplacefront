import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';

void main() {
  group('ConversationDto parsing', () {
    test('handles nullable metadata fields', () {
      final dto = Conversation.fromJson({
        'id': 10,
        'title': 'Seller',
        'last_message_text': null,
        'last_message_at': null,
        'unread_count': 2,
        'listing_title': null,
        'listing_price': null,
        'listing_image_url': null,
      });

      expect(dto.id, 10);
      expect(dto.lastMessagePreview, '');
      expect(dto.lastMessageAt, isNull);
      expect(dto.unreadCount, 2);
      expect(dto.listingTitle, isNull);
    });
  });

  group('Unread summary mapping', () {
    test('maps total and conversation counters', () {
      final summary = UnreadSummaryDto.fromJson({
        'total_unread': 4,
        'by_conversation': [
          {'conversation_id': 1, 'unread_count': 3},
          {'conversation_id': 2, 'unread_count': 1},
        ],
      });

      expect(summary.totalUnread, 4);
      expect(summary.byConversation.length, 2);
      expect(summary.byConversation.first.conversationId, 1);
    });
  });

  group('Trust/completeness parsing', () {
    test('parses trust fields from user me', () {
      final me = UserMeResponse.fromJson({
        'id': 1,
        'full_name': 'A',
        'email': 'a@a.com',
        'bio': '',
        'city': '',
        'preferred_language': 'en',
        'phone': '',
        'status': 'active',
        'email_verified': true,
        'phone_verified': false,
        'profile_completed': false,
        'trust_score': 67,
      });
      expect(me.emailVerified, isTrue);
      expect(me.phoneVerified, isFalse);
      expect(me.trustScore, 67);
    });

    test('parses completeness payload', () {
      final completeness = ProfileCompletenessDto.fromJson({
        'percentage': 70,
        'completed_fields': ['full_name'],
        'missing_fields': ['phone', 'city'],
      });
      expect(completeness.percentage, 70);
      expect(completeness.missingFields, contains('phone'));
    });
  });

  test('idempotency key builder returns UUID-like value', () {
    final api = ConversationsApi(Dio());
    final key = api.buildIdempotencyKey();
    expect(key, matches(RegExp(r'^[0-9a-fA-F-]{36}$')));
  });
}
