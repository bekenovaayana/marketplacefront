import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/conversations/data/attachment_repository.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:marketplace_frontend/features/conversations/data/conversations_api.dart';
import 'package:marketplace_frontend/features/conversations/presentation/pending_attachment.dart';
import 'package:marketplace_frontend/features/conversations/state/conversations_controller.dart';
import 'package:marketplace_frontend/features/conversations/ui/widgets/chat_input_bar.dart';
import 'package:marketplace_frontend/features/conversations/ui/widgets/message_attachment_view.dart';
import 'package:marketplace_frontend/features/notifications/state/unread_notifications_provider.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class ConversationDetailPage extends ConsumerStatefulWidget {
  const ConversationDetailPage({
    super.key,
    required this.conversationId,
    this.peerTitle,
  });

  final int conversationId;
  final String? peerTitle;

  @override
  ConsumerState<ConversationDetailPage> createState() =>
      _ConversationDetailPageState();
}

class _ConversationDetailPageState
    extends ConsumerState<ConversationDetailPage> {
  static const _maxAttachmentCount = 5;
  static const _maxAttachmentSizeBytes = 20 * 1024 * 1024;
  static const _allowedMimes = <String>{
    'image/jpeg',
    'image/png',
    'image/webp',
    'application/pdf',
  };

  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  List<ConversationMessage> _messages = const [];
  List<PendingAttachment> _pendingAttachments = const [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isSending = false;
  int _page = 1;
  bool _hasMore = true;
  String? _error;
  static const _pageSize = 50;

  late final ConversationsApi _conversationsApi;
  late final AttachmentRepository _attachmentRepo;
  late final UnreadNotificationsCountController _unreadNotifications;

  @override
  void initState() {
    super.initState();
    _conversationsApi = ref.read(conversationsApiProvider);
    _attachmentRepo = ref.read(attachmentRepositoryProvider);
    _unreadNotifications = ref.read(unreadNotificationsCountProvider.notifier);
    _controller.addListener(_onTextChanged);
    Future.microtask(() async {
      await _loadMessages();
      await ref
          .read(conversationsControllerProvider.notifier)
          .markConversationRead(widget.conversationId);
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _page = 1;
      _hasMore = true;
    });
    try {
      final data = await _conversationsApi.listMessages(
        widget.conversationId,
        page: 1,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = data;
        _isLoading = false;
        _hasMore = data.length >= _pageSize;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Failed to load messages. Please retry.';
      });
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoadingMore || _isLoading || !_hasMore) return;
    setState(() => _isLoadingMore = true);
    try {
      final nextPage = _page + 1;
      final data = await _conversationsApi.listMessages(
        widget.conversationId,
        page: nextPage,
        pageSize: _pageSize,
      );
      if (!mounted) return;
      setState(() {
        _messages = [...data, ..._messages];
        _page = nextPage;
        _hasMore = data.length >= _pageSize;
        _isLoadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _isLoadingMore = false);
    }
  }

  @override
  void dispose() {
    final cid = widget.conversationId;
    unawaited(
      _conversationsApi.markConversationRead(cid).catchError((Object _) {}),
    );
    _unreadNotifications.refresh();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    final hasUploading = _pendingAttachments.any((a) => a.isUploading);
    final readyAttachments = _pendingAttachments
        .where((a) => a.isReady)
        .toList();
    if (_isSending || hasUploading) return;
    if (text.isEmpty && readyAttachments.isEmpty) return;
    final api = _conversationsApi;
    final requestId = api.buildIdempotencyKey();
    final attachmentPayload = readyAttachments
        .map(
          (item) => MessageAttachmentCreate(
            fileName: _fileNameFromUrl(item.uploadResult!.url),
            originalName: item.uploadResult!.originalName,
            mimeType: item.uploadResult!.contentType,
            fileSize: item.uploadResult!.sizeBytes,
            fileUrl: item.uploadResult!.url,
          ),
        )
        .toList();
    final optimistic = ConversationMessage(
      id: -DateTime.now().millisecondsSinceEpoch,
      senderId: 0,
      text: text,
      sentAt: DateTime.now(),
      isMine: true,
      attachments: attachmentPayload
          .map(
            (e) => MessageAttachment(
              id: 0,
              messageId: 0,
              fileName: e.fileName,
              originalName: e.originalName,
              mimeType: e.mimeType,
              fileSize: e.fileSize,
              fileUrl: e.fileUrl,
            ),
          )
          .toList(),
    );
    setState(() {
      _isSending = true;
      _messages = [..._messages, optimistic];
      _controller.clear();
      _pendingAttachments = const [];
    });
    try {
      final serverMsg = await api.sendMessage(
        conversationId: widget.conversationId,
        text: text.isEmpty ? null : text,
        attachments: attachmentPayload,
        idempotencyKey: requestId,
      );
      if (!mounted) return;
      if (serverMsg != null) {
        setState(() {
          _messages = [
            ..._messages.where((m) => m.id != optimistic.id),
            serverMsg,
          ];
        });
      } else {
        await _loadMessages();
      }
      await ref
          .read(conversationsControllerProvider.notifier)
          .refreshUnreadSummary();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _messages = _messages.where((m) => m.id != optimistic.id).toList();
      });
      showAppNotification(context, 'Failed to send message. Please retry.');
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final barTitle = widget.peerTitle?.trim().isNotEmpty == true
        ? widget.peerTitle!.trim()
        : 'Messages';
    return AppScaffold(
      title: barTitle,
      body: Column(
        children: [
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _loadMessages,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _messages.isEmpty
                ? const Center(child: Text('No messages'))
                : NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.pixels >=
                          notification.metrics.maxScrollExtent - 100) {
                        _loadMoreMessages();
                      }
                      return false;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      itemCount: _messages.length + (_isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= _messages.length) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          );
                        }
                        final msg = _messages[_messages.length - index - 1];
                        if (msg.text.trim().isEmpty &&
                            msg.attachments.isEmpty) {
                          return const SizedBox.shrink();
                        }
                        return _MessageBubbleRow(
                          msg: msg,
                          formatTime: _formatTime,
                        );
                      },
                    ),
                  ),
          ),
          ChatInputBar(
            controller: _controller,
            pendingAttachments: _pendingAttachments,
            onPickAttachment: _onPickAttachmentPressed,
            onRetryAttachment: _retryAttachment,
            onRemoveAttachment: _removeAttachment,
            onSend: _send,
            isSending: _isSending,
            isSendEnabled: _isSendEnabled,
            isAttachmentLimitReached:
                _pendingAttachments.length >= _maxAttachmentCount,
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final h = date.hour.toString().padLeft(2, '0');
    final m = date.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  bool get _isSendEnabled {
    final textReady = _controller.text.trim().isNotEmpty;
    final attachmentReady = _pendingAttachments.any((a) => a.isReady);
    final hasUploading = _pendingAttachments.any((a) => a.isUploading);
    return (textReady || attachmentReady) && !hasUploading;
  }

  Future<void> _onPickAttachmentPressed() async {
    if (_pendingAttachments.length >= _maxAttachmentCount) {
      _showMessage('Max 5 attachments');
      return;
    }
    if (!mounted) return;
    final choice = await showModalBottomSheet<String>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Image (camera)'),
                onTap: () => Navigator.of(context).pop('camera'),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Image (gallery)'),
                onTap: () => Navigator.of(context).pop('gallery'),
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf_outlined),
                title: const Text('Document'),
                onTap: () => Navigator.of(context).pop('document'),
              ),
            ],
          ),
        );
      },
    );
    if (choice == null) return;
    if (choice == 'camera') {
      final file = await _picker.pickImage(source: ImageSource.camera);
      if (file != null) {
        await _addAttachment(File(file.path), file.mimeType);
      }
      return;
    }
    if (choice == 'gallery') {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null) {
        await _addAttachment(File(file.path), file.mimeType);
      }
      return;
    }
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf'],
    );
    final picked = result?.files.single.path;
    if (picked != null) {
      await _addAttachment(File(picked), 'application/pdf');
    }
  }

  Future<void> _addAttachment(File file, String? mimeHint) async {
    if (_pendingAttachments.length >= _maxAttachmentCount) {
      _showMessage('Max 5 attachments');
      return;
    }
    final size = await file.length();
    if (size > _maxAttachmentSizeBytes) {
      _showMessage('File too large (max 20 MB)');
      return;
    }
    final resolvedMime = _resolveMime(file.path, mimeHint);
    if (!_allowedMimes.contains(resolvedMime)) {
      _showMessage('Unsupported file type');
      return;
    }
    final pending = PendingAttachment(localFile: file, isUploading: true);
    setState(() {
      _pendingAttachments = [..._pendingAttachments, pending];
    });
    await _uploadAt(_pendingAttachments.length - 1);
  }

  Future<void> _uploadAt(int index) async {
    if (index < 0 || index >= _pendingAttachments.length) return;
    final repo = _attachmentRepo;
    final api = _conversationsApi;
    final current = _pendingAttachments[index];
    _replaceAttachment(
      index,
      current.copyWith(
        isUploading: true,
        clearError: true,
        clearUploadResult: true,
      ),
    );
    try {
      final result = await repo.uploadAttachment(current.localFile);
      _replaceAttachment(
        index,
        current.copyWith(
          uploadResult: result,
          isUploading: false,
          clearError: true,
        ),
      );
    } on DioException catch (e) {
      final msg = api.mapAttachmentUploadError(e);
      _replaceAttachment(
        index,
        current.copyWith(
          isUploading: false,
          errorMessage: msg,
          clearUploadResult: true,
        ),
      );
      _showMessage(msg);
    } catch (_) {
      const msg = 'Upload failed, tap to retry';
      _replaceAttachment(
        index,
        current.copyWith(
          isUploading: false,
          errorMessage: msg,
          clearUploadResult: true,
        ),
      );
      _showMessage(msg);
    }
  }

  Future<void> _retryAttachment(int index) async {
    await _uploadAt(index);
  }

  void _removeAttachment(int index) {
    if (index < 0 || index >= _pendingAttachments.length) return;
    setState(() {
      final next = List<PendingAttachment>.from(_pendingAttachments);
      next.removeAt(index);
      _pendingAttachments = next;
    });
  }

  void _replaceAttachment(int index, PendingAttachment value) {
    if (!mounted || index < 0 || index >= _pendingAttachments.length) return;
    setState(() {
      final next = List<PendingAttachment>.from(_pendingAttachments);
      next[index] = value;
      _pendingAttachments = next;
    });
  }

  String _resolveMime(String path, String? mimeHint) {
    final normalized = (mimeHint ?? '').toLowerCase();
    if (_allowedMimes.contains(normalized)) return normalized;
    final lower = path.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    return normalized;
  }

  String _fileNameFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri != null && uri.pathSegments.isNotEmpty) {
      return uri.pathSegments.last;
    }
    final segments = url.split('/');
    return segments.isEmpty ? url : segments.last;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    showAppNotification(context, message);
  }
}

