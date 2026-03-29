import 'package:flutter/foundation.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';

/// Subset of [PostingState] for the create-flow UI.
///
/// Equality ignores text fields (title, description, price, city, coords, phone)
/// so [patchBasic]/[patchPriceLocation] updates that only change those do not
/// rebuild the wizard while the user is typing — [TextEditingController]s stay
/// mounted and keep focus.
@immutable
class PostingFlowUiSlice {
  const PostingFlowUiSlice({
    required this.currentStep,
    required this.categories,
    required this.myListings,
    required this.myStatus,
    required this.isLoading,
    required this.isSavingDraft,
    required this.isPublishing,
    required this.mediaUploadFraction,
    required this.draftId,
    required this.categoryId,
    required this.images,
    required this.currency,
    required this.preview,
    required this.fieldErrors,
    required this.error,
    required this.message,
  });

  final int currentStep;
  final List<HomeCategory> categories;
  final List<ListingMine> myListings;
  final String myStatus;
  final bool isLoading;
  final bool isSavingDraft;
  final bool isPublishing;
  final double? mediaUploadFraction;
  final int? draftId;
  final num? categoryId;
  final List<PostingImage> images;
  final String currency;
  final Map<String, dynamic>? preview;
  final Map<String, String> fieldErrors;
  final String? error;
  final String? message;

  factory PostingFlowUiSlice.from(PostingState s) {
    return PostingFlowUiSlice(
      currentStep: s.currentStep,
      categories: s.categories,
      myListings: s.myListings,
      myStatus: s.myStatus,
      isLoading: s.isLoading,
      isSavingDraft: s.isSavingDraft,
      isPublishing: s.isPublishing,
      mediaUploadFraction: s.mediaUploadFraction,
      draftId: s.draftId,
      categoryId: s.payload.categoryId,
      images: s.payload.images,
      currency: s.payload.currency,
      preview: s.preview,
      fieldErrors: s.fieldErrors,
      error: s.error,
      message: s.message,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PostingFlowUiSlice &&
        other.currentStep == currentStep &&
        listEquals(other.categories, categories) &&
        listEquals(other.myListings, myListings) &&
        other.myStatus == myStatus &&
        other.isLoading == isLoading &&
        other.isSavingDraft == isSavingDraft &&
        other.isPublishing == isPublishing &&
        other.mediaUploadFraction == mediaUploadFraction &&
        other.draftId == draftId &&
        other.categoryId == categoryId &&
        listEquals(other.images, images) &&
        other.currency == currency &&
        mapEquals(other.preview, preview) &&
        mapEquals(other.fieldErrors, fieldErrors) &&
        other.error == error &&
        other.message == message;
  }

  @override
  int get hashCode => Object.hash(
        currentStep,
        Object.hashAll(categories),
        Object.hashAll(myListings),
        myStatus,
        isLoading,
        isSavingDraft,
        isPublishing,
        mediaUploadFraction,
        draftId,
        categoryId,
        Object.hashAll(images),
        currency,
        preview,
        fieldErrors,
        error,
        message,
      );
}
