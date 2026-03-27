import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/chats/ui/chats_tab.dart';
import 'package:marketplace_frontend/features/conversations/state/conversations_controller.dart';
import 'package:marketplace_frontend/features/favorites/ui/favorites_page.dart';
import 'package:marketplace_frontend/features/home/ui/home_tab.dart';
import 'package:marketplace_frontend/features/notifications/state/unread_notifications_provider.dart';
import 'package:marketplace_frontend/features/notifications/ui/notifications_screen.dart';
import 'package:marketplace_frontend/features/posting/ui/posting_tab.dart';
import 'package:marketplace_frontend/features/profile/ui/profile_tab.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class MainTabsPage extends ConsumerStatefulWidget {
  const MainTabsPage({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  ConsumerState<MainTabsPage> createState() => _MainTabsPageState();
}

class _MainTabsPageState extends ConsumerState<MainTabsPage>
    with WidgetsBindingObserver {
  late int _index = widget.initialIndex;

  final _tabs = const [
    HomeTab(),
    FavoritesPage(),
    PostingTab(),
    ChatsTab(),
    NotificationsScreen(),
    ProfileTab(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Future.microtask(() {
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        ref
            .read(conversationsControllerProvider.notifier)
            .refreshUnreadSummary();
        ref.read(unreadNotificationsCountProvider.notifier).refresh();
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final auth = ref.read(authControllerProvider);
      if (auth.isAuthenticated) {
        ref
            .read(conversationsControllerProvider.notifier)
            .refreshUnreadSummary();
        ref.read(unreadNotificationsCountProvider.notifier).refresh();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => AppStrings.of(context, key);
    final auth = ref.watch(authControllerProvider);
    final unread = ref.watch(conversationsControllerProvider).totalUnread;
    final notificationsUnread = ref.watch(unreadNotificationsCountProvider);
    return Scaffold(
      body: IndexedStack(index: _index, children: _tabs),
      bottomNavigationBar: NavigationBar(
        height: 68,
        selectedIndex: _index,
        onDestinationSelected: (value) async {
          const protectedTabs = <int>{1, 2, 3};
          if (!auth.isAuthenticated && protectedTabs.contains(value)) {
            final from = Uri.encodeComponent('/app?tab=$value');
            await context.push('/auth-gate?from=$from');
            return;
          }
          setState(() => _index = value);
          if (!auth.isAuthenticated) return;
          if (value == 3) {
            ref
                .read(conversationsControllerProvider.notifier)
                .refreshUnreadSummary();
          }
          if (value == 4) {
            ref.read(unreadNotificationsCountProvider.notifier).refresh();
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            label: t('home'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.favorite_border),
            label: t('favorites'),
          ),
          NavigationDestination(
            icon: const Icon(Icons.add_box_outlined),
            label: t('post'),
          ),
          NavigationDestination(
            icon: unread > 0
                ? Badge(
                    label: Text(unread > 99 ? '99+' : unread.toString()),
                    child: const Icon(Icons.chat_bubble_outline),
                  )
                : const Icon(Icons.chat_bubble_outline),
            label: t('chats'),
          ),
          NavigationDestination(
            icon: notificationsUnread > 0
                ? Badge(
                    label: Text(
                      notificationsUnread >= 100
                          ? '99+'
                          : notificationsUnread.toString(),
                    ),
                    backgroundColor: Colors.red,
                    child: const Icon(Icons.notifications_outlined),
                  )
                : const Icon(Icons.notifications_outlined),
            label: 'Alerts',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            label: t('profile'),
          ),
        ],
      ),
    );
  }
}
