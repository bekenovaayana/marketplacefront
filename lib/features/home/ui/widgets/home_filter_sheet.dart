import 'package:flutter/material.dart';
import 'package:marketplace_frontend/features/home/data/home_repository.dart';
import 'package:marketplace_frontend/features/home/models/home_models.dart';

class HomeFilterSheet extends StatefulWidget {
  const HomeFilterSheet({
    super.key,
    required this.categories,
    required this.facets,
    required this.initial,
  });

  final List<HomeCategory> categories;
  final ListingsFacets facets;
  final ListingQuery initial;

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late String _city;
  late String _minPrice;
  late String _maxPrice;
  late String _sort;
  int? _categoryId;

  @override
  void initState() {
    super.initState();
    _city = widget.initial.city ?? '';
    _minPrice = widget.initial.minPrice?.toString() ?? '';
    _maxPrice = widget.initial.maxPrice?.toString() ?? '';
    _sort = widget.initial.sort;
    _categoryId = widget.initial.categoryId;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              initialValue: _categoryId,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem<int?>(value: null, child: Text('All categories')),
                ...widget.categories.where((category) {
                  if (widget.facets.categories.isEmpty) return true;
                  return widget.facets.categories.any((f) => f.id == category.id);
                }).map(
                  (category) => DropdownMenuItem<int?>(
                    value: category.id,
                    child: Text(
                      widget.facets.categories
                              .firstWhere(
                                (f) => f.id == category.id,
                                orElse: () => const FacetCategory(id: 0, slug: '', count: -1),
                              )
                              .count >
                          -1
                          ? '${category.name} (${widget.facets.categories.firstWhere((f) => f.id == category.id, orElse: () => const FacetCategory(id: 0, slug: '', count: 0)).count})'
                          : category.name,
                    ),
                  ),
                ),
              ],
              onChanged: (value) => setState(() => _categoryId = value),
            ),
            const SizedBox(height: 10),
            TextFormField(
              initialValue: _city,
              decoration: InputDecoration(
                labelText: 'City',
                helperText: widget.facets.cities.isEmpty
                    ? null
                    : 'Available: ${widget.facets.cities.map((e) => e.city).take(4).join(', ')}',
              ),
              onChanged: (value) => _city = value,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: _minPrice,
                    decoration: InputDecoration(
                      labelText: 'Min price',
                      hintText: widget.facets.priceMin?.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _minPrice = value,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: _maxPrice,
                    decoration: InputDecoration(
                      labelText: 'Max price',
                      hintText: widget.facets.priceMax?.toStringAsFixed(0),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (value) => _maxPrice = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: _sort,
              decoration: const InputDecoration(labelText: 'Sort'),
              items: const [
                DropdownMenuItem(value: 'newest', child: Text('Newest')),
                DropdownMenuItem(value: 'price_asc', child: Text('Price asc')),
                DropdownMenuItem(value: 'price_desc', child: Text('Price desc')),
                DropdownMenuItem(value: 'recommended', child: Text('Recommended')),
                DropdownMenuItem(value: 'relevance', child: Text('Relevance')),
              ],
              onChanged: (value) => setState(() => _sort = value ?? 'newest'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        const ListingQuery(),
                      );
                    },
                    child: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(
                        ListingQuery(
                          q: widget.initial.q,
                          categoryId: _categoryId,
                          city: _city.isEmpty ? null : _city,
                          minPrice: double.tryParse(_minPrice),
                          maxPrice: double.tryParse(_maxPrice),
                          sort: _sort,
                          page: 1,
                          pageSize: widget.initial.pageSize,
                        ),
                      );
                    },
                    child: const Text('Apply'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
