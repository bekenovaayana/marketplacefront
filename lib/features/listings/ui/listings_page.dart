import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/listings/state/listings_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';
import 'package:marketplace_frontend/shared/widgets/pagination_loader.dart';

class ListingsPage extends ConsumerStatefulWidget {
  const ListingsPage({super.key});

  @override
  ConsumerState<ListingsPage> createState() => _ListingsPageState();
}

class _ListingsPageState extends ConsumerState<ListingsPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(listingsControllerProvider.notifier).loadInitial());
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(listingsControllerProvider);
    return AppScaffold(
      title: 'Listings',
      actions: [
        IconButton(
          onPressed: () => context.go('/favorites'),
          icon: const Icon(Icons.favorite_border),
        ),
        IconButton(
          onPressed: () => context.go('/conversations'),
          icon: const Icon(Icons.chat_bubble_outline),
        ),
        IconButton(
          onPressed: () => context.go('/payments'),
          icon: const Icon(Icons.payment_outlined),
        ),
        IconButton(
          onPressed: () async {
            await ref.read(authControllerProvider.notifier).logout();
            if (context.mounted) {
              context.go('/login');
            }
          },
          icon: const Icon(Icons.logout),
        ),
      ],
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/listings/create'),
        child: const Icon(Icons.add),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(listingsControllerProvider.notifier).loadInitial(),
        child: ListView(
          children: [
            if (state.isLoading)
              const SizedBox(
                height: 300,
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!state.isLoading && state.items.isEmpty)
              const SizedBox(
                height: 300,
                child: Center(child: Text('No listings found')),
              ),
            ...state.items.map(
              (item) => ListTile(
                title: Text(item.title),
                subtitle: Text('${item.city} • ${item.price}'),
                trailing: IconButton(
                  onPressed: () => ref
                      .read(listingsControllerProvider.notifier)
                      .toggleFavorite(item),
                  icon: Icon(
                    item.isFavorite ? Icons.favorite : Icons.favorite_border,
                    color: item.isFavorite ? Colors.red : null,
                  ),
                ),
                onTap: () => context.push('/listings/${item.id}'),
              ),
            ),
            PaginationLoader(
              hasMore: state.hasMore,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: () => ref.read(listingsControllerProvider.notifier).loadMore(),
            ),
          ],
        ),
      ),
    );
  }
}
