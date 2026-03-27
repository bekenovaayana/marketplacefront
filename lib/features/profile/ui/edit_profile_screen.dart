import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:marketplace_frontend/features/auth/state/auth_controller.dart';
import 'package:marketplace_frontend/core/errors/error_mapper.dart';
import 'package:marketplace_frontend/features/profile/data/profile_models.dart';
import 'package:marketplace_frontend/features/profile/state/profile_controller.dart';
import 'package:marketplace_frontend/features/profile/state/profile_validation.dart';
import 'package:marketplace_frontend/shared/widgets/app_notification_overlay.dart';
import 'package:marketplace_frontend/shared/widgets/app_scaffold.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  final _fullNameController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _cityController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityFocusNode = FocusNode();
  Timer? _cityDebounce;
  String _selectedLanguage = 'en';
  bool _guestRedirectScheduled = false;
  String? _localAvatarPreviewPath;
  XFile? _lastCroppedAvatar;
  bool _isPreparingAvatar = false;

  bool _seeded = false;
  UserMeResponse? _baseline;

  @override
  void initState() {
    super.initState();
    _fullNameController.addListener(_markDirtyRebuild);
    _firstNameController.addListener(_markDirtyRebuild);
    _lastNameController.addListener(_markDirtyRebuild);
    _bioController.addListener(_markDirtyRebuild);
    _cityController.addListener(_onCityChanged);
    _phoneController.addListener(_onPhoneChanged);
    _cityFocusNode.addListener(() {
      if (!_cityFocusNode.hasFocus) {
        ref.read(profileControllerProvider.notifier).clearCitySuggestions();
      }
    });
    Future.microtask(() {
      if (ref.read(profileControllerProvider).profile == null) {
        ref.read(profileControllerProvider.notifier).load();
      }
    });
  }

  @override
  void dispose() {
    _cityDebounce?.cancel();
    _fullNameController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _cityFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileControllerProvider);
    final profile = state.profile;

    if (!_seeded && profile != null) {
      _seeded = true;
      _baseline = profile;
      _fullNameController.text = profile.fullName;
      _firstNameController.text = profile.firstName;
      _lastNameController.text = profile.lastName;
      _bioController.text = profile.bio;
      _cityController.text = profile.city;
      _phoneController.text = profile.phone;
      _selectedLanguage =
          (profile.preferredLanguage == 'ru' ||
              profile.preferredLanguage == 'en')
          ? profile.preferredLanguage
          : 'en';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }

    final auth = ref.watch(authControllerProvider);
    if (auth.initialized && auth.isGuest && !_guestRedirectScheduled) {
      _guestRedirectScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        final from = Uri.encodeComponent(
          GoRouterState.of(context).uri.toString(),
        );
        context.go('/auth-gate?from=$from');
      });
    }

    final currentLanguage = _selectedLanguage;

    return AppScaffold(
      title: 'Edit profile',
      actions: [
        IconButton(
          tooltip: 'Change avatar',
          onPressed: (state.isUploadingAvatar || _isPreparingAvatar)
              ? null
              : _pickAvatar,
          icon: state.isUploadingAvatar
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.image_outlined),
        ),
      ],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: ListView(
              children: [
                if (state.error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      ErrorMapper.friendly(state.error),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                _AvatarPreview(
                  networkUrl: profile?.avatarUrl,
                  localPath: _localAvatarPreviewPath,
                  isUploading: state.isUploadingAvatar || _isPreparingAvatar,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: 'Full name',
                    errorText: _backendError(state, 'full_name'),
                  ),
                  validator: ProfileValidation.validateFullName,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'First name',
                    errorText: _backendError(state, 'first_name'),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Last name',
                    errorText: _backendError(state, 'last_name'),
                  ),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _bioController,
                  decoration: InputDecoration(
                    labelText: 'About me (optional)',
                    errorText: _backendError(state, 'bio'),
                  ),
                  maxLines: 4,
                  validator: ProfileValidation.validateBioOptional,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  focusNode: _cityFocusNode,
                  controller: _cityController,
                  decoration: InputDecoration(
                    labelText: 'City',
                    errorText: _backendError(state, 'city'),
                  ),
                ),
                if (state.citySuggestions.isNotEmpty && _cityFocusNode.hasFocus)
                  ...state.citySuggestions
                      .take(6)
                      .map(
                        (city) => ListTile(
                          dense: true,
                          title: Text(city),
                          onTap: () {
                            _cityController.text = city;
                            _cityController.selection =
                                TextSelection.fromPosition(
                                  TextPosition(offset: city.length),
                                );
                            ref
                                .read(profileControllerProvider.notifier)
                                .clearCitySuggestions();
                            _markDirtyRebuild();
                          },
                        ),
                      ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  key: ValueKey<String>(_selectedLanguage),
                  initialValue: currentLanguage == 'ru' ? 'ru' : 'en',
                  decoration: InputDecoration(
                    labelText: 'Preferred language',
                    errorText: _backendError(state, 'preferred_language'),
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: ProfileValidation.validatePreferredLanguage,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English (en)')),
                    DropdownMenuItem(value: 'ru', child: Text('Russian (ru)')),
                  ],
                  onChanged: state.isSaving
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => _selectedLanguage = value);
                          _markDirtyRebuild();
                        },
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[+\d]')),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Phone (optional)',
                    hintText: '+996500123456',
                    helperText:
                        'KG numbers only: +996 and 9 digits (or leave empty)',
                    errorText: _backendError(state, 'phone'),
                  ),
                  validator: ProfileValidation.validatePhoneOptional,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                ),
                const SizedBox(height: 12),
                if (profile != null)
                  TextFormField(
                    initialValue: profile.email,
                    enabled: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: state.isSaving ? null : _submitProfile,
                  child: state.isSaving
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submitProfile() async {
    final auth = ref.read(authControllerProvider);
    if (!auth.isAuthenticated) {
      if (!context.mounted) return;
      final from = Uri.encodeComponent(
        GoRouterState.of(context).uri.toString(),
      );
      await context.push<void>('/auth-gate?from=$from');
      return;
    }

    if (!_formKey.currentState!.validate()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the highlighted fields')),
      );
      return;
    }

    final baseline = _baseline;
    if (baseline == null) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile is still loading')));
      return;
    }

    if (!_isDirty()) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    final request = UpdateUserMeRequest(
      fullName: _diff(baseline.fullName, _fullNameController.text),
      firstName: _diff(baseline.firstName, _firstNameController.text),
      lastName: _diff(baseline.lastName, _lastNameController.text),
      bio: _diff(baseline.bio, _bioController.text),
      city: _diff(baseline.city, _cityController.text),
      preferredLanguage: _diff(
        _normalizeLang(baseline.preferredLanguage),
        _normalizeLang(_selectedLanguage),
      ),
      phone: _phonePatchValue(baseline.phone, _phoneController.text),
    );

    if (request.toJson().isEmpty) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No changes to save')));
      return;
    }

    await ref.read(profileControllerProvider.notifier).save(request: request);
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final err = ref.read(profileControllerProvider).error;
    if (err != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(ErrorMapper.friendly(err))),
      );
      return;
    }

    setState(() {
      _baseline = ref.read(profileControllerProvider).profile;
    });
    if (!mounted) return;
    messenger.showSnackBar(
      const SnackBar(content: Text('Profile updated successfully')),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _pickAvatar() async {
    final messenger = ScaffoldMessenger.of(context);
    final source = await _showAvatarSourcePicker();
    if (source == null) return;
    final file = await _pickAvatarBySource(source);
    if (file == null) return;
    setState(() => _isPreparingAvatar = true);
    final cropped = await _cropSquareAvatar(file.path);
    if (cropped == null) {
      if (mounted) setState(() => _isPreparingAvatar = false);
      return;
    }
    final compressed = await _compressAvatar(cropped);
    if (!mounted) return;
    setState(() {
      _isPreparingAvatar = false;
      _lastCroppedAvatar = compressed;
      _localAvatarPreviewPath = compressed.path;
    });
    final validationError = await _validateAvatarBeforeUpload(compressed);
    if (validationError != null) {
      messenger.showSnackBar(SnackBar(content: Text(validationError)));
      return;
    }
    await _uploadAvatar(compressed);
  }

  Future<_AvatarSource?> _showAvatarSourcePicker() async {
    return showModalBottomSheet<_AvatarSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Camera'),
              onTap: () => Navigator.of(context).pop(_AvatarSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Gallery'),
              onTap: () => Navigator.of(context).pop(_AvatarSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('Files / Screenshots'),
              onTap: () => Navigator.of(context).pop(_AvatarSource.files),
            ),
          ],
        ),
      ),
    );
  }

  Future<XFile?> _pickAvatarBySource(_AvatarSource source) async {
    switch (source) {
      case _AvatarSource.camera:
        return _picker.pickImage(source: ImageSource.camera);
      case _AvatarSource.gallery:
        return _picker.pickImage(source: ImageSource.gallery);
      case _AvatarSource.files:
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: const ['jpg', 'jpeg', 'png'],
          withData: false,
        );
        final path = picked?.files.single.path;
        if (path == null || path.isEmpty) return null;
        return XFile(path);
    }
  }

  Future<XFile?> _cropSquareAvatar(String path) async {
    final cropped = await ImageCropper().cropImage(
      sourcePath: path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop avatar',
          lockAspectRatio: true,
          hideBottomControls: false,
        ),
        IOSUiSettings(
          title: 'Crop avatar',
          aspectRatioLockEnabled: true,
          resetAspectRatioEnabled: false,
          rotateButtonsHidden: true,
        ),
      ],
    );
    if (cropped == null) return null;
    return XFile(cropped.path);
  }

  Future<XFile> _compressAvatar(XFile file) async {
    final size = await file.length();
    if (size <= 2 * 1024 * 1024) return file;
    final targetPath = '${file.path}_compressed.jpg';
    final compressed = await FlutterImageCompress.compressAndGetFile(
      file.path,
      targetPath,
      quality: 86,
      format: CompressFormat.jpeg,
      minWidth: 1080,
      minHeight: 1080,
    );
    if (compressed == null) return file;
    return XFile(compressed.path);
  }

  Future<String?> _validateAvatarBeforeUpload(XFile file) async {
    final size = await file.length();
    if (size > 5242880) {
      return 'Avatar is too large. Maximum is 5MB.';
    }
    final pathLower = file.path.toLowerCase();
    if (!(pathLower.endsWith('.jpg') ||
        pathLower.endsWith('.jpeg') ||
        pathLower.endsWith('.png'))) {
      return 'Unsupported avatar format. Use jpg/png.';
    }
    return null;
  }

  Future<void> _uploadAvatar(XFile file) async {
    await ref.read(profileControllerProvider.notifier).uploadAvatar(file);
    if (!mounted) return;
    final latest = ref.read(profileControllerProvider);
    if (latest.error == null) {
      showAppNotification(context, 'Avatar updated');
      setState(() {
        _localAvatarPreviewPath = null;
      });
    } else {
      final message = ErrorMapper.friendly(latest.error);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: 'Retry',
            onPressed: () {
              final retryFile = _lastCroppedAvatar;
              if (retryFile == null) return;
              _uploadAvatar(retryFile);
            },
          ),
        ),
      );
    }
  }

  String? _diff(String? baseline, String next) {
    final trimmed = next.trim();
    final base = (baseline ?? '').trim();
    if (trimmed == base) return null;
    return trimmed;
  }

  void _markDirtyRebuild() {
    if (mounted) setState(() {});
  }

  void _onCityChanged() {
    _markDirtyRebuild();
    _cityDebounce?.cancel();
    _cityDebounce = Timer(const Duration(milliseconds: 300), () {
      ref
          .read(profileControllerProvider.notifier)
          .loadCitySuggestions(_cityController.text);
    });
  }

  void _onPhoneChanged() {
    _markDirtyRebuild();
    final normalized = ProfileValidation.normalizeKgPhoneInput(
      _phoneController.text,
    );
    if (normalized == _phoneController.text) return;
    _phoneController.value = TextEditingValue(
      text: normalized,
      selection: TextSelection.collapsed(offset: normalized.length),
    );
  }

  static String _normalizeLang(String? raw) {
    final v = (raw ?? '').trim().toLowerCase();
    return v == 'ru' ? 'ru' : 'en';
  }

  static String _phoneCanonical(String? raw) {
    final n = ProfileValidation.normalizeKgPhoneInput(raw ?? '');
    final digits = n.length > 4 ? n.substring(4) : '';
    if (digits.isEmpty) return '';
    return n;
  }

  static String? _phonePatchValue(String? baselinePhone, String input) {
    final n = ProfileValidation.normalizeKgPhoneInput(input);
    final digits = n.length > 4 ? n.substring(4) : '';
    final base = ProfileValidation.normalizeKgPhoneInput(baselinePhone ?? '');
    final baseDigits = base.length > 4 ? base.substring(4) : '';
    if (digits.isEmpty) {
      if (baseDigits.isEmpty) return null;
      return '';
    }
    if (!RegExp(r'^\+996\d{9}$').hasMatch(n)) {
      return null;
    }
    if (n == base) return null;
    return n;
  }

  bool _isDirty() {
    final baseline = _baseline;
    if (baseline == null) return false;
    return _diff(baseline.fullName, _fullNameController.text) != null ||
        _diff(baseline.firstName, _firstNameController.text) != null ||
        _diff(baseline.lastName, _lastNameController.text) != null ||
        _diff(baseline.bio, _bioController.text) != null ||
        _diff(baseline.city, _cityController.text) != null ||
        _diff(
              _normalizeLang(baseline.preferredLanguage),
              _normalizeLang(_selectedLanguage),
            ) !=
            null ||
        _phoneCanonical(baseline.phone) !=
            _phoneCanonical(_phoneController.text);
  }

  String? _backendError(ProfileState state, String key) {
    final message = state.fieldErrors[key];
    if (message == null || message.isEmpty) return null;
    return message;
  }
}

enum _AvatarSource { camera, gallery, files }

class _AvatarPreview extends StatelessWidget {
  const _AvatarPreview({
    required this.networkUrl,
    required this.localPath,
    required this.isUploading,
  });

  final String? networkUrl;
  final String? localPath;
  final bool isUploading;

  @override
  Widget build(BuildContext context) {
    ImageProvider? imageProvider;
    if (localPath != null && localPath!.isNotEmpty) {
      imageProvider = FileImage(File(localPath!));
    } else if (networkUrl != null && networkUrl!.isNotEmpty) {
      imageProvider = NetworkImage(networkUrl!);
    }
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircleAvatar(
            radius: 44,
            backgroundImage: imageProvider,
            child: imageProvider == null
                ? const Icon(Icons.person, size: 34)
                : null,
          ),
          if (isUploading)
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0x66000000),
                ),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.4),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
