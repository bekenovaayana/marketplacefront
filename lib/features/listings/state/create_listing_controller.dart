import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/listings/data/create_listing_repository.dart';

class CreateListingState {
  const CreateListingState({
    this.categories = const [],
    this.selectedCategoryId,
    this.images = const [],
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.message,
  });

  final List<HomeCategory> categories;
  final int? selectedCategoryId;
  final List<XFile> images;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final String? message;

  CreateListingState copyWith({
    List<HomeCategory>? categories,
    int? selectedCategoryId,
    List<XFile>? images,
    double? latitude,
    double? longitude,
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    String? message,
    bool clearError = false,
    bool clearMessage = false,
  }) {
    return CreateListingState(
      categories: categories ?? this.categories,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      images: images ?? this.images,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
    );
  }
}

final createListingControllerProvider =
    StateNotifierProvider<CreateListingController, CreateListingState>((ref) {
  return CreateListingController(ref.watch(createListingRepositoryProvider));
});

class CreateListingController extends StateNotifier<CreateListingState> {
  CreateListingController(this._repository) : super(const CreateListingState());

  final CreateListingRepository _repository;

  static const maxImages = 10;
  static const maxSizeBytes = 67108864;
  static const allowedMime = {'image/jpeg', 'image/png', 'image/webp'};

  Future<void> init() async {
    if (state.categories.isNotEmpty) {
      return;
    }
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final categories = await _repository.categories();
      state = state.copyWith(
        isLoading: false,
        categories: categories,
        selectedCategoryId: categories.isNotEmpty ? categories.first.id : null,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(int? value) {
    state = state.copyWith(selectedCategoryId: value);
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(latitude: latitude, longitude: longitude);
  }

  Future<void> addImages(List<XFile> newFiles) async {
    final merged = [...state.images, ...newFiles];
    if (merged.length > maxImages) {
      state = state.copyWith(error: 'Maximum 10 photos allowed');
      return;
    }

    for (final file in newFiles) {
      final size = await file.length();
      if (size > maxSizeBytes) {
        state = state.copyWith(error: 'Image ${file.name} is larger than 64MB');
        return;
      }
      if (!allowedMime.contains((file.mimeType ?? '').toLowerCase())) {
        state = state.copyWith(error: 'Only jpg, png, and webp are supported');
        return;
      }
    }
    state = state.copyWith(images: merged, clearError: true);
  }

  void removeImageAt(int index) {
    final images = [...state.images]..removeAt(index);
    state = state.copyWith(images: images);
  }

  Future<bool> submit({
    required String title,
    required String description,
    required String priceText,
    required String city,
    required String phone,
  }) async {
    final categoryId = state.selectedCategoryId;
    if (categoryId == null) {
      state = state.copyWith(error: 'Category is required');
      return false;
    }
    final price = double.tryParse(priceText);
    if (price == null || price <= 0) {
      state = state.copyWith(error: 'Enter a valid price');
      return false;
    }

    state = state.copyWith(isSubmitting: true, clearError: true, clearMessage: true);
    try {
      final urls = <String>[];
      for (final file in state.images) {
        final uploaded = await _repository.uploadImage(file);
        urls.add(uploaded.url);
      }
      await _repository.createListing(
        CreateListingInput(
          categoryId: categoryId,
          title: title,
          description: description,
          price: price,
          currency: 'USD',
          city: city,
          contactPhone: phone,
          latitude: state.latitude,
          longitude: state.longitude,
          imageUrls: urls,
        ),
      );
      state = state.copyWith(
        isSubmitting: false,
        message: 'Listing created successfully',
        images: const [],
      );
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.message);
      return false;
    } catch (e) {
      state = state.copyWith(isSubmitting: false, error: e.toString());
      return false;
    }
  }
}
