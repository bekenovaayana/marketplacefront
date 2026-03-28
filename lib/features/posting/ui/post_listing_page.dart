import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/ui/widgets/create_flow_view.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/features/profile/state/profile_listings_nav_intent.dart';
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
  final _picker = ImagePicker();

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
    await c.saveDraftNow();
    if (!mounted) return;
    final err = ref.read(postingControllerProvider).error;
    if (err != null) return;
    final catId = ref.read(postingControllerProvider).payload.categoryId;
    ref.read(profileListingsNavIntentProvider.notifier).setIntent(
          ProfileListingsNavIntent(
            tab: ProfileListingsTab.draft,
            filterCategoryId: catId,
            nonce: DateTime.now().millisecondsSinceEpoch,
          ),
        );
    context.go('/app?tab=4');
  }

  Future<bool> _onPublish(PostingController c) async {
    final catId = ref.read(postingControllerProvider).payload.categoryId;
    final ok = await c.publish();
    if (!mounted) return ok;
    if (ok) {
      ref.read(profileListingsNavIntentProvider.notifier).setIntent(
            ProfileListingsNavIntent(
              tab: ProfileListingsTab.active,
              filterCategoryId: catId,
              nonce: DateTime.now().millisecondsSinceEpoch,
            ),
          );
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

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    if (!auth.isAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && context.mounted) context.go('/app?tab=4');
      });
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final state = ref.watch(postingControllerProvider);
    final c = ref.read(postingControllerProvider.notifier);
    _syncControllers(state.payload);

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
            onPressed: state.isSavingDraft || state.isLoading || state.draftId == null
                ? null
                : () => _onSaveDraft(c),
            child: Text(saveLabel),
          ),
        ],
      ),
      body: Column(
        children: [
          if (state.isSavingDraft) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: state.isLoading
                ? const Center(child: CircularProgressIndicator())
                : CreateFlowView(
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
                    onPublish: () => _onPublish(c),
                    onNextStep: () =>
                        c.setStep((state.currentStep + 1).clamp(0, 3)),
                    onBackStep: () =>
                        c.setStep((state.currentStep - 1).clamp(0, 3)),
                  ),
          ),
        ],
      ),
    );
  }
}
