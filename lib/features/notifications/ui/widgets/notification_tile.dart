import 'package:flutter/material.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/notifications/data/notification_models.dart';
import 'package:marketplace_frontend/features/notifications/ui/widgets/relative_time.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.notification,
    required this.onTap,
  });

  final NotificationModel notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isUnread = !notification.isRead;
    final avatarUrl = notification.actor?.avatarUrl;
    final resolvedAvatar = avatarUrl != null && avatarUrl.isNotEmpty
        ? ApiUrls.networkImageUrl(avatarUrl)
        : '';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: isUnread ? Colors.blue.shade50 : Colors.white,
        child: ListTile(
          leading: resolvedAvatar.isNotEmpty
              ? ClipOval(
                  child: Image.network(
                    resolvedAvatar,
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Icon(
                      _iconForType(notification.notificationType),
                      color: _colorForType(notification.notificationType),
                    ),
                  ),
                )
              : Icon(
                  _iconForType(notification.notificationType),
                  color: _colorForType(notification.notificationType),
                ),
          title: Text(
            notification.title,
            style: TextStyle(
              fontWeight: isUnread ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          subtitle: Text(
            notification.body,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                formatRelativeTime(notification.createdAt),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 4),
              if (isUnread)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'new_message':
        return Icons.chat_bubble_outline;
      case 'listing_approved':
        return Icons.check_circle_outline;
      case 'listing_rejected':
        return Icons.cancel_outlined;
      case 'payment_successful':
        return Icons.payment;
      case 'promotion_activated':
        return Icons.rocket_launch_outlined;
      case 'promotion_expired':
        return Icons.timer_off_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type) {
      case 'new_message':
        return Colors.blue;
      case 'listing_approved':
        return Colors.green;
      case 'listing_rejected':
        return Colors.red;
      case 'payment_successful':
        return Colors.green;
      case 'promotion_activated':
        return Colors.orange;
      case 'promotion_expired':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }
}
