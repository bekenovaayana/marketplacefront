import 'package:dio/dio.dart';
import 'package:marketplace_frontend/core/storage/token_storage.dart';

/// Attaches **Authorization: Bearer** plus the stored access token when a token exists,
/// except for requests marked with **`Options(extra: {'publicEndpoint': true})`**
/// (e.g. [POST /auth/login], [POST /auth/register]) so stale tokens are not sent.
///
/// ### Do **not** use [publicEndpoint] for “semi-public” listing APIs
/// The backend treats missing auth as **guest** (`is_favorite` false). These must
/// receive Bearer when the user is logged in:
/// - [GET /home], [GET /listings], [GET /listings/:id]
///
/// Access and optional **refresh** tokens are stored in [TokenStorage]; the
/// interceptor only sends the **access** token. Refresh flows (if the backend
/// exposes them) should run in one place and avoid infinite 401 loops.
///
/// ### Always authenticated (never `publicEndpoint`)
/// - [GET /auth/me], [GET /users/me], profile [PATCH /users/me], uploads
/// - [GET /conversations], [GET /conversations/by-listing/:id], [POST /conversations/from-listing]
/// - [GET /messages/:id], [POST /messages], [POST /messages/:id/mark-read]
/// - [GET /chats/unread-summary]
/// - [GET/POST/DELETE /favorites…], [POST …/contact-intent]
/// - Notifications, payments, posting drafts as applicable
///
/// ### Guest (no token): no `Authorization` header
/// Typical: [GET /home], [GET /listings], [GET /categories] — server treats as guest
/// (`is_favorite` / `is_owner` reflect that).
class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenStorage);

  final TokenStorage _tokenStorage;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final isPublic = options.extra['publicEndpoint'] == true;
    if (isPublic) {
      options.headers.remove('Authorization');
      handler.next(options);
      return;
    }
    final token = await _tokenStorage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }
}
