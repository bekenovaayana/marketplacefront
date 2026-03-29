import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';

final conversationsRepositoryProvider = Provider<ConversationsRepository>((ref) {
  return ConversationsRepository(ref.watch(conversationsApiProvider));
});

class ConversationsRepository {
  ConversationsRepository(this._api);

  final ConversationsApi _api;

  Future<void> deleteConversation(int conversationId) =>
      _api.deleteConversation(conversationId);
}
