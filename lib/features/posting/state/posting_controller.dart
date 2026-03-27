import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_local_store.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_repository.dart';

class PostingState {
  const PostingState({
    this.categories = const [],
    this.myListings = const [],
    this.myStatus = 'draft',
    this.currentStep = 0,
    this.isLoading = false,
    this.isSavingDraft = false,
    this.isPublishing = false,
    this.draftId,
    this.payload = const PostingDraftPayload(),
    this.preview,
    this.fieldErrors = const {},
    this.error,
    this.message,
  });

  final List<HomeCategory> categories;
  final List<ListingMine> myListings;
  final String myStatus;
  final int currentStep;
  final bool isLoading;
  final bool isSavingDraft;
  final bool isPublishing;
  final int? draftId;
  final PostingDraftPayload payload;
  final Map<String, dynamic>? preview;
  final Map<String, String> fieldErrors;
  final String? error;
  final String? message;

  PostingState copyWith({
    List<HomeCategory>? categories,
    List<ListingMine>? myListings,
    String? myStatus,
    int? currentStep,
    bool? isLoading,
    bool? isSavingDraft,
    bool? isPublishing,
    int? draftId,
    PostingDraftPayload? payload,
    Map<String, dynamic>? preview,
    Map<String, String>? fieldErrors,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
    bool clearDraftId = false,
  }) {
    return PostingState(
      categories: categories ?? this.categories,
      myListings: myListings ?? this.myListings,
      myStatus: myStatus ?? this.myStatus,
      currentStep: currentStep ?? this.currentStep,
      isLoading: isLoading ?? this.isLoading,
      isSavingDraft: isSavingDraft ?? this.isSavingDraft,
      isPublishing: isPublishing ?? this.isPublishing,
      draftId: clearDraftId ? null : (draftId ?? this.draftId),
      payload: payload ?? this.payload,
      preview: preview ?? this.preview,
      fieldErrors: fieldErrors ?? this.fieldErrors,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final postingControllerProvider =
    StateNotifierProvider<PostingController, PostingState>((ref) {
  return PostingController(
    repository: ref.watch(postingRepositoryProvider),
    localStore: ref.watch(postingLocalStoreProvider),
  );
});

class PostingController extends StateNotifier<PostingState> {
  PostingController({
    required PostingRepository repository,
    required PostingLocalStore localStore,
  })  : _repository = repository,
        _localStore = localStore,
        super(const PostingState());

  final PostingRepository _repository;
  final PostingLocalStore _localStore;
  Timer? _autosaveDebounce;

  static const _allowedMime = {'image/jpeg', 'image/jpg', 'image/png', 'image/webp'};
  static const _maxSize = 67108864;
  static const _maxImages = 10;

  Future<void> init() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final cats = await _repository.categories();
      final draftId = await _localStore.readDraftId();
      state = state.copyWith(
        isLoading: false,
        categories: cats,
        draftId: draftId,
      );
      await loadMyListings(status: state.myStatus);
      if (draftId != null) {
        await _loadDraftData(draftId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMyListings({required String status}) async {
    state = state.copyWith(isLoading: true, myStatus: status, clearError: true);
    try {
      final items = await _repository.myListings(status: status);
      state = state.copyWith(isLoading: false, myListings: items);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setStep(int value) {
    state = state.copyWith(currentStep: value);
    _scheduleAutosave();
  }

  void patchBasic({
    int? categoryId,
    String? title,
    String? description,
  }) {
    state = state.copyWith(
      payload: state.payload.copyWith(
        categoryId: categoryId,
        title: title,
        description: description,
      ),
      clearError: true,
    );
    _scheduleAutosave();
  }

  void patchPriceLocation({
    String? priceText,
    String? city,
    String? latText,
    String? lngText,
  }) {
    state = state.copyWith(
      payload: state.payload.copyWith(
        price: priceText != null ? double.tryParse(priceText) : state.payload.price,
        city: city,
        latitude: latText != null ? double.tryParse(latText) : state.payload.latitude,
        longitude: lngText != null ? double.tryParse(lngText) : state.payload.longitude,
      ),
      clearError: true,
    );
    _scheduleAutosave();
  }

  void patchContact({String? phone}) {
    state = state.copyWith(
      payload: state.payload.copyWith(contactPhone: phone),
      clearError: true,
    );
    _scheduleAutosave();
  }

  Future<void> addPhotos(List<XFile> files) async {
    if (state.payload.images.length + files.length > _maxImages) {
      state = state.copyWith(error: 'Maximum 10 photos allowed');
      return;
    }
    for (final file in files) {
      final size = await file.length();
      final mime = (file.mimeType ?? '').toLowerCase();
      if (size > _maxSize) {
        state = state.copyWith(error: 'Image is too large. Max size is 64MB');
        return;
      }
      if (!_allowedMime.contains(mime)) {
        state = state.copyWith(error: 'Only jpg, png, and webp are supported');
        return;
      }
    }

    state = state.copyWith(isSavingDraft: true, clearError: true);
    try {
      final uploaded = <PostingImage>[...state.payload.images];
      for (final file in files) {
        final image = await _repository.uploadImage(file);
        uploaded.add(
          PostingImage(url: image.url, sortOrder: uploaded.length),
        );
      }
      await _ensureDraftId();
      final normalized = _normalizeSort(uploaded);
      state = state.copyWith(
        isSavingDraft: false,
        payload: state.payload.copyWith(images: normalized),
      );
      await _repository.updateDraft(state.draftId!, state.payload.copyWith(images: normalized));
    } on ApiException catch (e) {
      state = state.copyWith(isSavingDraft: false, error: e.message);
    } catch (e) {
      state = state.copyWith(isSavingDraft: false, error: e.toString());
    }
  }

  Future<void> removePhoto(int index) async {
    final list = [...state.payload.images]..removeAt(index);
    final normalized = _normalizeSort(list);
    state = state.copyWith(payload: state.payload.copyWith(images: normalized));
    await saveDraftNow();
  }

  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    final items = [...state.payload.images];
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    final normalized = _normalizeSort(items);
    state = state.copyWith(payload: state.payload.copyWith(images: normalized));
    final draftId = state.draftId;
    if (draftId != null) {
      await _repository.reorderImages(draftId, normalized);
      await _repository.updateDraft(draftId, state.payload.copyWith(images: normalized));
    }
  }

  Future<void> setCurrentLocation({
    required double lat,
    required double lng,
  }) async {
    state = state.copyWith(
      payload: state.payload.copyWith(latitude: lat, longitude: lng),
    );
    _scheduleAutosave();
  }

  Future<void> saveDraftNow() async {
    await _autosave();
  }

  Future<void> loadPreview() async {
    try {
      await _ensureDraftId();
      await _repository.updateDraft(state.draftId!, state.payload);
      final data = await _repository.preview(state.draftId!);
      state = state.copyWith(preview: data, clearError: true);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<bool> publish() async {
    state = state.copyWith(
      isPublishing: true,
      fieldErrors: {},
      clearError: true,
      clearMessage: true,
    );
    try {
      await _ensureDraftId();
      await _repository.updateDraft(state.draftId!, state.payload);
      await _repository.publish(state.draftId!);
      state = state.copyWith(
        isPublishing: false,
        message: 'Listing published successfully',
        preview: null,
      );
      await _localStore.clearDraftId();
      await loadMyListings(status: 'active');
      _resetFlow();
      return true;
    } on DraftIncompleteException catch (e) {
      final errors = <String, String>{};
      for (final field in e.missingFields) {
        errors[field] = 'Required for publish';
      }
      state = state.copyWith(
        isPublishing: false,
        error: e.message,
        fieldErrors: errors,
      );
      return false;
    } on ApiException catch (e) {
      state = state.copyWith(isPublishing: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isPublishing: false, error: e.toString());
      return false;
    }
  }

  Future<void> unpublish(int id) async {
    try {
      await _repository.unpublish(id);
      await loadMyListings(status: state.myStatus);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> resumeDraft(int id) async {
    await _localStore.saveDraftId(id);
    state = state.copyWith(draftId: id, currentStep: 0);
    await _loadDraftData(id);
  }

  Future<void> _loadDraftData(int id) async {
    try {
      final json = await _repository.getById(id);
      final images = (json['images'] as List<dynamic>? ?? [])
          .map(
            (e) => PostingImage(
              url: (e as Map<String, dynamic>)['url'] as String? ?? '',
              sortOrder: (e['sort_order'] as num?)?.toInt() ?? 0,
            ),
          )
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      state = state.copyWith(
        payload: PostingDraftPayload(
          categoryId: (json['category_id'] as num?)?.toInt(),
          title: json['title'] as String?,
          description: json['description'] as String?,
          price: (json['price'] as num?)?.toDouble(),
          currency: (json['currency'] as String?) ?? 'USD',
          city: json['city'] as String?,
          contactPhone: json['contact_phone'] as String?,
          latitude: (json['latitude'] as num?)?.toDouble(),
          longitude: (json['longitude'] as num?)?.toDouble(),
          images: images,
        ),
      );
    } catch (_) {}
  }

  void _scheduleAutosave() {
    _autosaveDebounce?.cancel();
    _autosaveDebounce = Timer(const Duration(milliseconds: 600), () async {
      await _autosave();
    });
  }

  Future<void> _autosave() async {
    state = state.copyWith(isSavingDraft: true, clearError: true);
    try {
      await _ensureDraftId();
      await _repository.updateDraft(state.draftId!, state.payload);
      state = state.copyWith(isSavingDraft: false);
    } catch (e) {
      state = state.copyWith(isSavingDraft: false, error: e.toString());
    }
  }

  Future<void> _ensureDraftId() async {
    if (state.draftId != null) return;
    final id = await _repository.createDraft(state.payload);
    await _localStore.saveDraftId(id);
    state = state.copyWith(draftId: id);
  }

  List<PostingImage> _normalizeSort(List<PostingImage> input) {
    return input.asMap().entries.map((e) {
      return PostingImage(url: e.value.url, sortOrder: e.key);
    }).toList();
  }

  void _resetFlow() {
    state = state.copyWith(
      currentStep: 0,
      clearDraftId: true,
      payload: const PostingDraftPayload(),
      fieldErrors: {},
    );
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    super.dispose();
  }
}
