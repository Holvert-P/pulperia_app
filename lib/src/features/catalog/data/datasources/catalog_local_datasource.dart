import 'package:app/src/features/catalog/data/models/category_model.dart';
import 'package:app/src/features/catalog/data/models/subcategory_model.dart';
import 'package:app/src/features/catalog/data/models/unit_of_measure_model.dart';

abstract class CatalogLocalDataSource {
  Future<void> ensureCatalogReady();

  Future<List<CategoryModel>> getCategories({
    bool includeInactive = false,
    String? query,
  });

  Future<CategoryModel?> getCategoryById(String id);

  Future<CategoryModel?> getCategoryByNormalizedName(String normalizedName);

  Future<void> saveCategory(CategoryModel category);

  Future<void> updateCategory(
    CategoryModel category, {
    required String previousNormalizedName,
  });

  Future<List<SubcategoryModel>> getSubcategories({
    bool includeInactive = false,
    String? categoryId,
    String? query,
  });

  Future<SubcategoryModel?> getSubcategoryById(String id);

  Future<SubcategoryModel?> getSubcategoryByNormalizedName({
    required String categoryId,
    required String normalizedName,
  });

  Future<void> saveSubcategory(SubcategoryModel subcategory);

  Future<void> updateSubcategory(
    SubcategoryModel subcategory, {
    required String previousCategoryId,
    required String previousNormalizedName,
  });

  Future<List<UnitOfMeasureModel>> getUnits({
    bool includeInactive = false,
    String? query,
  });

  Future<UnitOfMeasureModel?> getUnitById(String id);

  Future<UnitOfMeasureModel?> getUnitByNormalizedName(String normalizedName);

  Future<void> saveUnit(UnitOfMeasureModel unit);

  Future<void> updateUnit(
    UnitOfMeasureModel unit, {
    required String previousNormalizedName,
  });

  Future<int> countProductsForCategory(String normalizedName);

  Future<int> countProductsForSubcategory({
    required String categoryNormalizedName,
    required String subcategoryNormalizedName,
  });

  Future<int> countProductsForUnit(String normalizedName);
}
