import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/shared/data/category_catalog.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';

class CreateFlowView extends StatelessWidget {
  const CreateFlowView({
    super.key,
    required this.state,
    required this.titleController,
    required this.descriptionController,
    required this.priceController,
    required this.cityController,
    required this.latController,
    required this.lngController,
    required this.phoneController,
    required this.onCategory,
    required this.onFieldChanged,
    required this.onPickPhotos,
    required this.onUseCurrentLocation,
    required this.onPickLocationOnMap,
    required this.onRemovePhoto,
    required this.onReorderPhoto,
    required this.onLoadPreview,
    required this.onPublish,
    required this.onNextStep,
    required this.onBackStep,
  });

  final PostingState state;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final TextEditingController priceController;
  final TextEditingController cityController;
  final TextEditingController latController;
  final TextEditingController lngController;
  final TextEditingController phoneController;
  final ValueChanged<int?> onCategory;
  final VoidCallback onFieldChanged;
  final VoidCallback onPickPhotos;
  final VoidCallback onUseCurrentLocation;
  final VoidCallback onPickLocationOnMap;
  final ValueChanged<int> onRemovePhoto;
  final Future<void> Function(int oldIndex, int newIndex) onReorderPhoto;
  final Future<void> Function() onLoadPreview;
  final Future<bool> Function() onPublish;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;

  @override
  Widget build(BuildContext context) {
    String t(String key) => AppStrings.of(context, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = const Color(0xFF23B554);
    final panel = isDark ? const Color(0xFF172335) : Colors.white;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Card(
          color: panel,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: accent,
                  ),
            ),
            child: Stepper(
              currentStep: state.currentStep,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              onStepTapped: (_) {},
              steps: [
            Step(
              isActive: state.currentStep >= 0,
              title: Text(t('postingStepBasic')),
              content: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final categoryOptions = CategoryCatalog.forForm(state.categories)
                          .where((c) => c.categoryId != null)
                          .toList();
                      final validIds = categoryOptions
                          .map((e) => e.categoryId!)
                          .toSet();
                      final rawCat = state.payload.categoryId?.toInt();
                      final selectedCategory =
                          rawCat != null && validIds.contains(rawCat)
                              ? rawCat
                              : null;
                      return DropdownButtonFormField<int?>(
                        key: ValueKey<Object?>(
                          'post_cat_${state.draftId}_$selectedCategory',
                        ),
                        initialValue: selectedCategory,
                        items: [
                          DropdownMenuItem<int?>(
                            value: null,
                            child: Text(t('postingCategoryPlaceholder')),
                          ),
                          ...categoryOptions.map(
                            (e) => DropdownMenuItem<int?>(
                              value: e.categoryId,
                              child: Text(e.labelRu),
                            ),
                          ),
                        ],
                        onChanged: onCategory,
                        decoration: InputDecoration(
                          labelText: t('labelCategory'),
                          errorText: state.fieldErrors['category_id'],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: titleController,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: t('labelTitle'),
                      errorText: state.fieldErrors['title'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: t('description'),
                      errorText: state.fieldErrors['description'],
                    ),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 1,
              title: Text(t('postingStepPriceLocation')),
              content: Column(
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: t('labelPrice'),
                      hintText: t('priceHintExample'),
                      errorText: state.fieldErrors['price'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cityController,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: t('labelCityRegion'),
                      errorText: state.fieldErrors['city'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: latController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onFieldChanged(),
                          decoration: InputDecoration(
                            labelText: t('labelLatitude'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onFieldChanged(),
                          decoration: InputDecoration(
                            labelText: t('labelLongitude'),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onPickLocationOnMap,
                    icon: const Icon(Icons.map_outlined),
                    label: Text(t('pickPlaceOnMap')),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onUseCurrentLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: Text(t('useCurrentLocation')),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 2,
              title: Text(t('postingStepPhotosContact')),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPickPhotos,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      '${t('addMedia')} (${state.payload.images.length}/10)',
                    ),
                  ),
                  if (state.fieldErrors['images'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        state.fieldErrors['images']!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ReorderableListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: state.payload.images.length,
                    onReorder: onReorderPhoto,
                    itemBuilder: (context, index) {
                      final image = state.payload.images[index];
                      final imgUrl = ApiUrls.absoluteUrl(image.url);
                      return ListTile(
                        key: ValueKey('${image.url}-$index'),
                        leading: image.url.isEmpty
                            ? const SizedBox(width: 48, height: 48)
                            : Image.network(
                                imgUrl,
                                width: 48,
                                height: 48,
                                fit: BoxFit.cover,
                              ),
                        title: Text('${t('mediaItem')} ${index + 1}'),
                        trailing: IconButton(
                          onPressed: () => onRemovePhoto(index),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
                    ],
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: t('contactPhoneLabel'),
                      hintText: t('phoneHintGeneric'),
                      errorText: state.fieldErrors['contact_phone'],
                    ),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 3,
              title: Text(t('postingStepPreviewPublish')),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: onLoadPreview,
                    child: Text(t('postingLoadPreview')),
                  ),
                  if (state.preview != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          '${t('postingPreviewHeader')}: ${state.preview!['title'] ?? state.payload.title ?? ''}\n'
                          '${t('cityLabel')}: ${state.preview!['city'] ?? state.payload.city ?? ''}\n'
                          '${t('labelPrice')}: ${state.preview!['price'] ?? state.payload.price ?? ''}\n'
                          '${t('contactPhoneLabel')}: ${state.preview!['contact_phone'] ?? state.payload.contactPhone ?? ''}\n'
                          '${t('mediaItem')}: ${(state.preview!['images'] as List?)?.length ?? state.payload.images.length}',
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: state.isPublishing
                        ? null
                        : () async {
                            final ok = await onPublish();
                            if (ok && context.mounted) {
                              showAppNotification(context, t('listingPublished'));
                            }
                          },
                    child: state.isPublishing
                        ? const CircularProgressIndicator()
                        : Text(t('postingPublishNow')),
                  ),
                ],
              ),
            ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            OutlinedButton(
              onPressed: state.currentStep == 0 ? null : onBackStep,
              child: Text(t('back')),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.currentStep == 3 ? null : onNextStep,
              child: Text(t('continueLabel')),
            ),
          ],
        ),
        if (state.error != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ErrorMapper.friendly(state.error),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (state.message != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              state.message!,
              style: TextStyle(color: accent, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}
