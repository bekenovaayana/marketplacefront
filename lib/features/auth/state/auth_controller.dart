import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/auth/data/auth_repository.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/favorites/state/favorite_stale_guard.dart';

void _authDebugPrint(String message) {
  // ignore: avoid_print
  print(message);
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      repository: ref.watch(authRepositoryProvider),
      reauthCoordinator: ref.watch(reauthCoordinatorProvider),
      onSessionCleared: () {
        ref.read(favoriteStaleGuardProvider.notifier).clear();
      },
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required ReauthCoordinator reauthCoordinator,
    this.onSessionCleared,
  }) : _repository = repository,
       _reauthCoordinator = reauthCoordinator,
       super(const AuthState());

  final AuthRepository _repository;
  final ReauthCoordinator _reauthCoordinator;
  final void Function()? onSessionCleared;

  Future<void> initialize() async {
    if (state.initialized) {
      return;
    }
    state = state.copyWith(isInitializing: true, clearError: true);
    try {
      final user = await _repository.restoreSession();
      state = state.copyWith(
        user: user,
        mode: user == null ? AuthMode.guest : AuthMode.authenticated,
      );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('AUTH INIT ERROR: $e\n$st');
      }
      state = state.copyWith(
        user: null,
        mode: AuthMode.guest,
        error: e.toString(),
      );
    } finally {
      state = state.copyWith(initialized: true, isInitializing: false);
    }
  }

  Future<bool> login({required String email, required String password}) async {
    _authDebugPrint('LOGIN START');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.login(email: email, password: password);
      _authDebugPrint('LOGIN SUCCESS');
      state = state.copyWith(
        user: session.user,
        mode: AuthMode.authenticated,
      );
      try {
        _reauthCoordinator.resolve(true);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('reauthCoordinator.resolve after login: $e\n$st');
        }
      }
      return true;
    } on ApiException catch (e) {
      _authDebugPrint('LOGIN ERROR: $e');
      state = state.copyWith(error: e.message);
      return false;
    } catch (e, st) {
      _authDebugPrint('LOGIN ERROR: $e');
      if (kDebugMode) {
        debugPrint('$st');
      }
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    _authDebugPrint('REGISTER START');
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      final session = await _repository.login(email: email, password: password);
      _authDebugPrint('REGISTER SUCCESS');
      state = state.copyWith(
        user: session.user,
        mode: AuthMode.authenticated,
      );
      try {
        _reauthCoordinator.resolve(true);
      } catch (e, st) {
        if (kDebugMode) {
          debugPrint('reauthCoordinator.resolve after register: $e\n$st');
        }
      }
      return true;
    } on ApiException catch (e) {
      _authDebugPrint('REGISTER ERROR: $e');
      state = state.copyWith(error: e.message);
      return false;
    } catch (e, st) {
      _authDebugPrint('REGISTER ERROR: $e');
      if (kDebugMode) {
        debugPrint('$st');
      }
      state = state.copyWith(error: e.toString());
      return false;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    onSessionCleared?.call();
    state = state.copyWith(
      user: null,
      initialized: true,
      isLoading: false,
      clearError: true,
      mode: AuthMode.guest,
    );
  }

  Future<void> handleUnauthorized() async {
    await _repository.logout();
    onSessionCleared?.call();
    _reauthCoordinator.resolve(false);
    state = state.copyWith(
      user: null,
      initialized: true,
      isLoading: false,
      clearError: true,
      mode: AuthMode.guest,
    );
  }
}
