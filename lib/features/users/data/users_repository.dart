import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/features/users/data/users_api.dart';

final usersRepositoryProvider = Provider<UsersRepository>((ref) {
  return UsersRepository(ref.watch(usersApiProvider));
});

class UsersRepository {
  UsersRepository(this._api);

  final UsersApi _api;

  Future<void> blockUser(int userId) => _api.blockUser(userId);
}
