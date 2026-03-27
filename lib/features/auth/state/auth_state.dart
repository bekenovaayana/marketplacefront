import 'package:marketplace_frontend/features/auth/models/auth_user.dart';

enum AuthMode { guest, authenticated }

class AuthState {
  const AuthState({
    this.isLoading = false,
    this.user,
    this.error,
    this.initialized = false,
    this.mode = AuthMode.guest,
  });

  final bool isLoading;
  final bool initialized;
  final AuthUser? user;
  final String? error;
  final AuthMode mode;

  bool get isAuthenticated => mode == AuthMode.authenticated && user != null;
  bool get isGuest => mode == AuthMode.guest;

  AuthState copyWith({
    bool? isLoading,
    bool? initialized,
    AuthUser? user,
    String? error,
    AuthMode? mode,
    bool clearError = false,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      initialized: initialized ?? this.initialized,
      user: user ?? this.user,
      error: clearError ? null : (error ?? this.error),
      mode: mode ?? this.mode,
    );
  }
}
