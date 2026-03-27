import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:marketplace_frontend/core/network/dio_client.dart';

final postingLocalStoreProvider = Provider<PostingLocalStore>((ref) {
  return PostingLocalStore(ref.watch(secureStorageProvider));
});

class PostingLocalStore {
  PostingLocalStore(this._storage);

  final dynamic _storage;
  static const _draftKey = 'posting_current_draft_id';

  Future<void> saveDraftId(int id) async {
    await _storage.write(key: _draftKey, value: id.toString());
  }

  Future<int?> readDraftId() async {
    final raw = await _storage.read(key: _draftKey);
    return int.tryParse(raw ?? '');
  }

  Future<void> clearDraftId() async {
    await _storage.delete(key: _draftKey);
  }
}
