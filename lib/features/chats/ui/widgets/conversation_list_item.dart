import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
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
    final title = conversation.displayTitle;
    final initial = title.isEmpty ? '?' : title[0].toUpperCase();
    return ListTile(
      leading: conversation.peerAvatarUrl != null &&
              conversation.peerAvatarUrl!.isNotEmpty
          ? CircleAvatar(
              backgroundImage: NetworkImage(
                ApiUrls.networkImageUrl(conversation.peerAvatarUrl!),
              ),
              onBackgroundImageError: (_, _) {},
              child: Text(initial),
            )
          : CircleAvatar(child: Text(initial)),
      title: Text(title),
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
                        ApiUrls.networkImageUrl(conversation.listingImageUrl),
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
                      _listingSubtitle(conversation),
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

  static String _listingSubtitle(Conversation c) {
    final t = c.listingTitle;
    if (t == null || t.isEmpty) return '';
    final p = c.listingPrice;
    if (p == null) return t;
    final cur = c.listingCurrency;
    final price = p.toStringAsFixed(0);
    if (cur != null && cur.isNotEmpty) {
      return '$t · $price $cur';
    }
    return '$t · $price';
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
