import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:marketplace_frontend/features/listings/state/listings_controller.dart';

class CreateListingPage extends ConsumerStatefulWidget {
  const CreateListingPage({super.key});

  @override
  ConsumerState<CreateListingPage> createState() => _CreateListingPageState();
}

class _CreateListingPageState extends ConsumerState<CreateListingPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _cityController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create listing')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 4,
                validator: (v) => (v == null || v.length < 10) ? 'Min 10 chars' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Price'),
                keyboardType: TextInputType.number,
                validator: (v) => double.tryParse(v ?? '') == null ? 'Invalid number' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _cityController,
                decoration: const InputDecoration(labelText: 'City'),
                validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _submitting
                    ? null
                    : () async {
                        if (!_formKey.currentState!.validate()) {
                          return;
                        }
                        setState(() => _submitting = true);
                        await ref.read(listingsControllerProvider.notifier).createListing(
                              title: _titleController.text.trim(),
                              description: _descriptionController.text.trim(),
                              price: double.parse(_priceController.text.trim()),
                              city: _cityController.text.trim(),
                            );
                        if (!context.mounted) {
                          return;
                        }
                        context.pop();
                      },
                child: _submitting
                    ? const CircularProgressIndicator()
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
