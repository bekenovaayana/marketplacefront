import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/ui/location_pick_result.dart';
import 'package:marketplace_frontend/features/posting/ui/location_picker_screen.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/state/posting_ui_slice.dart';
import 'package:marketplace_frontend/features/posting/ui/widgets/create_flow_view.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';

class PostListingPage extends ConsumerStatefulWidget {
  const PostListingPage({super.key});

  @override
  ConsumerState<PostListingPage> createState() => _PostListingPageState();
}

class _PostListingPageState extends ConsumerState<PostListingPage> {
  final _title = TextEditingController();
  final _description = TextEditingController();
  final _price = TextEditingController();
  final _city = TextEditingController();
  final _lat = TextEditingController();
  final _lng = TextEditingController();
  final _phone = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final auth = ref.read(authControllerProvider);
      if (!auth.isAuthenticated) {
        context.go('/app?tab=4');
        return;
      }
      ref.read(postingControllerProvider.notifier).initForNewListing();
    });
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

  Future<void> _onSaveDraft(PostingController c) async {
    _onFieldChanged(c);
    await c.saveDraftNow();
    if (!mounted) return;
    final err = ref.read(postingControllerProvider).error;
    if (err != null) return;
    final catId = ref.read(postingControllerProvider).payload.categoryId?.toInt();
    await ref.read(myActiveListingsProvider.notifier).syncAfterDraftSaved(
          listingCategoryId: catId,
        );
    if (!mounted) return;
    context.go('/app?tab=4');
  }

  Future<bool> _onPublish(PostingController c) async {
    _onFieldChanged(c);
    final catId = ref.read(postingControllerProvider).payload.categoryId?.toInt();
    final ok = await c.publish();
    if (!mounted) return ok;
    if (ok) {
      await ref.read(myActiveListingsProvider.notifier).syncAfterPublish(
            listingCategoryId: catId,
          );
      if (!mounted) return ok;
      context.go('/app?tab=4');
    }
    return ok;
  }

  void _syncControllers(PostingDraftPayload payload) {
    void setIfDiff(TextEditingController ctl, String next) {
      if (ctl.text != next) ctl.text = next;
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
    if (!mounted) return;
    final t = AppStrings.of;
    final source = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                t(context, 'postingMediaPickTitle'),
                style: Theme.of(ctx).textTheme.titleSmall,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.folder_open),
              title: Text(t(context, 'postingMediaFromFiles')),
              onTap: () => Navigator.pop(ctx, 'files'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t(context, 'postingMediaFromGallery')),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: Text(t(context, 'postingMediaFromCamera')),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
          ],
        ),
      ),
    );
    if (!mounted || source == null) return;

    final picker = ImagePicker();
    List<XFile> files = [];

    if (source == 'files') {
      final picked = await FilePicker.platform.pickFiles(
        allowMultiple: true,
        type: FileType.custom,
        allowedExtensions: const [
          'jpg',
          'jpeg',
          'png',
          'webp',
          'heic',
          'heif',
          'mp4',
          'webm',
          'mov',
        ],
      );
      if (picked != null) {
        files = picked.files
            .where((f) => (f.path ?? '').isNotEmpty)
            .map((f) => XFile(f.path!))
            .toList();
      }
    } else if (source == 'gallery') {
      files = await picker.pickMultiImage();
    } else if (source == 'camera') {
      final one = await picker.pickImage(source: ImageSource.camera);
      if (one != null) files = [one];
    }

    if (files.isNotEmpty) {
      await c.addPhotos(files);
    }
  }

  Future<void> _useLocation(PostingController c) async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      showAppNotification(context, AppStrings.of(context, 'locationServiceDisabled'));
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showAppNotification(context, AppStrings.of(context, 'locationPermissionDenied'));
      return;
    }
    final pos = await Geolocator.getCurrentPosition();
    var city = '';
    try {
      final marks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (marks.isNotEmpty) {
        final p = marks.first;
        final loc = p.locality?.trim() ?? '';
        city = loc.isNotEmpty
            ? loc
            : (p.subAdministrativeArea ?? p.administrativeArea ?? '').trim();
      }
    } catch (_) {}
    _lat.text = pos.latitude.toString();
    _lng.text = pos.longitude.toString();
    if (city.isNotEmpty) {
      _city.text = city;
    }
    c.patchPriceLocation(
      city: _city.text,
      latText: _lat.text,
      lngText: _lng.text,
    );
  }

  Future<void> _pickLocationOnMap(PostingController c) async {
    final lat = double.tryParse(_lat.text.trim());
    final lng = double.tryParse(_lng.text.trim());
    final result = await Navigator.push<LocationPickResult>(
      context,
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(
          initialCity: _city.text.trim().isEmpty ? null : _city.text.trim(),
          initialLat: lat,
          initialLng: lng,
        ),
      ),
    );
    if (result == null) return;
    _city.text = result.city;
    _lat.text = result.latitude.toString();
    _lng.text = result.longitude.toString();
    c.patchPriceLocation(
      city: result.city,
      latText: _lat.text,
      lngText: _lng.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) context.go('/app?tab=4');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    ref.listen<PostingState>(postingControllerProvider, (prev, next) {
      if (prev?.hydrateGeneration == next.hydrateGeneration) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncControllers(next.payload);
      });
    });

    final ui = ref.watch(postingControllerProvider.select(PostingFlowUiSlice.from));
    final c = ref.read(postingControllerProvider.notifier);

    final saveLabel = AppStrings.of(context, 'profileSaveDraft');

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context, 'profilePostListing')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.go('/app?tab=4'),
        ),
        actions: [
          TextButton(
            onPressed: ui.isSavingDraft || ui.isLoading || ui.draftId == null
                ? null
                : () => _onSaveDraft(c),
            child: Text(saveLabel),
          ),
        ],
      ),
      body: Column(
        children: [
          if (ui.isSavingDraft) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ui.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CreateFlowView(
                    ui: ui,
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
                    onPickLocationOnMap: () => _pickLocationOnMap(c),
                    onRemovePhoto: (index) => c.removePhoto(index),
                    onReorderPhoto: (o, n) => c.reorderPhotos(o, n),
                    onLoadPreview: () async {
                      _onFieldChanged(c);
                      await c.loadPreview();
                    },
                    onPublish: () => _onPublish(c),
                    onNextStep: () =>
                        c.setStep((ui.currentStep + 1).clamp(0, 3)),
                    onBackStep: () =>
                        c.setStep((ui.currentStep - 1).clamp(0, 3)),
                    onJumpToStep: c.setStep,
                  ),
          ),
        ],
      ),
    );
  }
}
