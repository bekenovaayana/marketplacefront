import 'package:flutter/material.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/shared/data/category_catalog.dart';
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
  final ValueChanged<int> onRemovePhoto;
  final Future<void> Function(int oldIndex, int newIndex) onReorderPhoto;
  final Future<void> Function() onLoadPreview;
  final Future<bool> Function() onPublish;
  final VoidCallback onNextStep;
  final VoidCallback onBackStep;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Stepper(
          currentStep: state.currentStep,
          controlsBuilder: (context, details) => const SizedBox.shrink(),
          onStepTapped: (_) {},
          steps: [
            Step(
              isActive: state.currentStep >= 0,
              title: const Text('Basic'),
              content: Column(
                children: [
                  Builder(
                    builder: (context) {
                      final categoryOptions = CategoryCatalog.forForm(state.categories)
                          .where((c) => c.categoryId != null)
                          .toList();
                      return DropdownButtonFormField<int>(
                        initialValue: state.payload.categoryId,
                        items: categoryOptions
                            .map(
                              (e) => DropdownMenuItem(
                                value: e.categoryId!,
                                child: Text(e.labelRu),
                              ),
                            )
                            .toList(),
                        onChanged: onCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
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
                      labelText: 'Title',
                      errorText: state.fieldErrors['title'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: descriptionController,
                    maxLines: 4,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: 'Description',
                      errorText: state.fieldErrors['description'],
                    ),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 1,
              title: const Text('Price & Location'),
              content: Column(
                children: [
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: 'Price',
                      errorText: state.fieldErrors['price'],
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: cityController,
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: 'City',
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
                          decoration: const InputDecoration(
                            labelText: 'Latitude',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: lngController,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => onFieldChanged(),
                          decoration: const InputDecoration(
                            labelText: 'Longitude',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: onUseCurrentLocation,
                    icon: const Icon(Icons.my_location_outlined),
                    label: const Text('Use current location'),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 2,
              title: const Text('Photos & Contact'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPickPhotos,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: Text(
                      'Add photos (${state.payload.images.length}/10)',
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
                        title: Text('Photo ${index + 1}'),
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
                    onChanged: (_) => onFieldChanged(),
                    decoration: InputDecoration(
                      labelText: 'Contact phone',
                      errorText: state.fieldErrors['contact_phone'],
                    ),
                  ),
                ],
              ),
            ),
            Step(
              isActive: state.currentStep >= 3,
              title: const Text('Preview & Publish'),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OutlinedButton(
                    onPressed: onLoadPreview,
                    child: const Text('Load preview'),
                  ),
                  if (state.preview != null)
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(
                          'Preview: ${state.preview!['title'] ?? state.payload.title ?? ''}\n'
                          'City: ${state.preview!['city'] ?? state.payload.city ?? ''}\n'
                          'Price: ${state.preview!['price'] ?? state.payload.price ?? ''}',
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
                              showAppNotification(context, 'Published');
                            }
                          },
                    child: state.isPublishing
                        ? const CircularProgressIndicator()
                        : const Text('Publish now'),
                  ),
                ],
              ),
            ),
          ],
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: state.currentStep == 0 ? null : onBackStep,
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.currentStep == 3 ? null : onNextStep,
              child: const Text('Continue'),
            ),
          ],
        ),
        if (state.error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              ErrorMapper.friendly(state.error),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (state.message != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              state.message!,
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }
}
