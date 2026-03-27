import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http_parser/http_parser.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/conversations/data/conversation_models.dart';
import 'package:mime/mime.dart';

final attachmentRepositoryProvider = Provider<AttachmentRepository>((ref) {
  return AttachmentRepository(ref.watch(dioProvider));
});

class AttachmentRepository {
  AttachmentRepository(this._dio);

  final Dio _dio;

  Future<AttachmentUploadResult> uploadAttachment(File file) async {
    final mimeType = _detectMime(file.path);
    final multipart = await MultipartFile.fromFile(
      file.path,
      filename: file.uri.pathSegments.isEmpty ? 'file' : file.uri.pathSegments.last,
      contentType: _toMediaType(mimeType),
    );
    final response = await _dio.post(
      '/attachments',
      data: FormData.fromMap({'file': multipart}),
      options: Options(contentType: 'multipart/form-data'),
    );
    return AttachmentUploadResult.fromJson(response.data as Map<String, dynamic>);
  }

  String _detectMime(String path) {
    return lookupMimeType(path) ?? 'application/octet-stream';
  }

  MediaType _toMediaType(String mime) {
    final parts = mime.split('/');
    if (parts.length != 2) return MediaType('application', 'octet-stream');
    return MediaType(parts.first, parts.last);
  }
}
