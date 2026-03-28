import 'package:flutter/material.dart';
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

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late final TextEditingController _cityController;
  late final TextEditingController _latController;
  late final TextEditingController _lngController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _cityController = TextEditingController(text: widget.initialCity ?? '');
    _latController = TextEditingController(
      text: widget.initialLat?.toString() ?? '',
    );
    _lngController = TextEditingController(
      text: widget.initialLng?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final lat = double.parse(_latController.text.trim());
    final lng = double.parse(_lngController.text.trim());
    Navigator.of(context).pop(
      LocationPickResult(
        city: _cityController.text.trim(),
        latitude: lat,
        longitude: lng,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String t(String key) => AppStrings.of(context, key);
    return Scaffold(
      appBar: AppBar(title: Text(t('pickLocationTitle'))),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
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
                  if (value == null) {
                    return t('fieldLatitudeNumber');
                  }
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
                  if (value == null) {
                    return t('fieldLongitudeNumber');
                  }
                  if (value < -180 || value > 180) {
                    return t('fieldLongitudeRange');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submit,
                child: Text(t('useThisLocation')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
