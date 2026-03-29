import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/core/network/api_urls.dart';
import 'package:marketplace_frontend/features/listings/ui/listing_detail_page.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/posting/ui/location_pick_result.dart';
import 'package:marketplace_frontend/features/posting/ui/location_picker_screen.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/state/posting_ui_slice.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/ui/widgets/create_flow_view.dart';
import 'package:marketplace_frontend/features/profile/state/my_active_listings_controller.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';
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
  int _modeIndex = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _bootstrapPostingIfSignedIn();
    });
  }

  void _bootstrapPostingIfSignedIn() {
    final auth = ref.read(authControllerProvider);
    if (auth.initialized && auth.isAuthenticated) {
      ref.read(postingControllerProvider.notifier).init();
    }
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final panel = isDark ? const Color(0xFF172335) : Colors.white;
    const accent = Color(0xFF23B554);
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (!next.initialized) return;
      if (next.isAuthenticated && prev?.isAuthenticated != true) {
        ref.read(postingControllerProvider.notifier).init();
      }
    });
    if (!auth.isAuthenticated) {
      String t(String key) => AppStrings.of(context, key);
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Card(
              color: panel,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_box_outlined, size: 56, color: accent),
                    const SizedBox(height: 10),
                    Text(t('signInToCreateListings')),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final from = Uri.encodeComponent('/app?tab=2');
                        context.push('/auth-gate?from=$from');
                      },
                      child: Text(t('signInOrCreateAccount')),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
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
    String t(String key) => AppStrings.of(context, key);

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Theme(
              data: Theme.of(context).copyWith(
                colorScheme: Theme.of(context).colorScheme.copyWith(primary: accent),
              ),
              child: SegmentedButton<int>(
                segments: [
                  ButtonSegment(value: 0, label: Text(t('postingTabCreate'))),
                  ButtonSegment(value: 1, label: Text(t('postingTabMyListings'))),
                ],
                selected: {_modeIndex},
                onSelectionChanged: (v) => setState(() => _modeIndex = v.first),
              ),
            ),
          ),
          if (ui.isSavingDraft) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _modeIndex == 0
                ? CreateFlowView(
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
                    onPublish: () async {
                      _onFieldChanged(c);
                      final catId =
                          ref.read(postingControllerProvider).payload.categoryId?.toInt();
                      final ok = await c.publish();
                      if (ok && mounted) {
                        await ref
                            .read(myActiveListingsProvider.notifier)
                            .syncAfterPublish(listingCategoryId: catId);
                      }
                      return ok;
                    },
                    onNextStep: () =>
                        c.setStep((ui.currentStep + 1).clamp(0, 3)),
                    onBackStep: () =>
                        c.setStep((ui.currentStep - 1).clamp(0, 3)),
                    onJumpToStep: c.setStep,
                  )
                : _MyListingsView(
                    t: t,
                    flowUi: ui,
                    onOpenListingDetail: (id) {
                      Navigator.of(context)
                          .push<bool>(
                            MaterialPageRoute(
                              builder: (_) => ListingDetailPage(
                                listingId: id,
                                useOwnerPreview: true,
                              ),
                            ),
                          )
                          .then((deleted) {
                            if (!context.mounted) return;
                            if (deleted == true) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(t('listingDeleted')),
                                ),
                              );
                            }
                          });
                    },
                    onStatus: (status) => c.loadMyListings(status: status),
                    onResumeDraft: (id) async {
                      await c.resumeDraft(id);
                      if (mounted) setState(() => _modeIndex = 0);
                    },
                    onUnpublish: (id) async {
                      await c.unpublish(id);
                      if (mounted) {
                        await ref.read(myActiveListingsProvider.notifier).refresh();
                      }
                    },
                    onRepublish: (id) async {
                      await c.resumeDraft(id);
                      final catId =
                          ref.read(postingControllerProvider).payload.categoryId?.toInt();
                      final ok = await c.publish();
                      if (mounted && ok) {
                        await ref
                            .read(myActiveListingsProvider.notifier)
                            .syncAfterPublish(listingCategoryId: catId);
                      }
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
    final disabledMsg = AppStrings.of(context, 'locationServiceDisabled');
    final deniedMsg = AppStrings.of(context, 'locationPermissionDenied');
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      if (!mounted) return;
      showAppNotification(context, disabledMsg);
      return;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      if (!mounted) return;
      showAppNotification(context, deniedMsg);
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
}

class _MyListingsView extends StatelessWidget {
  const _MyListingsView({
    required this.t,
    required this.flowUi,
    required this.onOpenListingDetail,
    required this.onStatus,
    required this.onResumeDraft,
    required this.onUnpublish,
    required this.onRepublish,
  });

  final String Function(String key) t;
  final PostingFlowUiSlice flowUi;
  final ValueChanged<int> onOpenListingDetail;
  final ValueChanged<String> onStatus;
  final ValueChanged<int> onResumeDraft;
  final Future<void> Function(int) onUnpublish;
  final Future<void> Function(int) onRepublish;

  @override
  Widget build(BuildContext context) {
    const statuses = ['draft', 'active', 'inactive', 'sold'];
    String statusLabel(String status) {
      switch (status) {
        case 'draft':
          return t('listingStatusDraft');
        case 'active':
          return t('listingStatusActive');
        case 'inactive':
          return t('listingStatusInactive');
        case 'sold':
          return t('listingStatusSold');
        default:
          return status;
      }
    }

    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: statuses.map((status) {
              final selected = flowUi.myStatus == status;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(statusLabel(status)),
                  selected: selected,
                  onSelected: (_) => onStatus(status),
                ),
              );
            }).toList(),
          ),
        ),
        Expanded(
          child: flowUi.isLoading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: flowUi.myListings.length,
                  itemBuilder: (context, index) {
                    final item = flowUi.myListings[index];
                    final coverUrl = ApiUrls.networkImageUrl(item.cover);
                    return ListTile(
                      onTap: () => onOpenListingDetail(item.id),
                      leading: coverUrl.isEmpty
                          ? const CircleAvatar(
                              child: Icon(Icons.inventory_2_outlined),
                            )
                          : CircleAvatar(
                              backgroundImage: NetworkImage(coverUrl),
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
                              child: Text(t('resumeListing')),
                            ),
                          if (item.status == 'active')
                            TextButton(
                              onPressed: () => onUnpublish(item.id),
                              child: Text(t('unpublishListing')),
                            ),
                          if (item.status == 'inactive')
                            TextButton(
                              onPressed: () => onRepublish(item.id),
                              child: Text(t('republishListing')),
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
