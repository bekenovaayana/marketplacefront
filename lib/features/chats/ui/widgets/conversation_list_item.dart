import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';

class ConversationListItem extends StatelessWidget {
  const ConversationListItem({
    super.key,
    required this.conversation,
    required this.unreadCount,
    required this.onTap,
  });

  final Conversation conversation;
  final int unreadCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final preview = conversation.lastMessagePreview.trim().isEmpty
        ? 'No messages yet'
        : conversation.lastMessagePreview.trim();
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      leading: CircleAvatar(
        child: Text(conversation.title.isEmpty ? '?' : conversation.title[0].toUpperCase()),
      ),
      title: Text(conversation.title),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (conversation.listingTitle != null && conversation.listingTitle!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Row(
                children: [
                  if (conversation.listingImageUrl != null &&
                      conversation.listingImageUrl!.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.network(
                        conversation.listingImageUrl!,
                        width: 18,
                        height: 18,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  Expanded(
                    child: Text(
                      conversation.listingPrice == null
                          ? conversation.listingTitle!
                          : '${conversation.listingTitle!} · ${conversation.listingPrice!.toStringAsFixed(0)}',
                      style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            _formatTime(conversation.lastMessageAt),
            style: textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 4),
          if (unreadCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                unreadCount > 99 ? '99+' : unreadCount.toString(),
                style: textTheme.labelSmall?.copyWith(color: Colors.white),
              ),
            ),
        ],
      ),
      onTap: onTap,
    );
  }

  String _formatTime(DateTime? value) {
    if (value == null) return '';
    final now = DateTime.now();
    if (now.difference(value).inHours < 24) {
      return DateFormat.Hm().format(value);
    }
    return DateFormat('dd.MM').format(value);
  }
}
