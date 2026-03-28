import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/features/auth/state/auth_state.dart';
import 'package:marketplace_frontend/features/posting/state/posting_controller.dart';
import 'package:marketplace_frontend/features/posting/data/posting_models.dart';
import 'package:marketplace_frontend/features/posting/ui/widgets/create_flow_view.dart';
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
    ref.listen<AuthState>(authControllerProvider, (prev, next) {
      if (!next.initialized) return;
      if (next.isAuthenticated && prev?.isAuthenticated != true) {
        ref.read(postingControllerProvider.notifier).init();
      }
    });
    if (!auth.isAuthenticated) {
      return Scaffold(
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
