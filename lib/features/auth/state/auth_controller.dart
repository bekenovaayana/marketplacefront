import 'package:flutter_riverpod/legacy.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';
import 'package:marketplace_frontend/features/auth/data/auth_repository.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) {
    return AuthController(
      repository: ref.watch(authRepositoryProvider),
      reauthCoordinator: ref.watch(reauthCoordinatorProvider),
    );
  },
);

class AuthController extends StateNotifier<AuthState> {
  AuthController({
    required AuthRepository repository,
    required ReauthCoordinator reauthCoordinator,
  }) : _repository = repository,
       _reauthCoordinator = reauthCoordinator,
       super(const AuthState());

  final AuthRepository _repository;
  final ReauthCoordinator _reauthCoordinator;

  Future<void> initialize() async {
    if (state.initialized) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    final user = await _repository.restoreSession();
    state = state.copyWith(
      isLoading: false,
      initialized: true,
      user: user,
      mode: user == null ? AuthMode.guest : AuthMode.authenticated,
    );
  }

  Future<bool> login({required String email, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final session = await _repository.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        user: session.user,
        mode: AuthMode.authenticated,
      );
      _reauthCoordinator.resolve(true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repository.register(
        fullName: fullName,
        email: email,
        password: password,
      );
      final session = await _repository.login(email: email, password: password);
      state = state.copyWith(
        isLoading: false,
        user: session.user,
        mode: AuthMode.authenticated,
      );
      _reauthCoordinator.resolve(true);
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isLoading: false, error: e.message);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = state.copyWith(
      user: null,
      initialized: true,
      clearError: true,
      mode: AuthMode.guest,
    );
  }

  Future<void> handleUnauthorized() async {
    await _repository.logout();
    _reauthCoordinator.resolve(false);
    state = state.copyWith(
      user: null,
      initialized: true,
      clearError: true,
      mode: AuthMode.guest,
    );
  }
}
