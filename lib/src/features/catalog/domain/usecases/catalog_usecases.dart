import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/repositories/catalog_repository.dart';

class EnsureCatalogReady {
  const EnsureCatalogReady(this._repository);

  final CatalogRepository _repository;

  Future<void> call() => _repository.ensureCatalogReady();
}

class GetCatalogCategories {
  const GetCatalogCategories(this._repository);

  final CatalogRepository _repository;

  Future<List<CatalogCategory>> call({
    bool includeInactive = false,
    String? query,
  }) =>
      _repository.getCategories(includeInactive: includeInactive, query: query);
}

class SaveCatalogCategory {
  const SaveCatalogCategory(this._repository);

  final CatalogRepository _repository;

  Future<CatalogCategory> call(CatalogCategory category) =>
      _repository.saveCategory(category);
}

class GetCatalogSubcategories {
  const GetCatalogSubcategories(this._repository);

  final CatalogRepository _repository;

  Future<List<CatalogSubcategory>> call({
    bool includeInactive = false,
    String? categoryId,
    String? query,
  }) => _repository.getSubcategories(
    includeInactive: includeInactive,
    categoryId: categoryId,
    query: query,
  );
}

class SaveCatalogSubcategory {
  const SaveCatalogSubcategory(this._repository);

  final CatalogRepository _repository;

  Future<CatalogSubcategory> call(CatalogSubcategory subcategory) =>
      _repository.saveSubcategory(subcategory);
}

class GetUnitsOfMeasure {
  const GetUnitsOfMeasure(this._repository);

  final CatalogRepository _repository;

  Future<List<UnitOfMeasure>> call({
    bool includeInactive = false,
    String? query,
  }) => _repository.getUnits(includeInactive: includeInactive, query: query);
}

class SaveUnitOfMeasure {
  const SaveUnitOfMeasure(this._repository);

  final CatalogRepository _repository;

  Future<UnitOfMeasure> call(UnitOfMeasure unit) => _repository.saveUnit(unit);
}

class CountProductsForCatalogCategory {
  const CountProductsForCatalogCategory(this._repository);

  final CatalogRepository _repository;

  Future<int> call(String normalizedName) =>
      _repository.countProductsForCategory(normalizedName);
}

class CountProductsForCatalogSubcategory {
  const CountProductsForCatalogSubcategory(this._repository);

  final CatalogRepository _repository;

  Future<int> call({
    required String categoryNormalizedName,
    required String subcategoryNormalizedName,
  }) => _repository.countProductsForSubcategory(
    categoryNormalizedName: categoryNormalizedName,
    subcategoryNormalizedName: subcategoryNormalizedName,
  );
}

class CountProductsForUnitOfMeasure {
  const CountProductsForUnitOfMeasure(this._repository);

  final CatalogRepository _repository;

  Future<int> call(String normalizedName) =>
      _repository.countProductsForUnit(normalizedName);
}
