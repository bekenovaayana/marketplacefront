import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:marketplace_frontend/features/chats/ui/widgets/conversation_list_item.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/profile/ui/widgets/profile_trust_card.dart';

void main() {
  testWidgets('conversation item renders unread badge and listing preview', (
    tester,
  ) async {
    final item = Conversation(
      id: 1,
      title: 'Seller',
      lastMessagePreview: 'Hello',
      lastMessageAt: DateTime.now(),
      unreadCount: 2,
      listingTitle: 'iPhone',
      listingPrice: 1000,
      listingImageUrl: '',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ConversationListItem(
            conversation: item,
            unreadCount: 3,
            onTap: () {},
          ),
        ),
      ),
    );

    expect(find.text('Seller'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);
    expect(find.textContaining('iPhone'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
  });

  testWidgets('profile trust card renders score and missing fields', (
    tester,
  ) async {
    final me = UserMeResponse(
      id: 1,
      fullName: 'User',
      firstName: 'User',
      lastName: 'Test',
      email: 'u@test.com',
      bio: '',
      city: '',
      preferredLanguage: 'en',
      phone: '',
      avatarUrl: null,
      status: 'active',
      emailVerified: true,
      phoneVerified: false,
      profileCompleted: false,
      trustScore: 75,
      lastSeenAt: null,
      createdAt: null,
      updatedAt: null,
    );
    const completeness = ProfileCompletenessDto(
      percentage: 60,
      completedFields: ['email'],
      missingFields: ['phone', 'city'],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: ProfileTrustCard(
            profile: me,
            completeness: completeness,
            onTapMissingField: (_) {},
          ),
        ),
      ),
    );

    expect(find.textContaining('75'), findsWidgets);
    expect(find.textContaining('Profile completeness: 60%'), findsOneWidget);
    expect(find.text('Add phone'), findsOneWidget);
    expect(find.text('Add city'), findsOneWidget);
  });
}
