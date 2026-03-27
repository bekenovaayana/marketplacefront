import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';

class PostingTab extends ConsumerStatefulWidget {
  const PostingTab({super.key});

  @override
  ConsumerState<PostingTab> createState() => _PostingTabState();
}

class _PostingTabState extends ConsumerState<PostingTab>
    with AutomaticKeepAliveClientMixin {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _phone = TextEditingController();
  final _picker = ImagePicker();
  int _modeIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(postingControllerProvider.notifier).init());
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _price.dispose();
    _city.dispose();
    _lat.dispose();
    _lng.dispose();
    _phone.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      return Scaffold(
        appBar: AppBar(title: const Text('Post')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.add_box_outlined, size: 56),
                const SizedBox(height: 10),
                const Text('Sign in to create or manage listings'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    final from = Uri.encodeComponent('/app?tab=2');
                    context.push('/auth-gate?from=$from');
                  },
                  child: const Text('Sign in / Create account'),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final state = ref.watch(postingControllerProvider);
    final c = ref.read(postingControllerProvider.notifier);
    _syncControllers(state.payload);

    return Scaffold(
      appBar: AppBar(title: const Text('Post')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Create')),
                ButtonSegment(value: 1, label: Text('My listings')),
              ],
              selected: {_modeIndex},
              onSelectionChanged: (v) => setState(() => _modeIndex = v.first),
            ),
          ),
          if (state.isSavingDraft) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _modeIndex == 0
                ? _CreateFlowView(
                    state: state,
                    titleController: _title,
                    descriptionController: _description,
                    priceController: _price,
                    cityController: _city,
                    latController: _lat,
                    lngController: _lng,
                    phoneController: _phone,
                    onCategory: (id) => c.patchBasic(categoryId: id),
                    onFieldChanged: () => _onFieldChanged(c),
                    onPickPhotos: () => _pickPhotos(c),
                    onUseCurrentLocation: () => _useLocation(c),
                    onRemovePhoto: (index) => c.removePhoto(index),
                    onReorderPhoto: (o, n) => c.reorderPhotos(o, n),
                    onLoadPreview: c.loadPreview,
                    onPublish: c.publish,
                    onNextStep: () =>
                        c.setStep((state.currentStep + 1).clamp(0, 3)),
                    onBackStep: () =>
                        c.setStep((state.currentStep - 1).clamp(0, 3)),
                  )
                : _MyListingsView(
                    state: state,
                    onStatus: (status) => c.loadMyListings(status: status),
                    onResumeDraft: (id) async {
                      await c.resumeDraft(id);
                      if (mounted) setState(() => _modeIndex = 0);
                    },
                    onUnpublish: c.unpublish,
                    onRepublish: (id) async {
                      await c.resumeDraft(id);
                      await c.publish();
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _syncControllers(PostingDraftPayload payload) {
    void setIfDiff(TextEditingController c, String next) {
      if (c.text != next) c.text = next;
    }

    setIfDiff(_title, payload.title ?? '');
    setIfDiff(_description, payload.description ?? '');
    setIfDiff(_price, payload.price?.toString() ?? '');
    setIfDiff(_city, payload.city ?? '');
    setIfDiff(_lat, payload.latitude?.toString() ?? '');
    setIfDiff(_lng, payload.longitude?.toString() ?? '');
    setIfDiff(_phone, payload.contactPhone ?? '');
  }

  void _onFieldChanged(PostingController c) {
    c.patchBasic(title: _title.text, description: _description.text);
    c.patchPriceLocation(
      priceText: _price.text,
      city: _city.text,
      latText: _lat.text,
      lngText: _lng.text,
    );
    c.patchContact(phone: _phone.text);
  }

  Future<void> _pickPhotos(PostingController c) async {
    final files = await _picker.pickMultiImage();
    if (files.isNotEmpty) {
      await c.addPhotos(files);
    }
  }

  Future<void> _useLocation(PostingController c) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      showAppNotification(context, 'Location service is disabled');
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showAppNotification(context, 'Location permission denied');
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    await c.setCurrentLocation(lat: pos.latitude, lng: pos.longitude);
  }
}

class _CreateFlowView extends StatelessWidget {
  const _CreateFlowView({
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
                  DropdownButtonFormField<int>(
                    initialValue: state.payload.categoryId,
                    items: state.categories
                        .map(
                          (e) => DropdownMenuItem(
                            value: e.id,
                            child: Text(e.name),
                          ),
                        )
                        .toList(),
                    onChanged: onCategory,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      errorText: state.fieldErrors['category_id'],
                    ),
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
                      return ListTile(
                        key: ValueKey('${image.url}-$index'),
                        leading: image.url.isEmpty
                            ? const SizedBox(width: 48, height: 48)
                            : Image.network(
                                image.url,
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

class _MyListingsView extends StatelessWidget {
  const _MyListingsView({
    required this.state,
    required this.onStatus,
    required this.onResumeDraft,
    required this.onUnpublish,
    required this.onRepublish,
  });

  final PostingState state;
  final ValueChanged<String> onStatus;
  final ValueChanged<int> onResumeDraft;
  final ValueChanged<int> onUnpublish;
  final ValueChanged<int> onRepublish;

  @override
  Widget build(BuildContext context) {
    const statuses = ['draft', 'active', 'inactive', 'sold'];
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: statuses.map((status) {
              final selected = state.myStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(status),
                  selected: selected,
                  onSelected: (_) => onStatus(status),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: state.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: state.myListings.length,
                  itemBuilder: (context, index) {
                    final item = state.myListings[index];
                    return ListTile(
                      leading: item.cover.isEmpty
                          ? const CircleAvatar(
                              child: Icon(Icons.inventory_2_outlined),
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(item.cover),
                            ),
                      title: Text(item.title),
                      subtitle: Text(
                        '${item.price.toStringAsFixed(0)} • ${item.city}',
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (item.status == 'draft')
                            TextButton(
                              onPressed: () => onResumeDraft(item.id),
                              child: const Text('Resume'),
                            ),
                          if (item.status == 'active')
                            TextButton(
                              onPressed: () => onUnpublish(item.id),
                              child: const Text('Unpublish'),
                            ),
                          if (item.status == 'inactive')
                            TextButton(
                              onPressed: () => onRepublish(item.id),
                              child: const Text('Republish'),
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
