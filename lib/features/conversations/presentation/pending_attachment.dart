import 'dart:io';

import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';

class PendingAttachment {
  const PendingAttachment({
    required this.localFile,
    this.uploadResult,
    this.isUploading = false,
    this.errorMessage,
  });

  final File localFile;
  final AttachmentUploadResult? uploadResult;
  final bool isUploading;
  final String? errorMessage;

  bool get isReady => uploadResult != null && !isUploading && errorMessage == null;

  PendingAttachment copyWith({
    File? localFile,
    AttachmentUploadResult? uploadResult,
    bool? isUploading,
    String? errorMessage,
    bool clearUploadResult = false,
    bool clearError = false,
  }) {
    return PendingAttachment(
      localFile: localFile ?? this.localFile,
      uploadResult: clearUploadResult ? null : (uploadResult ?? this.uploadResult),
      isUploading: isUploading ?? this.isUploading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
