import 'package:marketplace_frontend/features/auth/models/auth_user.dart';

enum AuthMode { guest, authenticated }

/// Sentinel so [AuthState.copyWith] can set `user` to `null` (logout / guest).
const Object _kUserKeep = Object();

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.isInitializing = false,
    this.user,
    this.error,
    this.initialized = false,
    this.mode = AuthMode.guest,
  });

  final bool isLoading;
  /// Session restore on cold start — separate from [isLoading] (login/register).
  final bool isInitializing;
  final bool initialized;
  final AuthUser? user;
  final String? error;
  final AuthMode mode;

  bool get isAuthenticated => mode == AuthMode.authenticated && user != null;
  bool get isGuest => mode == AuthMode.guest;

  AuthState copyWith({
    bool? isLoading,
    bool? isInitializing,
    bool? initialized,
    Object? user = _kUserKeep,
    String? error,
    AuthMode? mode,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      isInitializing: isInitializing ?? this.isInitializing,
      initialized: initialized ?? this.initialized,
      user: identical(user, _kUserKeep) ? this.user : user as AuthUser?,
      error: clearError ? null : (error ?? this.error),
      mode: mode ?? this.mode,
    );
  }
}
