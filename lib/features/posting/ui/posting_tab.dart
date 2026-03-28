import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/posting/ui/location_pick_result.dart';
import 'package:marketplace_frontend/features/posting/ui/location_picker_screen.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/ui/widgets/create_flow_view.dart';
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _syncControllers(next.payload);
      });
    });

    final state = ref.watch(postingControllerProvider);
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
          if (state.isSavingDraft) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: _modeIndex == 0
                ? CreateFlowView(
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
                    onPickLocationOnMap: () => _pickLocationOnMap(c),
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
                    t: t,
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
    final picked = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'mp4', 'webm', 'mov'],
    );
    if (picked != null) {
      final files = picked.files
          .where((f) => (f.path ?? '').isNotEmpty)
          .map((f) => XFile(f.path!))
          .toList();
      if (files.isNotEmpty) {
        await c.addPhotos(files);
      }
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
    await c.setCurrentLocation(lat: pos.latitude, lng: pos.longitude);
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
    required this.state,
    required this.onStatus,
    required this.onResumeDraft,
    required this.onUnpublish,
    required this.onRepublish,
  });

  final String Function(String key) t;
  final PostingState state;
  final ValueChanged<String> onStatus;
  final ValueChanged<int> onResumeDraft;
  final ValueChanged<int> onUnpublish;
  final ValueChanged<int> onRepublish;

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
              final selected = state.myStatus == status;
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
