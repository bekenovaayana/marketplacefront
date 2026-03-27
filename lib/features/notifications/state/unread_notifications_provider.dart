import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' show FutureProvider;
import 'package:flutter_riverpod/legacy.dart' as legacy;
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/core/storage/token_storage.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_repository.dart';

final unreadCountProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.watch(notificationRepositoryProvider).fetchUnreadCount();
});

final unreadNotificationsCountProvider = legacy.StateNotifierProvider<
    UnreadNotificationsCountController, int>((ref) {
  return UnreadNotificationsCountController(
    ref.watch(notificationRepositoryProvider),
    ref.watch(tokenStorageProvider),
  );
});

class UnreadNotificationsCountController extends legacy.StateNotifier<int>
    with WidgetsBindingObserver {
  UnreadNotificationsCountController(this._repository, this._tokenStorage) : super(0) {
    WidgetsBinding.instance.addObserver(this);
    refresh();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isForeground) {
        refresh();
      }
    });
  }

  final NotificationRepository _repository;
  final TokenStorage _tokenStorage;
  Timer? _timer;
  bool _isForeground = true;

  Future<void> refresh() async {
    try {
      final token = await _tokenStorage.readAccessToken();
      if (token == null || token.isEmpty) {
        state = 0;
        return;
      }
      state = await _repository.fetchUnreadCount();
    } catch (_) {}
  }

  void reset() {
    state = 0;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _isForeground = state == AppLifecycleState.resumed;
    if (_isForeground) {
      refresh();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }
}
