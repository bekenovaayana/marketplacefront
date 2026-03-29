import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/listings/models/listing_public.dart';
import 'package:marketplace_frontend/features/posting/data/kg_regions.dart';
import 'package:marketplace_frontend/features/posting/posting_flow_validation.dart';
import 'package:marketplace_frontend/features/posting/state/posting_ui_slice.dart';
import 'package:marketplace_frontend/shared/data/category_catalog.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/listing_card.dart';

class CreateFlowView extends StatelessWidget {
  const CreateFlowView({
    super.key,
    required this.ui,
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
    required this.onJumpToStep,
  });

  final PostingFlowUiSlice ui;
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
  final ValueChanged<int> onJumpToStep;

  static int _stepForPublishKey(String key) {
    switch (key) {
      case 'postingMissingCategory':
      case 'postingMissingTitle':
      case 'postingMissingDescription':
        return 0;
      case 'postingMissingPrice':
      case 'postingMissingCity':
        return 1;
      case 'postingMissingPhotos':
      case 'postingMissingPhone':
        return 2;
      default:
        return 0;
    }
  }

  static String _stepCounter(BuildContext context, int stepIndex) {
    final raw = AppStrings.of(context, 'postingStepCounter');
    return raw
        .replaceAll('{current}', '${stepIndex + 1}')
        .replaceAll('{total}', '4');
  }

  ListingPublic _buildPreviewListing() {
    final pv = ui.preview;
    Map<String, dynamic> root = {};
    if (pv != null) {
      final nested = pv['listing'];
      if (nested is Map<String, dynamic>) {
        root = Map<String, dynamic>.from(nested);
      } else {
        root = Map<String, dynamic>.from(pv);
      }
    }
    final title = titleController.text.trim().isNotEmpty
        ? titleController.text
        : (root['title'] as String? ?? '');
    final description = descriptionController.text.trim().isNotEmpty
        ? descriptionController.text
        : (root['description'] as String? ?? '');
    final parsedPrice = PostingFlowValidation.parsePriceInt(priceController.text);
    final priceRaw = root['price'];
    final price = parsedPrice != null
        ? parsedPrice.toDouble()
        : (priceRaw is num
            ? priceRaw.toDouble()
            : double.tryParse('$priceRaw') ?? 0);
    final currency = root['currency'] as String? ?? ui.currency;
    final city = cityController.text.trim().isNotEmpty
        ? cityController.text
        : (root['city'] as String? ?? '');
    final images = <ListingImage>[];
    final rawImgs = root['images'] as List<dynamic>?;
    if (rawImgs != null && rawImgs.isNotEmpty) {
      for (final e in rawImgs) {
        if (e is Map<String, dynamic>) {
          images.add(ListingImage.fromJson(e));
        }
      }
    } else {
      for (final e in ui.images) {
        images.add(
          ListingImage(
            url: ApiUrls.networkImageUrl(e.url),
            sortOrder: e.sortOrder,
          ),
        );
      }
    }
    return ListingPublic(
      id: ui.draftId ?? 0,
      title: title,
      description: description,
      price: price,
      currency: currency,
      city: city,
      createdAt: DateTime.now(),
      images: images,
      isFavorite: false,
      isOwner: true,
      userId: null,
    );
  }

