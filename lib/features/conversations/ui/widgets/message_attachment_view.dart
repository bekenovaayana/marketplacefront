import 'package:flutter/material.dart';
import 'package:marketplace_frontend/core/config/env.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:photo_view/photo_view.dart';
import 'package:url_launcher/url_launcher.dart';

class MessageAttachmentView extends StatelessWidget {
  const MessageAttachmentView({
    super.key,
    required this.attachment,
  });

  final MessageAttachment attachment;

  @override
  Widget build(BuildContext context) {
    if (attachment.mimeType.startsWith('image/')) {
      final imageUrl = _absoluteUrl(attachment.fileUrl);
      return GestureDetector(
        onTap: () => _openImageViewer(context, imageUrl),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            width: 220,
            height: 160,
            child: Image.network(
              imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: Colors.grey.shade300,
                alignment: Alignment.center,
                child: const Icon(Icons.broken_image_outlined),
              ),
            ),
          ),
        ),
      );
    }

    final isPdf = attachment.mimeType == 'application/pdf';
    if (isPdf) {
      return GestureDetector(
        onTap: () => _openPdf(),
        child: Container(
          width: 220,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.picture_as_pdf, color: Colors.red),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment.originalName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatFileSize(attachment.fileSize),
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Future<void> _openPdf() async {
    final uri = Uri.parse(_absoluteUrl(attachment.fileUrl));
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  void _openImageViewer(BuildContext context, String imageUrl) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(8),
        child: SizedBox.expand(
          child: Stack(
            children: [
              PhotoView(
                imageProvider: NetworkImage(imageUrl),
                backgroundDecoration: const BoxDecoration(color: Colors.black),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _absoluteUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    return '${Env.baseUrl}$path';
  }
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}
