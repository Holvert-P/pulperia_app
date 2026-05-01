import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';

abstract class CatalogRepository {
  Future<void> ensureCatalogReady();

  Future<List<CatalogCategory>> getCategories({
    bool includeInactive = false,
    String? query,
  });

  Future<CatalogCategory?> getCategoryById(String id);

  Future<CatalogCategory> saveCategory(CatalogCategory category);

  Future<List<CatalogSubcategory>> getSubcategories({
    bool includeInactive = false,
    String? categoryId,
    String? query,
  });

  Future<CatalogSubcategory?> getSubcategoryById(String id);

  Future<CatalogSubcategory> saveSubcategory(CatalogSubcategory subcategory);

  Future<List<UnitOfMeasure>> getUnits({
    bool includeInactive = false,
    String? query,
  });

  Future<UnitOfMeasure?> getUnitById(String id);

  Future<UnitOfMeasure> saveUnit(UnitOfMeasure unit);

  Future<int> countProductsForCategory(String normalizedName);

  Future<int> countProductsForSubcategory({
    required String categoryNormalizedName,
    required String subcategoryNormalizedName,
  });

  Future<int> countProductsForUnit(String normalizedName);
}

class CatalogValidationException implements Exception {
  const CatalogValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
