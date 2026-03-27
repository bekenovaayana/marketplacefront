import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/conversations/state/conversations_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class ConversationsPage extends ConsumerWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(conversationsControllerProvider);
    return AppScaffold(
      title: 'Conversations',
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : state.items.isEmpty
                  ? const Center(child: Text('No conversations'))
                  : ListView.builder(
                      itemCount: state.items.length,
                      itemBuilder: (context, index) {
                        final item = state.items[index];
                        return ListTile(
                          title: Text(item.title),
                          subtitle: Text(item.lastMessagePreview),
                          onTap: () => context.push('/conversations/${item.id}'),
                        );
                      },
                    ),
    );
  }
}
