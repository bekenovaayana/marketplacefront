import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/listings/state/create_listing_controller.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/skeleton_box.dart';

class CreateListingTab extends ConsumerStatefulWidget {
  const CreateListingTab({super.key});

  @override
  ConsumerState<CreateListingTab> createState() => _CreateListingTabState();
}

class _CreateListingTabState extends ConsumerState<CreateListingTab>
    with AutomaticKeepAliveClientMixin {
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(
      () => ref.read(createListingControllerProvider.notifier).init(),
    );
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty && mounted) {
      await ref.read(createListingControllerProvider.notifier).addImages(files);
    }
  }

  Future<void> _useCurrentLocation() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (mounted) {
        showAppNotification(context, 'Location service is disabled');
      }
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      if (mounted) {
        showAppNotification(context, 'Location permission denied');
      }
      return;
    }
    final position = await Geolocator.getCurrentPosition();
    ref
        .read(createListingControllerProvider.notifier)
        .setLocation(position.latitude, position.longitude);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final state = ref.watch(createListingControllerProvider);
    final controller = ref.read(createListingControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('Post listing')),
      body: state.isLoading
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  SkeletonBox(height: 42),
                  SizedBox(height: 10),
                  SkeletonBox(height: 42),
                  SizedBox(height: 10),
                  SkeletonBox(height: 90),
                ],
              ),
            )
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: state.selectedCategoryId,
                    items: state.categories
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: controller.setCategory,
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _title,
                    decoration: const InputDecoration(labelText: 'Title'),
                    validator: (value) => value == null || value.length < 3
                        ? 'Min 3 chars'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _description,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                    validator: (value) => value == null || value.length < 10
                        ? 'Min 10 chars'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _price,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Price'),
                    validator: (value) => (double.tryParse(value ?? '') == null)
                        ? 'Enter valid price'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _city,
                    decoration: const InputDecoration(labelText: 'City'),
                    validator: (value) => value == null || value.isEmpty
                        ? 'City is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _phone,
                    decoration: const InputDecoration(
                      labelText: 'Contact phone',
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Phone is required'
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _pickImages,
                        icon: const Icon(Icons.photo_library_outlined),
                        label: Text('Add photos (${state.images.length}/10)'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _useCurrentLocation,
                        icon: const Icon(Icons.my_location_outlined),
                        label: const Text('Use current location'),
                      ),
                    ],
                  ),
                  if (state.images.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 90,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemBuilder: (context, index) {
                          final image = state.images[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: FutureBuilder(
                                  future: image.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (!snapshot.hasData) {
                                      return Container(
                                        width: 90,
                                        height: 90,
                                        color: Colors.grey.shade200,
                                      );
                                    }
                                    return Image.memory(
                                      snapshot.data!,
                                      width: 90,
                                      height: 90,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (context, error, stackTrace) {
                                            return Container(
                                              width: 90,
                                              height: 90,
                                              color: Colors.grey.shade200,
                                              child: const Icon(
                                                Icons.image_outlined,
                                              ),
                                            );
                                          },
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                right: 0,
                                child: GestureDetector(
                                  onTap: () => controller.removeImageAt(index),
                                  child: const CircleAvatar(
                                    radius: 12,
                                    child: Icon(Icons.close, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                        separatorBuilder: (context, index) =>
                            const SizedBox(width: 8),
                        itemCount: state.images.length,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (state.latitude != null && state.longitude != null)
                    Text(
                      'Location: ${state.latitude!.toStringAsFixed(5)}, '
                      '${state.longitude!.toStringAsFixed(5)}',
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
                  const SizedBox(height: 14),
                  ElevatedButton(
                    onPressed: state.isSubmitting
                        ? null
                        : () async {
                            if (!_formKey.currentState!.validate()) {
                              return;
                            }
                            final ok = await ref
                                .read(createListingControllerProvider.notifier)
                                .submit(
                                  title: _title.text.trim(),
                                  description: _description.text.trim(),
                                  priceText: _price.text.trim(),
                                  city: _city.text.trim(),
                                  phone: _phone.text.trim(),
                                );
                            if (!context.mounted) return;
                            if (ok) {
                              showAppNotification(context, 'Listing created');
                              _title.clear();
                              _description.clear();
                              _price.clear();
                              _city.clear();
                              _phone.clear();
                            }
                          },
                    child: state.isSubmitting
                        ? const CircularProgressIndicator()
                        : const Text('Publish listing'),
                  ),
                ],
              ),
            ),
    );
  }
}
