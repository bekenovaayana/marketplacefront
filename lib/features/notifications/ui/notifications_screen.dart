import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/conversations/ui/conversation_detail_page.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_models.dart';
import 'package:marketplace_frontend/features/notifications/state/notifications_controller.dart';
import 'package:marketplace_frontend/features/notifications/state/unread_notifications_provider.dart';
import 'package:marketplace_frontend/features/notifications/ui/widgets/notification_tile.dart';
import 'package:marketplace_frontend/features/payments/ui/payments_page.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen>
    with AutomaticKeepAliveClientMixin {
  final _scrollController = ScrollController();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 180;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(notificationsProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(notificationsProvider);
    final unreadCount = ref.watch(unreadNotificationsCountProvider);
    final allCaughtUp =
        state.unreadOnly && state.items.isEmpty && !state.isLoading;
    String t(String key) => AppStrings.of(context, key);
    return Scaffold(
      appBar: AppBar(
        title: Text(t('notificationsTitle')),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: () async {
                try {
                  await ref.read(notificationsProvider.notifier).markAllRead();
                  ref.read(unreadNotificationsCountProvider.notifier).reset();
                  await ref.read(notificationsProvider.notifier).refresh();
                } catch (_) {
                  if (!context.mounted) return;
                  showAppNotification(context, t('markAllReadFailed'));
                }
              },
              child: Text(t('markAllRead')),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text(t('notificationsFilterAll')),
                  selected: !state.unreadOnly,
                  onSelected: (_) => ref
                      .read(notificationsProvider.notifier)
                      .setUnreadOnly(false),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(t('notificationsFilterUnread')),
                  selected: state.unreadOnly,
                  onSelected: (_) => ref
                      .read(notificationsProvider.notifier)
                      .setUnreadOnly(true),
                ),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await ref.read(notificationsProvider.notifier).refresh();
                await ref
                    .read(unreadNotificationsCountProvider.notifier)
                    .refresh();
              },
              child: state.isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : state.error != null
                  ? ListView(
                      children: [
                        const SizedBox(height: 120),
                        Center(child: Text(state.error!)),
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: () =>
                                ref.read(notificationsProvider.notifier).load(),
                            child: Text(t('retry')),
                          ),
                        ),
                      ],
                    )
                  : allCaughtUp
                  ? ListView(
                      children: [
                        const SizedBox(height: 140),
                        const Icon(
                          Icons.check_circle_outline,
                          size: 44,
                          color: Colors.green,
                        ),
                        const SizedBox(height: 12),
                        Center(child: Text(t('notificationsAllCaughtUp'))),
                      ],
                    )
                  : state.items.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 140),
                        const Icon(Icons.notifications_none, size: 44),
                        const SizedBox(height: 12),
                        Center(child: Text(t('notificationsEmpty'))),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount:
                          state.items.length + (state.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.items.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final item = state.items[index];
                        return NotificationTile(
                          notification: item,
                          onTap: () => _onTapNotification(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onTapNotification(NotificationModel notification) async {
    final notifier = ref.read(notificationsProvider.notifier);
    final unreadController = ref.read(
      unreadNotificationsCountProvider.notifier,
    );
    try {
      await notifier.markRead(notification.id);
      await unreadController.refresh();
    } catch (_) {
      if (!mounted) return;
      showAppNotification(
        context,
        AppStrings.of(context, 'markReadFailed'),
      );
    }
    if (!mounted) return;
    final entityId = notification.entityId;
    if (entityId == null) return;

    final et = (notification.entityType ?? '').toLowerCase();
    final nt = notification.notificationType.toLowerCase();

    if (et == 'listing' ||
        nt == 'listing_favorited' ||
        nt == 'contact_request') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ListingDetailPage(listingId: entityId),
        ),
      );
      return;
    }
    if (et == 'conversation' ||
        et == 'chat' ||
        nt == 'new_message') {
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ConversationDetailPage(conversationId: entityId),
        ),
      );
      await unreadController.refresh();
      return;
    }
    if (et == 'payment' || et == 'promotion') {
      await Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const PaymentsPage()));
    }
  }
}
