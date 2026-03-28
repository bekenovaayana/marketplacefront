import 'package:marketplace_frontend/features/home/models/home_models.dart';
import 'package:marketplace_frontend/shared/data/category_catalog.dart';

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

  static List<ProfileCategoryChipResolved> resolve(List<HomeCategory> api) {
    return CategoryCatalog.resolve(api)
        .map(
          (r) => ProfileCategoryChipResolved(
            labelRu: r.labelRu,
            categoryId: r.categoryId,
            isMatched: r.isMatched,
            slugHints: r.slugHints,
          ),
        )
        .toList();
  }
}
