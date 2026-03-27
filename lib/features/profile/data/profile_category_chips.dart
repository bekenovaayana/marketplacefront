import 'package:marketplace_frontend/features/home/models/home_models.dart';

/// Fixed Russian labels + possible API [slug] values for matching GET /categories.
class ProfileCategoryChipResolved {
  const ProfileCategoryChipResolved({
    required this.labelRu,
    required this.categoryId,
    required this.isMatched,
    required this.slugHints,
  });

  final String labelRu;
  final int? categoryId;
  final bool isMatched;
  final List<String> slugHints;
}

class ProfileCategoryChips {
  ProfileCategoryChips._();

  static const List<(String label, List<String> slugs)> definitions = [
    ('Транспорт', ['transport', 'vehicles', 'auto', 'cars', 'avto']),
    ('Недвижимость', [
      'real-estate',
      'property',
      'nedvizhimost',
      'realestate',
      'real_estate',
    ]),
    ('Дом и сад', ['home', 'garden', 'dom', 'home-garden', 'dom_i_sad']),
    ('Услуги', ['services', 'uslugi']),
    ('Работа', ['jobs', 'work', 'rabota']),
    ('Личные вещи', ['personal', 'lichnye', 'personal-items', 'clothes']),
    ('Животные', ['pets', 'animals', 'zhivotnye']),
    ('Детский мир', ['kids', 'children', 'baby', 'detsky', 'detskij']),
    ('Спорт и хобби', ['sport', 'hobby', 'sports', 'fitness']),
    ('Техника и электроника', [
      'electronics',
      'tech',
      'tehnika',
      'devices',
      'electronics-and-tech',
    ]),
  ];

  static List<ProfileCategoryChipResolved> resolve(List<HomeCategory> api) {
    final bySlug = <String, HomeCategory>{};
    for (final c in api) {
      bySlug[c.slug.toLowerCase().trim()] = c;
    }
    return definitions.map((def) {
      final hints = def.$2.map((s) => s.toLowerCase().trim()).toList();
      HomeCategory? hit;
      for (final h in hints) {
        hit = bySlug[h];
        if (hit != null) break;
      }
      if (hit == null) {
        for (final c in api) {
          final slug = c.slug.toLowerCase();
          if (hints.any((h) => slug == h || slug.contains(h) || h.contains(slug))) {
            hit = c;
            break;
          }
        }
      }
      return ProfileCategoryChipResolved(
        labelRu: def.$1,
        categoryId: hit?.id,
        isMatched: hit != null,
        slugHints: def.$2,
      );
    }).toList();
  }
}
