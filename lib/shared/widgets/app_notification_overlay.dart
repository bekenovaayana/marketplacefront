import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

void showAppNotification(
  BuildContext context,
  String message, {
  Duration duration = const Duration(seconds: 4),
}) {
  _AppNotificationOverlay.instance.show(
    context: context,
    message: message,
    duration: duration,
  );
}

class _AppNotificationOverlay {
  _AppNotificationOverlay._();

  static final instance = _AppNotificationOverlay._();

  final List<_NotificationItem> _items = [];
  final Map<int, Timer> _timers = {};

  OverlayEntry? _entry;
  int _seed = 0;

  void show({
    required BuildContext context,
    required String message,
    required Duration duration,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _ensureEntry(overlay);

    final id = _seed++;
    _items.add(_NotificationItem(id: id, message: message));
    _entry?.markNeedsBuild();

    _timers[id]?.cancel();
    _timers[id] = Timer(duration, () => dismiss(id));
  }

  void dismiss(int id) {
    _timers.remove(id)?.cancel();
    _items.removeWhere((item) => item.id == id);
    if (_items.isEmpty) {
      _entry?.remove();
      _entry = null;
      return;
    }
    _entry?.markNeedsBuild();
  }

  void _ensureEntry(OverlayState overlay) {
    if (_entry != null) {
      return;
    }
    _entry = OverlayEntry(
      builder: (context) {
        final viewportWidth = MediaQuery.sizeOf(context).width;
        final maxWidth = math.min(360.0, math.max(0.0, viewportWidth - 32));
        return Positioned(
          top: 16,
          right: 16,
          child: Material(
            type: MaterialType.transparency,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (final item in _items)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _ToastCard(
                        message: item.message,
                        onClose: () => dismiss(item.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
    overlay.insert(_entry!);
  }
}

class _NotificationItem {
  const _NotificationItem({required this.id, required this.message});

  final int id;
  final String message;
}

class _ToastCard extends StatelessWidget {
  const _ToastCard({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Material(
      elevation: 8,
      borderRadius: BorderRadius.circular(12),
      color: const Color(0xFF1F2937),
      child: Container(
        constraints: const BoxConstraints(minWidth: 220),
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(message, style: const TextStyle(color: Colors.white)),
            ),
            const SizedBox(width: 8),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: onClose,
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