/// One [Row] per message so alignment is correct with [ListView.reverse].
class _MessageBubbleRow extends StatelessWidget {
  const _MessageBubbleRow({
    required this.msg,
    required this.formatTime,
  });

  final ConversationMessage msg;
  final String Function(DateTime date) formatTime;

  @override
  Widget build(BuildContext context) {
    final mine = msg.layoutIsMine;
    final maxW = MediaQuery.sizeOf(context).width * 0.78;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bubbleColor = mine
        ? (isDark
            ? Theme.of(context).colorScheme.primaryContainer
            : const Color(0xFFDCF8C6))
        : Colors.grey.shade200;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Row(
        mainAxisAlignment:
            mine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Flexible(
            child: Container(
              constraints: BoxConstraints(maxWidth: maxW),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(mine ? 12 : 4),
                  bottomRight: Radius.circular(mine ? 4 : 12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (msg.attachments.isNotEmpty) ...[
                    ...msg.attachments.map(
                      (attachment) => Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: MessageAttachmentView(attachment: attachment),
                      ),
                    ),
                  ],
                  if (msg.text.trim().isNotEmpty) ...[
                    Text(msg.text),
                    const SizedBox(height: 4),
                  ],
                  Text(
                    formatTime(msg.sentAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey.shade700,
                        ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