  void _openCategorySheet(BuildContext context, String Function(String key) t) {
    final options = CategoryCatalog.forForm(ui.categories)
        .where((c) => c.categoryId != null)
        .toList();
    final searchController = TextEditingController();
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
          child: StatefulBuilder(
            builder: (ctx, setModal) {
              final q = searchController.text.toLowerCase().trim();
              final filtered = q.isEmpty
                  ? options
                  : options
                      .where((e) => e.labelRu.toLowerCase().contains(q))
                      .toList();
              return DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.65,
                minChildSize: 0.35,
                maxChildSize: 0.92,
                builder: (_, scrollController) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                        child: Text(
                          t('postingChooseCategory'),
                          style: Theme.of(ctx).textTheme.titleMedium,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: TextField(
                          controller: searchController,
                          decoration: InputDecoration(
                            hintText: t('postingSearchCategories'),
                            prefixIcon: const Icon(Icons.search),
                            border: const OutlineInputBorder(),
                          ),
                          onChanged: (_) => setModal(() {}),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final e = filtered[i];
                            return ListTile(
                              title: Text(e.labelRu),
                              onTap: () {
                                onCategory(e.categoryId);
                                Navigator.pop(ctx);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        );
      },
    ).whenComplete(searchController.dispose);
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => AppStrings.of(context, key);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const accent = Color(0xFF23B554);
    final panel = isDark ? const Color(0xFF172335) : Colors.white;

    final categoryOptions = CategoryCatalog.forForm(ui.categories)
        .where((c) => c.categoryId != null)
        .toList();
    final validIds =
        categoryOptions.map((e) => e.categoryId!).toSet();
    final rawCat = ui.categoryId?.toInt();
    final selectedId =
        rawCat != null && validIds.contains(rawCat) ? rawCat : null;
    final selectedLabel = selectedId == null
        ? null
        : categoryOptions
            .firstWhere(
              (e) => e.categoryId == selectedId,
              orElse: () => categoryOptions.first,
            )
            .labelRu;

    final canContinue = PostingFlowValidation.canProceedToNextStep(
      ui,
      ui.currentStep,
      titleText: titleController.text,
      descriptionText: descriptionController.text,
      priceText: priceController.text,
      cityText: cityController.text,
      phoneText: phoneController.text,
      t: t,
    );
    final blockingHint = PostingFlowValidation.blockingHintForStep(
      ui,
      ui.currentStep,
      titleText: titleController.text,
      descriptionText: descriptionController.text,
      priceText: priceController.text,
      cityText: cityController.text,
      phoneText: phoneController.text,
      t: t,
    );

    Widget stepTitle(int index, String titleKey) {
      final active = ui.currentStep == index;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleKey,
            style: TextStyle(
              fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              color: active ? accent : null,
            ),
          ),
          Text(
            _stepCounter(context, index),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        if (ui.isSavingDraft && ui.mediaUploadFraction == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 8),
                Text(
                  t('postingDraftSaving'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        if (ui.mediaUploadFraction != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t('postingUploadingMedia'),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                LinearProgressIndicator(value: ui.mediaUploadFraction),
              ],
            ),
          ),
        Card(
          color: panel,
          child: Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(context).colorScheme.copyWith(
                    primary: accent,
                  ),
            ),
            child: Stepper(
              currentStep: ui.currentStep,
              controlsBuilder: (context, details) => const SizedBox.shrink(),
              onStepTapped: (i) => onJumpToStep(i.clamp(0, 3)),
              steps: [
                Step(
                  isActive: ui.currentStep >= 0,
                  state: ui.currentStep > 0
                      ? StepState.complete
                      : StepState.indexed,
                  title: stepTitle(0, t('postingStepBasic')),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _openCategorySheet(context, t),
                          borderRadius: BorderRadius.circular(8),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: t('labelCategory'),
                              border: const OutlineInputBorder(),
                              errorText: ui.fieldErrors['category_id'],
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              selectedLabel ?? t('postingCategoryPlaceholder'),
                              style: TextStyle(
                                color: selectedLabel == null
                                    ? Theme.of(context).hintColor
                                    : null,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: titleController,
                        onChanged: (_) => onFieldChanged(),
                        maxLength: 120,
                        buildCounter: (
                          context, {
                          required currentLength,
                          required isFocused,
                          maxLength,
                        }) =>
                            Text(
                          '$currentLength / $maxLength',
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        decoration: InputDecoration(
                          labelText: t('labelTitle'),
                          hintText: t('validationTitleShort'),
                          errorText: ui.fieldErrors['title'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: descriptionController,
                        maxLines: 4,
                        minLines: 3,
                        maxLength: 2000,
                        onChanged: (_) => onFieldChanged(),
                        decoration: InputDecoration(
                          labelText: t('description'),
                          alignLabelWithHint: true,
                          errorText: ui.fieldErrors['description'],
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  isActive: ui.currentStep >= 1,
                  state: ui.currentStep > 1
                      ? StepState.complete
                      : StepState.indexed,
                  title: stepTitle(1, t('postingStepPriceLocation')),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: priceController,
                        keyboardType: TextInputType.number,
                        onChanged: (_) => onFieldChanged(),
                        decoration: InputDecoration(
                          labelText: t('labelPrice'),
                          hintText: t('priceHintExample'),
                          errorText: ui.fieldErrors['price'],
                        ),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          showModalBottomSheet<void>(
                            context: context,
                            builder: (ctx) => ListView(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              children: kgPostingRegionPresets
                                  .map(
                                    (e) => ListTile(
                                      title: Text(e.label),
                                      subtitle: Text(e.city),
                                      onTap: () {
                                        cityController.text = e.city;
                                        onFieldChanged();
                                        Navigator.pop(ctx);
                                      },
                                    ),
                                  )
                                  .toList(),
                            ),
                          );
                        },
                        icon: const Icon(Icons.location_city_outlined),
                        label: Text(t('kgRegionQuickPick')),
                      ),
                      Text(
                        t('kgRegionHint'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cityController,
                        onChanged: (_) => onFieldChanged(),
                        decoration: InputDecoration(
                          labelText: t('labelCityRegion'),
                          errorText: ui.fieldErrors['city'],
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
                  isActive: ui.currentStep >= 2,
                  state: ui.currentStep > 2
                      ? StepState.complete
                      : StepState.indexed,
                  title: stepTitle(2, t('postingStepPhotosContact')),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      OutlinedButton.icon(
                        onPressed: ui.isSavingDraft ? null : onPickPhotos,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text(
                          '${t('addMedia')} (${ui.images.length}/10)',
                        ),
                      ),
                      if (ui.images.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            t('postingMediaEmptyHint'),
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (ui.fieldErrors['images'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            ui.fieldErrors['images']!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      const SizedBox(height: 8),
                      ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: ui.images.length,
                        onReorder: onReorderPhoto,
                        itemBuilder: (context, index) {
                          final image = ui.images[index];
                          final imgUrl = ApiUrls.networkImageUrl(image.url);
                          return Card(
                            key: ValueKey('${image.url}-$index'),
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: image.url.isEmpty
                                    ? Container(
                                        width: 56,
                                        height: 56,
                                        color: Colors.grey.shade300,
                                        child: const Icon(Icons.image),
                                      )
                                    : Image.network(
                                        imgUrl,
                                        width: 56,
                                        height: 56,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) =>
                                            Container(
                                          width: 56,
                                          height: 56,
                                          color: Colors.grey.shade300,
                                          child: const Icon(
                                            Icons.broken_image_outlined,
                                          ),
                                        ),
                                      ),
                              ),
                              title: Text('${t('mediaItem')} ${index + 1}'),
                              subtitle: Text(t('postingDragToReorder')),
                              trailing: IconButton(
                                onPressed: () => onRemovePhoto(index),
                                icon: const Icon(Icons.delete_outline),
                              ),
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
                          errorText: ui.fieldErrors['contact_phone'],
                        ),
                      ),
                    ],
                  ),
                ),
                Step(
                  isActive: ui.currentStep >= 3,
                  state: StepState.indexed,
                  title: stepTitle(3, t('postingStepPreviewPublish')),
                  content: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t('postingMissingFields'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: PostingFlowValidation.missingPublishKeys(
                              ui,
                              titleText: titleController.text,
                              descriptionText: descriptionController.text,
                              priceText: priceController.text,
                              cityText: cityController.text,
                              phoneText: phoneController.text,
                            )
                            .map(
                              (key) => ActionChip(
                                label: Text(t(key)),
                                onPressed: () =>
                                    onJumpToStep(_stepForPublishKey(key)),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: ui.isSavingDraft ? null : onLoadPreview,
                        icon: const Icon(Icons.refresh),
                        label: Text(t('postingLoadPreview')),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t('postingPreviewCardTitle'),
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      AspectRatio(
                        aspectRatio: 0.78,
                        child: ListingCard(
                          item: _buildPreviewListing(),
                          onTap: () {},
                          onFavoriteTap: () {},
                        ),
                      ),
                      const SizedBox(height: 12),
                      FilledButton(
                        onPressed: ui.isPublishing
                            ? null
                            : () async {
                                final ok = await onPublish();
                                if (ok && context.mounted) {
                                  showAppNotification(
                                    context,
                                    t('listingPublished'),
                                  );
                                }
                              },
                        child: ui.isPublishing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: ui.currentStep == 0 ? null : onBackStep,
                child: Text(t('back')),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton(
                    onPressed: ui.currentStep >= 3 || !canContinue
                        ? null
                        : onNextStep,
                    child: Text(t('continueLabel')),
                  ),
                  if (blockingHint != null && ui.currentStep < 3)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        blockingHint,
                        style: TextStyle(
                          color: Colors.red.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        if (ui.error != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ErrorMapper.friendly(ui.error),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (ui.message != null)
          Container(
            margin: const EdgeInsets.only(top: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              ui.message!,
              style: const TextStyle(
                color: accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}
