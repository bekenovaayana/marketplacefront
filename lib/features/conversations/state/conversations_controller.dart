import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';

class ConversationsState {
  const ConversationsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isRefreshingUnread = false,
    this.page = 1,
    this.hasMore = true,
    this.totalUnread = 0,
    this.unreadByConversation = const {},
    this.error,
  });

  final List<Conversation> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isRefreshingUnread;
  final int page;
  final bool hasMore;
  final int totalUnread;
  final Map<int, int> unreadByConversation;
  final String? error;

  ConversationsState copyWith({
    List<Conversation>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isRefreshingUnread,
    int? page,
    bool? hasMore,
    int? totalUnread,
    Map<int, int>? unreadByConversation,
    String? error,
    bool clearError = false,
  }) {
    return ConversationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshingUnread: isRefreshingUnread ?? this.isRefreshingUnread,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      totalUnread: totalUnread ?? this.totalUnread,
      unreadByConversation: unreadByConversation ?? this.unreadByConversation,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final conversationsControllerProvider = StateNotifierProvider<
    ConversationsController, ConversationsState>((ref) {
  return ConversationsController(ref.watch(conversationsApiProvider));
});

class ConversationsController extends StateNotifier<ConversationsState> {
  ConversationsController(this._api)
      : super(const ConversationsState(isLoading: true)) {
    load();
    refreshUnreadSummary();
  }

  final ConversationsApi _api;
  static const _pageSize = 20;
  bool _loading = false;
  bool _loadingMore = false;

  Future<void> load({bool refresh = false}) async {
    if (_loading) return;
    _loading = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final items = await _api.listConversations(page: 1, pageSize: _pageSize);
      state = state.copyWith(
        isLoading: false,
        items: items,
        page: 1,
        hasMore: items.length >= _pageSize,
      );
      if (refresh) {
        await refreshUnreadSummary();
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _loading = false;
    }
  }

  Future<void> loadMore() async {
    if (_loadingMore || state.isLoading || !state.hasMore) return;
    _loadingMore = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final items = await _api.listConversations(page: nextPage, pageSize: _pageSize);
      state = state.copyWith(
        isLoadingMore: false,
        items: [...state.items, ...items],
        page: nextPage,
        hasMore: items.length >= _pageSize,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> refreshUnreadSummary() async {
    state = state.copyWith(isRefreshingUnread: true);
    try {
      final summary = await _api.getUnreadSummary();
      final map = <int, int>{
        for (final item in summary.byConversation) item.conversationId: item.unreadCount,
      };
      state = state.copyWith(
        isRefreshingUnread: false,
        totalUnread: summary.totalUnread,
        unreadByConversation: map,
      );
    } catch (_) {
      state = state.copyWith(isRefreshingUnread: false);
    }
  }

  Future<void> markConversationRead(int conversationId) async {
    final current = state.unreadByConversation[conversationId] ?? 0;
    if (current > 0) {
      final patched = Map<int, int>.from(state.unreadByConversation);
      patched[conversationId] = 0;
      final nextTotal = state.totalUnread - current < 0 ? 0 : state.totalUnread - current;
      state = state.copyWith(unreadByConversation: patched, totalUnread: nextTotal);
    }
    try {
      await _api.markConversationRead(conversationId);
    } catch (_) {
      // ignore to avoid blocking chat entry
    }
    await refreshUnreadSummary();
  }
}
