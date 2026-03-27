import 'dart:io';

import 'package:flutter/material.dart';
import 'package:marketplace_frontend/features/conversations/presentation/pending_attachment.dart';

class ChatInputBar extends StatelessWidget {
  const ChatInputBar({
    super.key,
    required this.controller,
    required this.pendingAttachments,
    required this.onPickAttachment,
    required this.onRetryAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
    required this.isSending,
    required this.isSendEnabled,
    required this.isAttachmentLimitReached,
  });

  final TextEditingController controller;
  final List<PendingAttachment> pendingAttachments;
  final VoidCallback onPickAttachment;
  final ValueChanged<int> onRetryAttachment;
  final ValueChanged<int> onRemoveAttachment;
  final VoidCallback onSend;
  final bool isSending;
  final bool isSendEnabled;
  final bool isAttachmentLimitReached;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (pendingAttachments.isNotEmpty)
            SizedBox(
              height: 78,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                scrollDirection: Axis.horizontal,
                itemCount: pendingAttachments.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final item = pendingAttachments[index];
                  return _AttachmentChip(
                    item: item,
                    onRetry: () => onRetryAttachment(index),
                    onRemove: () => onRemoveAttachment(index),
                  );
                },
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: isAttachmentLimitReached ? null : onPickAttachment,
                  icon: const Icon(Icons.attach_file),
                ),
                Expanded(
                  child: TextField(
                    controller: controller,
                    minLines: 1,
                    maxLines: 4,
                    decoration: const InputDecoration(hintText: 'Message'),
                  ),
                ),
                IconButton(
                  onPressed: isSending || !isSendEnabled ? null : onSend,
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentChip extends StatelessWidget {
  const _AttachmentChip({
    required this.item,
    required this.onRetry,
    required this.onRemove,
  });

  final PendingAttachment item;
  final VoidCallback onRetry;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final ext = item.localFile.path.toLowerCase();
    final isImage = ext.endsWith('.jpg') ||
        ext.endsWith('.jpeg') ||
        ext.endsWith('.png') ||
        ext.endsWith('.webp');
    return SizedBox(
      width: 120,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: item.errorMessage != null ? Colors.red : Colors.grey.shade300,
              ),
            ),
            padding: const EdgeInsets.all(8),
            child: isImage
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.file(
                      File(item.localFile.path),
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                    ),
                  )
                : Row(
                    children: [
                      const Icon(Icons.picture_as_pdf, color: Colors.red),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _truncate(item.uploadResult?.originalName ?? _basename(item.localFile.path)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 20,
                height: 20,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 12, color: Colors.white),
              ),
            ),
          ),
          if (item.isUploading)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0x66000000),
                child: Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),
          if (!item.isUploading && item.errorMessage != null)
            Positioned(
              left: 4,
              bottom: 4,
              child: GestureDetector(
                onTap: onRetry,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.refresh, size: 12, color: Colors.white),
                      SizedBox(width: 4),
                      Text(
                        'Retry',
                        style: TextStyle(fontSize: 10, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll('\\', '/');
    final segments = normalized.split('/');
    return segments.isEmpty ? path : segments.last;
  }

  String _truncate(String value) {
    if (value.length <= 20) return value;
    return '${value.substring(0, 20)}...';
  }
}
