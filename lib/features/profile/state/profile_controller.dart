import 'package:flutter_riverpod/legacy.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/api_exception.dart';
import 'package:marketplace_frontend/features/profile/data/profile_repository.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';

class ProfileState {
  const ProfileState({
    this.isLoading = false,
    this.isSaving = false,
    this.isUploadingAvatar = false,
    this.isChangingPassword = false,
    this.profile,
    this.completeness,
    this.error,
    this.message,
    this.fieldErrors = const {},
    this.citySuggestions = const [],
  });

  final bool isLoading;
  final bool isSaving;
  final bool isUploadingAvatar;
  final bool isChangingPassword;
  final UserMeResponse? profile;
  final ProfileCompletenessDto? completeness;
  final String? error;
  final String? message;
  final Map<String, String> fieldErrors;
  final List<String> citySuggestions;

  ProfileState copyWith({
    bool? isLoading,
    bool? isSaving,
    bool? isUploadingAvatar,
    bool? isChangingPassword,
    UserMeResponse? profile,
    ProfileCompletenessDto? completeness,
    String? error,
    String? message,
    Map<String, String>? fieldErrors,
    List<String>? citySuggestions,
    bool clearError = false,
    bool clearMessage = false,
    bool clearFieldErrors = false,
  }) {
    return ProfileState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      isUploadingAvatar: isUploadingAvatar ?? this.isUploadingAvatar,
      isChangingPassword: isChangingPassword ?? this.isChangingPassword,
      profile: profile ?? this.profile,
      completeness: completeness ?? this.completeness,
      error: clearError ? null : (error ?? this.error),
      message: clearMessage ? null : (message ?? this.message),
      fieldErrors: clearFieldErrors
          ? const {}
          : (fieldErrors ?? this.fieldErrors),
      citySuggestions: citySuggestions ?? this.citySuggestions,
    );
  }
}

final profileControllerProvider =
    StateNotifierProvider<ProfileController, ProfileState>((ref) {
      return ProfileController(ref.watch(profileRepositoryProvider));
    });

class ProfileController extends StateNotifier<ProfileState> {
  ProfileController(this._repository) : super(const ProfileState());

  final ProfileRepository _repository;

  Future<void> load() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      final profile = await _repository.getMe();
      final completeness = await _repository.getProfileCompleteness();
      state = state.copyWith(
        isLoading: false,
        profile: profile,
        completeness: completeness,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<bool> patchMe(UpdateUserMeRequest request) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearMessage: true,
      clearFieldErrors: true,
    );
    try {
      final updated = await _repository.updateMe(request);
      state = state.copyWith(
        isSaving: false,
        profile: updated,
      );
      return true;
    } on ProfileValidationException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.message,
        fieldErrors: e.fieldErrors,
      );
      return false;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
      return false;
    }
  }

  Future<void> save({required UpdateUserMeRequest request}) async {
    state = state.copyWith(
      isSaving: true,
      clearError: true,
      clearMessage: true,
      clearFieldErrors: true,
    );
    try {
      final updated = await _repository.updateMe(request);
      state = state.copyWith(
        isSaving: false,
        profile: updated,
        message: 'Profile updated successfully',
      );
      await _refreshCompletenessQuietly();
    } on ProfileValidationException catch (e) {
      state = state.copyWith(
        isSaving: false,
        error: e.message,
        fieldErrors: e.fieldErrors,
      );
    } catch (e) {
      state = state.copyWith(isSaving: false, error: e.toString());
    }
  }

  Future<void> uploadAvatar(XFile file) async {
    state = state.copyWith(
      isUploadingAvatar: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      final avatar = await _repository.uploadAvatar(file);
      final current = state.profile;
      if (current != null) {
        final patched = UserMeResponse(
          id: current.id,
          fullName: current.fullName,
          firstName: current.firstName,
          lastName: current.lastName,
          email: current.email,
          bio: current.bio,
          city: current.city,
          preferredLanguage: current.preferredLanguage,
          phone: current.phone,
          theme: current.theme,
          notifyNewMessage: current.notifyNewMessage,
          notifyContactRequest: current.notifyContactRequest,
          notifyListingFavorited: current.notifyListingFavorited,
          avatarUrl: avatar.avatarUrl,
          status: current.status,
          emailVerified: current.emailVerified,
          phoneVerified: current.phoneVerified,
          profileCompleted: current.profileCompleted,
          trustScore: current.trustScore,
          lastSeenAt: current.lastSeenAt,
          createdAt: current.createdAt,
          updatedAt: current.updatedAt,
        );
        state = state.copyWith(
          isUploadingAvatar: false,
          profile: patched,
          message: 'Avatar updated',
        );
        await _refreshCompletenessQuietly();
      } else {
        await load();
        state = state.copyWith(
          isUploadingAvatar: false,
          message: 'Avatar updated',
        );
      }
    } catch (e) {
      state = state.copyWith(isUploadingAvatar: false, error: e.toString());
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    state = state.copyWith(
      isChangingPassword: true,
      clearError: true,
      clearMessage: true,
    );
    try {
      await _repository.changePassword(currentPassword, newPassword);
      state = state.copyWith(
        isChangingPassword: false,
        message: 'Password updated successfully',
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        isChangingPassword: false,
        error: e.message,
      );
    } catch (e) {
      state = state.copyWith(isChangingPassword: false, error: e.toString());
    }
  }

  Future<void> _refreshCompletenessQuietly() async {
    try {
      final completeness = await _repository.getProfileCompleteness();
      state = state.copyWith(completeness: completeness);
    } catch (_) {}
  }

  Future<void> loadCitySuggestions(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      state = state.copyWith(citySuggestions: const []);
      return;
    }
    try {
      final suggestions = await _repository.searchKgCities(trimmed);
      state = state.copyWith(citySuggestions: suggestions);
    } catch (_) {}
  }

  void clearCitySuggestions() {
    state = state.copyWith(citySuggestions: const []);
  }
}
