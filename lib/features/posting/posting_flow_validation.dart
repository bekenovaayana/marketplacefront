import 'package:marketplace_frontend/features/posting/state/posting_ui_slice.dart';

/// Client-side checks before advancing steps in the posting wizard.
class PostingFlowValidation {
  PostingFlowValidation._();

  static int? parsePriceInt(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    final asInt = int.tryParse(normalized);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(normalized);
    if (asDouble == null) return null;
    if (asDouble != asDouble.toInt().toDouble()) return null;
    return asDouble.toInt();
  }

  /// First blocking issue for the current step, or null if OK to continue.
  static String? blockingHintForStep(
    PostingFlowUiSlice slice,
    int step, {
    required String titleText,
    required String descriptionText,
    required String priceText,
    required String cityText,
    required String phoneText,
    required String Function(String key) t,
  }) {
    switch (step) {
      case 0:
        if (slice.categoryId == null) return t('validationCategoryRequired');
        if (titleText.trim().length < 3) return t('validationTitleShort');
        if (descriptionText.trim().length < 10) {
          return t('validationDescriptionShort');
        }
        return null;
      case 1:
        final price = parsePriceInt(priceText);
        if (price == null || price < 0) return t('validationPriceRequired');
        if (cityText.trim().length < 2) return t('validationCityRequired');
        return null;
      case 2:
        if (slice.images.isEmpty) return t('validationPhotosRequired');
        final phone = phoneText.trim();
        if (phone.length < 8) return t('validationPhoneShort');
        return null;
      default:
        return null;
    }
  }

  static bool canProceedToNextStep(
    PostingFlowUiSlice slice,
    int step, {
    required String titleText,
    required String descriptionText,
    required String priceText,
    required String cityText,
    required String phoneText,
    required String Function(String key) t,
  }) {
    return blockingHintForStep(
          slice,
          step,
          titleText: titleText,
          descriptionText: descriptionText,
          priceText: priceText,
          cityText: cityText,
          phoneText: phoneText,
          t: t,
        ) ==
        null;
  }

  static List<String> missingPublishKeys(
    PostingFlowUiSlice slice, {
    required String titleText,
    required String descriptionText,
    required String priceText,
    required String cityText,
    required String phoneText,
  }) {
    final out = <String>[];
    if (slice.categoryId == null) out.add('postingMissingCategory');
    if (titleText.trim().length < 3) out.add('postingMissingTitle');
    if (descriptionText.trim().length < 10) {
      out.add('postingMissingDescription');
    }
    final price = parsePriceInt(priceText);
    if (price == null || price < 0) {
      out.add('postingMissingPrice');
    }
    if (cityText.trim().length < 2) out.add('postingMissingCity');
    if (slice.images.isEmpty) out.add('postingMissingPhotos');
    if (phoneText.trim().length < 8) {
      out.add('postingMissingPhone');
    }
    return out;
  }
}
