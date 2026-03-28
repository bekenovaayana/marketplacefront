import 'package:marketplace_frontend/features/home/models/home_models.dart';

class FixedCategoryDef {
  const FixedCategoryDef({
    required this.labelRu,
    required this.slugHints,
    this.nameHints = const [],
  });

  final String labelRu;
  final List<String> slugHints;
  final List<String> nameHints;
}

class ResolvedFixedCategory {
  const ResolvedFixedCategory({
    required this.labelRu,
    required this.categoryId,
    required this.isMatched,
    required this.slugHints,
    this.apiCategory,
  });

  final String labelRu;
  final int? categoryId;
  final bool isMatched;
  final List<String> slugHints;
  final HomeCategory? apiCategory;
}

class CategoryCatalog {
  CategoryCatalog._();

  static const List<FixedCategoryDef> fixed = [
    FixedCategoryDef(
      labelRu: 'Транспорт',
      slugHints: ['transport', 'vehicles', 'auto', 'cars', 'avto'],
      nameHints: ['транспорт', 'авто', 'transport'],
    ),
    FixedCategoryDef(
      labelRu: 'Недвижимость',
      slugHints: ['real-estate', 'property', 'nedvizhimost', 'realestate', 'real_estate'],
      nameHints: ['недвижимость', 'property', 'real estate'],
    ),
    FixedCategoryDef(
      labelRu: 'Дом и сад',
      slugHints: ['home', 'garden', 'dom', 'home-garden', 'dom_i_sad', 'dom-i-sad'],
      nameHints: ['дом и сад', 'home and garden'],
    ),
    FixedCategoryDef(
      labelRu: 'Услуги',
      slugHints: ['services', 'uslugi'],
      nameHints: ['услуги', 'services'],
    ),
    FixedCategoryDef(
      labelRu: 'Работа',
      slugHints: ['jobs', 'work', 'rabota'],
      nameHints: ['работа', 'jobs', 'work'],
    ),
    FixedCategoryDef(
      labelRu: 'Личные вещи',
      slugHints: ['personal', 'lichnye', 'personal-items', 'clothes', 'lichnye-veschi'],
      nameHints: ['личные вещи', 'одежда', 'personal'],
    ),
    FixedCategoryDef(
      labelRu: 'Животные',
      slugHints: ['pets', 'animals', 'zhivotnye'],
      nameHints: ['животные', 'pets', 'animals'],
    ),
    FixedCategoryDef(
      labelRu: 'Детский мир',
      slugHints: ['kids', 'children', 'baby', 'detsky', 'detskij', 'detskiy-mir', 'detmir', 'toys'],
      nameHints: ['детский мир', 'детские товары', 'kids', 'children', 'baby', 'toys'],
    ),
    FixedCategoryDef(
      labelRu: 'Спорт и хобби',
      slugHints: ['sport', 'hobby', 'sports', 'fitness', 'sport-i-hobbi'],
      nameHints: ['спорт и хобби', 'sport', 'hobby'],
    ),
    FixedCategoryDef(
      labelRu: 'Техника и электроника',
      slugHints: [
        'electronics',
        'tech',
        'tehnika',
        'devices',
        'electronics-and-tech',
        'tekhnika-i-elektronika',
        'gadgets',
      ],
      nameHints: ['техника и электроника', 'электроника', 'техника', 'electronics', 'tech', 'gadgets'],
    ),
  ];

  static String _norm(String value) => value.trim().toLowerCase();

  static List<ResolvedFixedCategory> resolve(List<HomeCategory> api) {
    final bySlug = <String, HomeCategory>{};
    for (final c in api) {
      final key = _norm(c.slug);
      bySlug.putIfAbsent(key, () => c);
    }
    final byName = <String, HomeCategory>{};
    for (final c in api) {
      final key = _norm(c.name);
      byName.putIfAbsent(key, () => c);
    }

    return fixed.map((def) {
      HomeCategory? hit;
      final slugs = def.slugHints.map(_norm).toList();
      final names = [def.labelRu, ...def.nameHints].map(_norm).toList();

      for (final h in slugs) {
        hit = bySlug[h];
        if (hit != null) break;
      }

      if (hit == null) {
        for (final c in api) {
          final slug = _norm(c.slug);
          if (slugs.any((h) => slug == h || slug.contains(h) || h.contains(slug))) {
            hit = c;
            break;
          }
        }
      }

      if (hit == null) {
        for (final h in names) {
          hit = byName[h];
          if (hit != null) break;
        }
      }

      if (hit == null) {
        for (final c in api) {
          final n = _norm(c.name);
          if (names.any((h) => n == h || n.contains(h) || h.contains(n))) {
            hit = c;
            break;
          }
        }
      }

      return ResolvedFixedCategory(
        labelRu: def.labelRu,
        categoryId: hit?.id,
        isMatched: hit != null,
        slugHints: def.slugHints,
        apiCategory: hit,
      );
    }).toList();
  }

  static List<ResolvedFixedCategory> forForm(List<HomeCategory> api) {
    final fixedResolved = resolve(api);
    final used = fixedResolved.where((r) => r.categoryId != null).map((r) => r.categoryId!).toSet();
    final tail = api
        .where((c) => !used.contains(c.id))
        .map(
          (c) => ResolvedFixedCategory(
            labelRu: c.name.isNotEmpty ? c.name : c.slug,
            categoryId: c.id,
            isMatched: true,
            slugHints: const [],
            apiCategory: c,
          ),
        )
        .toList();
    if (fixedResolved.any((r) => r.isMatched)) {
      return [...fixedResolved, ...tail];
    }
    return tail;
  }

  static (List<T>, List<T>) splitTwoRows<T>(List<T> items) {
    final mid = (items.length / 2).ceil();
    return (items.take(mid).toList(), items.skip(mid).toList());
  }
}
