import 'dart:async';

import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/core/errors/api_field_errors.dart';
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

  static const _allowedMime = {
    'image/jpeg',
    'image/jpg',
    'image/png',
    'image/webp',
    'video/mp4',
    'video/webm',
    'video/quicktime',
  };
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
      if (draftId != null) {
        await _loadDraftData(draftId);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      return;
    }

    try {
      final items = await _repository.myListings(status: state.myStatus);
      state = state.copyWith(myListings: items);
    } catch (_) {
      // Don't block the create flow if /listings/me fails (guest race, expired token, etc.).
      // User can open «My listings» to retry via loadMyListings.
    }
  }

  /// Fresh draft for the standalone «Post a Listing» flow: parallel categories + draft.
  Future<void> initForNewListing() async {
    _autosaveDebounce?.cancel();
    await _localStore.clearDraftId();
    state = const PostingState(
      isLoading: true,
      payload: PostingDraftPayload(currency: 'USD'),
    );
    try {
      final results = await Future.wait<Object>([
        _repository.categories(),
        _repository.createDraft(const PostingDraftPayload(currency: 'USD')),
      ]);
      final cats = results.first as List<HomeCategory>;
      final id = results.last as int;
      await _localStore.saveDraftId(id);
      state = state.copyWith(
        isLoading: false,
        categories: cats,
        draftId: id,
        payload: const PostingDraftPayload(currency: 'USD'),
        currentStep: 0,
        clearError: true,
      );
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(
        e,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMyListings({required String status}) async {
    state = state.copyWith(isLoading: true, myStatus: status, clearError: true);
    try {
      final items = await _repository.myListings(status: status);
      state = state.copyWith(isLoading: false, myListings: items);
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(
        e,
        isLoading: false,
      );
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
      fieldErrors: const {},
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
        price: priceText != null ? _parsePriceInput(priceText) : state.payload.price,
        city: city,
        latitude: latText != null ? double.tryParse(latText) : state.payload.latitude,
        longitude: lngText != null ? double.tryParse(lngText) : state.payload.longitude,
      ),
      fieldErrors: const {},
      clearError: true,
    );
    _scheduleAutosave();
  }

  void patchContact({String? phone}) {
    state = state.copyWith(
      payload: state.payload.copyWith(contactPhone: _normalizeKgPhone(phone)),
      fieldErrors: const {},
      clearError: true,
    );
    _scheduleAutosave();
  }

  Future<void> addPhotos(List<XFile> files) async {
    if (state.payload.images.length + files.length > _maxImages) {
      state = state.copyWith(error: 'Maximum 10 media files allowed');
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
        final ext = file.name.toLowerCase();
        final isKnownExt = ext.endsWith('.jpg') ||
            ext.endsWith('.jpeg') ||
            ext.endsWith('.png') ||
            ext.endsWith('.webp') ||
            ext.endsWith('.mp4') ||
            ext.endsWith('.webm') ||
            ext.endsWith('.mov');
        if (!isKnownExt) {
          state = state.copyWith(error: 'Only jpg, png, webp, mp4, webm and mov are supported');
          return;
        }
      }
      if (!_allowedMime.contains(mime) && (file.mimeType ?? '').isNotEmpty) {
        state = state.copyWith(error: 'Only jpg, png, webp, mp4, webm and mov are supported');
        return;
      }
    }

    state = state.copyWith(isSavingDraft: true, clearError: true);
    try {
      final uploaded = <PostingImage>[...state.payload.images];
      for (final file in files) {
        await _ensureDraftId();
        final dynamic repo = _repository;
        PostingImage media;
        try {
          media = await repo.uploadListingMedia(
            listingId: state.draftId!,
            file: file,
          ) as PostingImage;
        } catch (_) {
          media = await _repository.uploadImage(file);
        }
        uploaded.add(PostingImage(
          url: media.url,
          sortOrder: uploaded.length,
        ));
      }
      final normalized = _normalizeSort(uploaded);
      state = state.copyWith(
        isSavingDraft: false,
        payload: state.payload.copyWith(images: normalized),
      );
      await _repository.updateDraft(state.draftId!, state.payload.copyWith(images: normalized));
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(
        e,
        isSavingDraft: false,
      );
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
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(e);
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
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(
        e,
        isPublishing: false,
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

  Future<void> deleteMyListing(int id) async {
    try {
      final dynamic repo = _repository;
      try {
        await repo.deleteListing(id);
      } catch (_) {
        await _repository.unpublish(id);
      }
      await loadMyListings(status: state.myStatus);
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(e);
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
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
          price: _toInt(json['price']),
          currency: (json['currency'] as String?) ?? 'USD',
          city: json['city'] as String?,
          contactPhone: json['contact_phone'] as String?,
          latitude: _toDouble(json['latitude']),
          longitude: _toDouble(json['longitude']),
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
    } on ApiFieldErrorsException catch (e) {
      _applyFieldErrors(
        e,
        isSavingDraft: false,
      );
    } catch (e) {
      state = state.copyWith(isSavingDraft: false, error: e.toString());
    }
  }

  Future<void> _ensureDraftId() async {
    if (state.draftId != null && state.draftId! > 0) return;
    final id = await _repository.createDraft(state.payload);
    if (id <= 0) {
      throw const ApiException(
        'Could not create listing draft. Check connection and try again.',
      );
    }
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

  static int? _parsePriceInput(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(normalized);
    if (asDouble == null) return null;
    if (asDouble != asDouble.toInt().toDouble()) return null;
    return asDouble.toInt();
  }

  static int? _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) {
      if (value != value.toInt()) return null;
      return value.toInt();
    }
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      final asInt = int.tryParse(normalized);
      if (asInt != null) return asInt;
      final asDouble = double.tryParse(normalized);
      if (asDouble == null) return null;
      if (asDouble != asDouble.toInt().toDouble()) return null;
      return asDouble.toInt();
    }
    return null;
  }

  static double? _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
  }

  static String? _normalizeKgPhone(String? phone) {
    if (phone == null) return null;
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return null;
    if (digits.startsWith('996')) {
      final rest = digits.substring(3);
      return '+996$rest';
    }
    if (digits.length <= 9) {
      return '+996$digits';
    }
    return '+$digits';
  }

  void _applyFieldErrors(
    ApiFieldErrorsException e, {
    bool? isLoading,
    bool? isSavingDraft,
    bool? isPublishing,
  }) {
    final fallback = e.fieldErrors.values.isNotEmpty
        ? e.fieldErrors.values.first
        : 'Validation failed. Please check the entered data.';
    state = state.copyWith(
      isLoading: isLoading ?? state.isLoading,
      isSavingDraft: isSavingDraft ?? state.isSavingDraft,
      isPublishing: isPublishing ?? state.isPublishing,
      fieldErrors: e.fieldErrors,
      error: (e.rawMessage != null && e.rawMessage!.trim().isNotEmpty)
          ? e.rawMessage!.trim()
          : fallback,
    );
  }

  @override
  void dispose() {
    _autosaveDebounce?.cancel();
    super.dispose();
  }
}
