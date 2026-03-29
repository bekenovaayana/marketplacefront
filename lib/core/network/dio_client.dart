import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/fastapi_detail.dart';
import 'package:marketplace_frontend/core/config/env.dart';
import 'package:marketplace_frontend/core/network/auth_interceptor.dart';
import 'package:marketplace_frontend/core/storage/token_storage.dart';

final sessionExpiredProvider = Provider<ValueNotifier<int>>((ref) {
  final notifier = ValueNotifier<int>(0);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final reauthCoordinatorProvider = Provider<ReauthCoordinator>((ref) {
  final coordinator = ReauthCoordinator();
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final tokenStorageProvider = Provider<TokenStorage>((ref) {
  return TokenStorage(ref.watch(secureStorageProvider));
});

final dioProvider = Provider<Dio>((ref) {
  final tokenStorage = ref.watch(tokenStorageProvider);
  final coordinator = ref.watch(reauthCoordinatorProvider);
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
      headers: const {'Content-Type': 'application/json'},
    ),
  );
  dio.interceptors.add(AuthInterceptor(tokenStorage));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        if (kDebugMode &&
            (options.path.contains('/auth/login') ||
                options.path.contains('/auth/register') ||
                options.path.contains('/auth/me') ||
                options.path.contains('/users/me'))) {
          debugPrint('REQ ${options.method} ${options.baseUrl}${options.path}');
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        final path = response.requestOptions.path;
        if (kDebugMode &&
            (path.contains('/auth/login') ||
                path.contains('/auth/register') ||
                path.contains('/users/me'))) {
          debugPrint(
            'RES ${response.statusCode} ${response.requestOptions.baseUrl}$path',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final status = error.response?.statusCode;
        if (kDebugMode &&
            (options.path.contains('/auth/login') ||
                options.path.contains('/auth/register') ||
                options.path.contains('/auth/me') ||
                options.path.contains('/users/me'))) {
          debugPrint('ERR $status ${options.baseUrl}${options.path}');
        }
        final hasAuthHeader =
            (options.headers['Authorization']?.toString().isNotEmpty ?? false);
        final retried = options.extra['reauth_retried'] == true;
        if (status == 401 && hasAuthHeader) {
          if (retried) {
            await tokenStorage.clear();
            ref.read(sessionExpiredProvider).value++;
            handler.next(error);
            return;
          }
          await _retryAfterReauth(
            ref: ref,
            dio: dio,
            tokenStorage: tokenStorage,
            coordinator: coordinator,
            error: error,
            handler: handler,
          );
          return;
        }
        final detail = error.response?.data;
        if (detail is Map<String, dynamic>) {
          final parsed = messageFromFastApiDetail(detail['detail']);
          if (parsed != null && parsed.isNotEmpty) {
            return handler.reject(
              error.copyWith(
                error: ApiException(
                  parsed,
                  statusCode: error.response?.statusCode,
                ),
              ),
            );
          }
          final message = detail['detail'];
          if (message is String && message.isNotEmpty) {
            return handler.reject(
              error.copyWith(
                error: ApiException(
                  message,
                  statusCode: error.response?.statusCode,
                ),
              ),
            );
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
});

Future<void> _retryAfterReauth({
  required Ref ref,
  required Dio dio,
  required TokenStorage tokenStorage,
  required ReauthCoordinator coordinator,
  required DioException error,
  required ErrorInterceptorHandler handler,
}) async {
  final authorized = await coordinator.requestReauth();
  if (!authorized) {
    await tokenStorage.clear();
    ref.read(sessionExpiredProvider).value++;
    handler.next(error);
    return;
  }
  final token = await tokenStorage.readAccessToken();
  if (token == null || token.isEmpty) {
    handler.next(error);
    return;
  }
  final options = error.requestOptions;
  options.headers['Authorization'] = 'Bearer $token';
  options.extra['reauth_retried'] = true;
  try {
    final response = await dio.fetch(options);
    handler.resolve(response);
  } on DioException catch (e) {
    handler.next(e);
  }
}

class ReauthCoordinator {
  final ValueNotifier<int> promptTicker = ValueNotifier<int>(0);
  Completer<bool>? _pending;

  Future<bool> requestReauth() {
    if (_pending != null) return _pending!.future;
    _pending = Completer<bool>();
    promptTicker.value++;
    return _pending!.future
        .timeout(const Duration(minutes: 2), onTimeout: () => false)
        .whenComplete(() {
          _pending = null;
        });
  }

  void resolve(bool success) {
    if (_pending == null || _pending!.isCompleted) return;
    _pending!.complete(success);
  }

  void dispose() {
    promptTicker.dispose();
  }
}
