import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_models.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.unreadOnly = false,
    this.page = 1,
    this.hasMore = true,
    this.error,
  });

  final List<NotificationModel> items;
  final bool isLoading;
  final bool isLoadingMore;
  final bool unreadOnly;
  final int page;
  final bool hasMore;
  final String? error;

  NotificationsState copyWith({
    List<NotificationModel>? items,
    bool? isLoading,
    bool? isLoadingMore,
    bool? unreadOnly,
    int? page,
    bool? hasMore,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      unreadOnly: unreadOnly ?? this.unreadOnly,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsController, NotificationsState>((ref) {
  return NotificationsController(ref.watch(notificationRepositoryProvider));
});

class NotificationsController extends StateNotifier<NotificationsState> {
  NotificationsController(this._repository)
      : super(const NotificationsState(isLoading: true)) {
    load();
  }

  final NotificationRepository _repository;
  static const _pageSize = 20;
  bool _loading = false;
  bool _loadingMore = false;

  Future<void> load() async {
    if (_loading) return;
    _loading = true;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final result = await _repository.fetchNotifications(
        page: 1,
        pageSize: _pageSize,
        unreadOnly: state.unreadOnly,
      );
      state = state.copyWith(
        isLoading: false,
        items: result.items,
        page: 1,
        hasMore: result.page < result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    } finally {
      _loading = false;
    }
  }

  Future<void> refresh() => load();

  Future<void> loadMore() async {
    if (_loadingMore || state.isLoading || !state.hasMore) return;
    _loadingMore = true;
    state = state.copyWith(isLoadingMore: true, clearError: true);
    try {
      final nextPage = state.page + 1;
      final result = await _repository.fetchNotifications(
        page: nextPage,
        pageSize: _pageSize,
        unreadOnly: state.unreadOnly,
      );
      final seen = <int>{for (final item in state.items) item.id};
      final merged = [
        ...state.items,
        ...result.items.where((item) => !seen.contains(item.id)),
      ];
      state = state.copyWith(
        isLoadingMore: false,
        items: merged,
        page: nextPage,
        hasMore: result.page < result.totalPages,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    } finally {
      _loadingMore = false;
    }
  }

  Future<void> setUnreadOnly(bool value) async {
    if (state.unreadOnly == value) return;
    state = state.copyWith(unreadOnly: value);
    await load();
  }

  Future<void> markRead(int id) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index == -1) return;
    final current = state.items[index];
    if (current.isRead) return;
    final patched = List<NotificationModel>.from(state.items);
    patched[index] = current.copyWith(isRead: true, readAt: DateTime.now());
    state = state.copyWith(items: patched);
    try {
      await _repository.markRead(id);
    } catch (_) {
      // non-blocking: optimistic update stays
    }
  }

  Future<int> markAllRead() async {
    final updated = await _repository.markAllRead();
    final now = DateTime.now();
    state = state.copyWith(
      items: state.items.map((e) => e.copyWith(isRead: true, readAt: now)).toList(),
    );
    return updated;
  }
}
