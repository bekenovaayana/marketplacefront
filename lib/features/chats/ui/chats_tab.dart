import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/chats/ui/widgets/conversation_list_item.dart';
import 'package:marketplace_frontend/features/conversations/ui/conversation_detail_page.dart';
import 'package:marketplace_frontend/features/conversations/state/conversations_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class ChatsTab extends ConsumerStatefulWidget {
  const ChatsTab({super.key});

  @override
  ConsumerState<ChatsTab> createState() => _ChatsTabState();
}

class _ChatsTabState extends ConsumerState<ChatsTab>
    with AutomaticKeepAliveClientMixin {
  bool _requestedLoad = false;
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
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      ref.read(conversationsControllerProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    String t(String key) => AppStrings.of(context, key);
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.chat_bubble_outline, size: 56),
                const SizedBox(height: 10),
                const Text('Sign in to view chats and send messages'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final from = Uri.encodeComponent('/app?tab=3');
                    context.push('/auth-gate?from=$from');
                  },
                  child: const Text('Sign in / Create account'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (auth.isAuthenticated && !_requestedLoad) {
      _requestedLoad = true;
      Future.microtask(() async {
        await ref.read(conversationsControllerProvider.notifier).load();
        await ref
            .read(conversationsControllerProvider.notifier)
            .refreshUnreadSummary();
      });
    }
    final state = ref.watch(conversationsControllerProvider);
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () {
          if (!auth.isAuthenticated) return Future.value();
          return ref
              .read(conversationsControllerProvider.notifier)
              .load(refresh: true);
        },
        child: state.isLoading
            ? ListView(
                children: const [
                  SizedBox(height: 10),
                  _ChatTileSkeleton(),
                  _ChatTileSkeleton(),
                  _ChatTileSkeleton(),
                ],
              )
            : state.error != null
            ? ListView(
                children: [
                  ListTile(
                    title: Text(ErrorMapper.friendly(state.error)),
                    trailing: TextButton(
                      onPressed: () => ref
                          .read(conversationsControllerProvider.notifier)
                          .load(),
                      child: Text(t('retry')),
                    ),
                  ),
                ],
              )
            : state.items.isEmpty
            ? ListView(
                key: const PageStorageKey('chats_tab_empty'),
                children: [
                  const SizedBox(height: 120),
                  Center(child: Text(t('noConversations'))),
                ],
              )
            : ListView.builder(
                controller: _scrollController,
                key: const PageStorageKey('chats_tab_list'),
                itemCount: state.items.length + (state.isLoadingMore ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= state.items.length) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final item = state.items[index];
                  final unreadCount =
                      state.unreadByConversation[item.id] ?? item.unreadCount;
                  return ConversationListItem(
                    conversation: item,
                    unreadCount: unreadCount,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ConversationDetailPage(conversationId: item.id),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _ChatTileSkeleton extends StatelessWidget {
  const _ChatTileSkeleton();

  @override
  Widget build(BuildContext context) {
    return const ListTile(
      leading: CircleAvatar(backgroundColor: Color(0xFFE8EBF1)),
      title: SkeletonBox(height: 14),
      subtitle: Padding(
        padding: EdgeInsets.only(top: 6),
        child: SkeletonBox(height: 12, width: 180),
      ),
    );
  }
}
