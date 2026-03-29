import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:marketplace_frontend/features/posting/data/kg_regions.dart';
import 'package:marketplace_frontend/features/posting/ui/location_pick_result.dart';
import 'package:marketplace_frontend/shared/l10n/app_strings.dart';

class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({
    super.key,
    this.initialCity,
    this.initialLat,
    this.initialLng,
  });

  final String? initialCity;
  final double? initialLat;
  final double? initialLng;

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  static const LatLng _defaultCenter = LatLng(42.8746, 74.5698);

  late TabController _tabs;
  GoogleMapController? _mapController;
  LatLng? _mapPin;
  String _resolvedCity = '';
  bool _resolving = false;
  bool _loadingGps = false;

  late final TextEditingController _cityController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  final _manualFormKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    final lat = widget.initialLat;
    final lng = widget.initialLng;
    if (lat != null && lng != null) {
      _mapPin = LatLng(lat, lng);
    }
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _latController = TextEditingController(text: lat?.toString() ?? '');
    _lngController = TextEditingController(text: lng?.toString() ?? '');
  }

  @override
  void dispose() {
    _tabs.dispose();
    _mapController?.dispose();
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  Future<void> _resolveCity(LatLng point) async {
    setState(() => _resolving = true);
    try {
      final list = await placemarkFromCoordinates(point.latitude, point.longitude);
      final p = list.isNotEmpty ? list.first : null;
      final locality = p?.locality?.trim() ?? '';
      final sub = p?.subAdministrativeArea?.trim() ?? '';
      final admin = p?.administrativeArea?.trim() ?? '';
      final city = locality.isNotEmpty
          ? locality
          : (sub.isNotEmpty ? sub : admin);
      setState(() => _resolvedCity = city);
    } catch (_) {
      setState(() => _resolvedCity = '');
    } finally {
      if (mounted) setState(() => _resolving = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _loadingGps = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (mounted) _toast(AppStrings.of(context, 'locationServiceDisabled'));
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) _toast(AppStrings.of(context, 'locationPermissionDenied'));
        return;
      }
      final pos = await Geolocator.getCurrentPosition();
      final point = LatLng(pos.latitude, pos.longitude);
      setState(() => _mapPin = point);
      await _resolveCity(point);
      await _mapController?.animateCamera(CameraUpdate.newLatLngZoom(point, 14));
    } finally {
      if (mounted) setState(() => _loadingGps = false);
    }
  }

  void _toast(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  void _popWith(LatLng point, String city) {
    Navigator.of(context).pop(
      LocationPickResult(
        city: city.trim().isEmpty ? 'Unknown' : city.trim(),
        latitude: point.latitude,
        longitude: point.longitude,
      ),
    );
  }

  void _submitManual() {
    if (!_manualFormKey.currentState!.validate()) return;
    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());
    _popWith(LatLng(lat, lng), _cityController.text.trim());
  }

  void _submitMap() {
    final pin = _mapPin;
    if (pin == null) return;
    final city = _resolvedCity.isNotEmpty ? _resolvedCity : _cityController.text.trim();
    _popWith(pin, city);
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => AppStrings.of(context, key);

    return Scaffold(
      appBar: AppBar(
        title: Text(t('pickLocationTitle')),
        bottom: TabBar(
          controller: _tabs,
          tabs: [
            Tab(text: t('locationTabMap')),
            Tab(text: t('locationTabManual')),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          Stack(
            children: [
              GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _mapPin ?? _defaultCenter,
                  zoom: _mapPin != null ? 14 : 11,
                ),
                onMapCreated: (c) => _mapController = c,
                onTap: (ll) async {
                  setState(() => _mapPin = ll);
                  await _resolveCity(ll);
                },
                markers: _mapPin == null
                    ? {}
                    : {
                        Marker(
                          markerId: const MarkerId('pin'),
                          position: _mapPin!,
                        ),
                      },
                myLocationButtonEnabled: false,
              ),
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: Material(
                  elevation: 2,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      t('locationPickOnMapHint'),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 72,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'gps',
                  onPressed: _loadingGps ? null : _useCurrentLocation,
                  child: _loadingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.my_location),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_resolving)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          t('locationGeocoding'),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      )
                    else if (_resolvedCity.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _resolvedCity,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                      ),
                    FilledButton(
                      onPressed: _mapPin == null ? null : _submitMap,
                      child: Text(t('locationDone')),
                    ),
                  ],
                ),
              ),
            ],
          ),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Form(
                key: _manualFormKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
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
                                      setState(() => _cityController.text = e.city);
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
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _cityController,
                      decoration: InputDecoration(labelText: t('cityLabel')),
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? t('fieldCityRequired')
                          : null,
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _latController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(labelText: t('labelLatitude')),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t('fieldLatitudeRequired');
                        }
                        final value = double.tryParse(v.trim());
                        if (value == null) return t('fieldLatitudeNumber');
                        if (value < -90 || value > 90) {
                          return t('fieldLatitudeRange');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    TextFormField(
                      controller: _lngController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: InputDecoration(labelText: t('labelLongitude')),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return t('fieldLongitudeRequired');
                        }
                        final value = double.tryParse(v.trim());
                        if (value == null) return t('fieldLongitudeNumber');
                        if (value < -180 || value > 180) {
                          return t('fieldLongitudeRange');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: _submitManual,
                      child: Text(t('useThisLocation')),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
