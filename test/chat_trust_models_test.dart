import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';
import 'package:marketplace_frontend/features/favorites/data/favorite_record.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';

void main() {
  group('ConversationMessage', () {
    const me = 7;

    test('bubble side uses sender_id vs current user (POST may omit is_mine)', () {
      final mineMsg = ConversationMessage.fromJson({
        'id': 1,
        'sender_id': me,
        'text_body': 'hi',
        'sent_at': '2020-01-01T00:00:00Z',
        'is_mine': false,
      });
      expect(mineMsg.isMine, isFalse);
      expect(mineMsg.isFromCurrentUser(me), isTrue);

      final other = ConversationMessage.fromJson({
        'id': 2,
        'sender_id': 1,
        'text_body': 'yo',
        'sent_at': '2020-01-01T00:00:00Z',
        'is_mine': true,
      });
      expect(other.isMine, isTrue);
      expect(other.isFromCurrentUser(me), isFalse);
    });

    test('falls back to is_mine when sender id missing', () {
      final noSender = ConversationMessage.fromJson({
        'id': 3,
        'text_body': 'x',
        'sent_at': '2020-01-01T00:00:00Z',
        'is_mine': true,
      });
      expect(noSender.senderId, 0);
      expect(noSender.isFromCurrentUser(me), isTrue);
    });

    test('parses user_id / author_id as sender', () {
      final a = ConversationMessage.fromJson({
        'id': 4,
        'user_id': 42,
        'text_body': 'a',
        'sent_at': '2020-01-01T00:00:00Z',
      });
      expect(a.senderId, 42);
      final b = ConversationMessage.fromJson({
        'id': 5,
        'author_id': 43,
        'text_body': 'b',
        'sent_at': '2020-01-01T00:00:00Z',
      });
      expect(b.senderId, 43);
    });

    test('optimistic row is always mine when sender matches', () {
      final optimistic = ConversationMessage(
        id: -1,
        senderId: me,
        text: 't',
        sentAt: DateTime.utc(2020),
        isMine: true,
      );
      expect(optimistic.isFromCurrentUser(me), isTrue);
    });
  });

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

  test('FavoriteRecord parses GET /favorites row', () {
    final r = FavoriteRecord.fromJson({
      'id': 10,
      'user_id': 1,
      'listing_id': 20,
      'created_at': '2020-01-01T00:00:00Z',
      'listing_is_available': false,
      'listing': {
        'id': 20,
        'title': 'Phone',
        'description': '',
        'price': 100,
        'currency': 'KGS',
        'city': 'B',
        'is_favorite': true,
      },
    });
    expect(r.id, 10);
    expect(r.listingId, 20);
    expect(r.listingIsAvailable, isFalse);
    expect(r.listing?.title, 'Phone');
  });

  test('parseMessageFromPostResponse unwraps message envelope', () {
    final m = ConversationsApi.parseMessageFromPostResponse({
      'message': {
        'id': 42,
        'text_body': 'ok',
        'sent_at': '2020-01-01T00:00:00Z',
        'is_mine': true,
      },
    });
    expect(m, isNotNull);
    expect(m!.id, 42);
    expect(m.isMine, isTrue);
  });
}
