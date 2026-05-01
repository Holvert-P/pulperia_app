import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/catalog/data/datasources/catalog_local_datasource.dart';
import 'package:app/src/features/catalog/data/datasources/catalog_local_datasource_impl.dart';
import 'package:app/src/features/catalog/data/models/category_model.dart';
import 'package:app/src/features/catalog/data/models/subcategory_model.dart';
import 'package:app/src/features/catalog/data/models/unit_of_measure_model.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:app/src/features/catalog/domain/services/catalog_text_normalizer.dart';

class CatalogRepositoryImpl implements CatalogRepository {
  CatalogRepositoryImpl({
    AppDatabase? database,
    CatalogLocalDataSource? localDataSource,
  }) : _localDataSource =
           localDataSource ??
           CatalogLocalDataSourceImpl(
             database: database ?? AppDatabase.instance,
           );

  final CatalogLocalDataSource _localDataSource;

  @override
  Future<void> ensureCatalogReady() => _localDataSource.ensureCatalogReady();

  @override
  Future<List<CatalogCategory>> getCategories({
    bool includeInactive = false,
    String? query,
  }) async => (await _localDataSource.getCategories(
    includeInactive: includeInactive,
    query: query,
  )).map((model) => model.toEntity()).toList();

  @override
  Future<CatalogCategory?> getCategoryById(String id) async =>
      (await _localDataSource.getCategoryById(id))?.toEntity();

  @override
  Future<CatalogCategory> saveCategory(CatalogCategory category) async {
    final normalized = _normalizeRequired(category.name, 'La categoria');
    final existing = await _localDataSource.getCategoryByNormalizedName(
      normalized,
    );
    if (existing != null && existing.id != category.id) {
      throw const CatalogValidationException('Ya existe una categoria igual.');
    }

    final now = DateTime.now();
    final isNew = category.id.trim().isEmpty;
    final current = isNew
        ? null
        : await _localDataSource.getCategoryById(category.id);
    final item = CatalogCategory(
      id: isNew ? _newId('cat') : category.id,
      name: category.name.trim(),
      normalizedName: normalized,
      description: category.description,
      iconName: category.iconName,
      colorHex: category.colorHex,
      sortOrder: category.sortOrder,
      isActive: category.isActive,
      createdAt: isNew ? now : category.createdAt,
      updatedAt: now,
      subcategoryCount: category.subcategoryCount,
      productCount: category.productCount,
    );
    final model = CategoryModel.fromEntity(item);
    if (isNew) {
      await _localDataSource.saveCategory(model);
    } else {
      await _localDataSource.updateCategory(
        model,
        previousNormalizedName:
            current?.normalizedName ?? category.normalizedName,
      );
    }
    return item;
  }

  @override
  Future<List<CatalogSubcategory>> getSubcategories({
    bool includeInactive = false,
    String? categoryId,
    String? query,
  }) async => (await _localDataSource.getSubcategories(
    includeInactive: includeInactive,
    categoryId: categoryId,
    query: query,
  )).map((model) => model.toEntity()).toList();

  @override
  Future<CatalogSubcategory?> getSubcategoryById(String id) async =>
      (await _localDataSource.getSubcategoryById(id))?.toEntity();

  @override
  Future<CatalogSubcategory> saveSubcategory(
    CatalogSubcategory subcategory,
  ) async {
    if (subcategory.categoryId.trim().isEmpty) {
      throw const CatalogValidationException('Selecciona una categoria.');
    }
    final normalized = _normalizeRequired(subcategory.name, 'La subcategoria');
    final existing = await _localDataSource.getSubcategoryByNormalizedName(
      categoryId: subcategory.categoryId,
      normalizedName: normalized,
    );
    if (existing != null && existing.id != subcategory.id) {
      throw const CatalogValidationException(
        'Ya existe una subcategoria igual en esa categoria.',
      );
    }

    final now = DateTime.now();
    final isNew = subcategory.id.trim().isEmpty;
    final current = isNew
        ? null
        : await _localDataSource.getSubcategoryById(subcategory.id);
    final item = CatalogSubcategory(
      id: isNew ? _newId('sub') : subcategory.id,
      categoryId: subcategory.categoryId,
      name: subcategory.name.trim(),
      normalizedName: normalized,
      description: subcategory.description,
      sortOrder: subcategory.sortOrder,
      isActive: subcategory.isActive,
      createdAt: isNew ? now : subcategory.createdAt,
      updatedAt: now,
      categoryName: subcategory.categoryName,
      categoryNormalizedName: subcategory.categoryNormalizedName,
      productCount: subcategory.productCount,
    );
    final model = SubcategoryModel.fromEntity(item);
    if (isNew) {
      await _localDataSource.saveSubcategory(model);
    } else {
      await _localDataSource.updateSubcategory(
        model,
        previousCategoryId: current?.categoryId ?? subcategory.categoryId,
        previousNormalizedName:
            current?.normalizedName ?? subcategory.normalizedName,
      );
    }
    return item;
  }

  @override
  Future<List<UnitOfMeasure>> getUnits({
    bool includeInactive = false,
    String? query,
  }) async => (await _localDataSource.getUnits(
    includeInactive: includeInactive,
    query: query,
  )).map((model) => model.toEntity()).toList();

  @override
  Future<UnitOfMeasure?> getUnitById(String id) async =>
      (await _localDataSource.getUnitById(id))?.toEntity();

  @override
  Future<UnitOfMeasure> saveUnit(UnitOfMeasure unit) async {
    final normalized = _normalizeRequired(unit.name, 'La unidad');
    final existing = await _localDataSource.getUnitByNormalizedName(normalized);
    if (existing != null && existing.id != unit.id) {
      throw const CatalogValidationException('Ya existe una unidad igual.');
    }

    final now = DateTime.now();
    final isNew = unit.id.trim().isEmpty;
    final current = isNew ? null : await _localDataSource.getUnitById(unit.id);
    final item = UnitOfMeasure(
      id: isNew ? _newId('unit') : unit.id,
      name: unit.name.trim(),
      normalizedName: normalized,
      symbol: _blankToNull(unit.symbol),
      allowsDecimal: unit.allowsDecimal,
      description: _blankToNull(unit.description),
      sortOrder: unit.sortOrder,
      isActive: unit.isActive,
      createdAt: isNew ? now : unit.createdAt,
      updatedAt: now,
      productCount: unit.productCount,
    );
    final model = UnitOfMeasureModel.fromEntity(item);
    if (isNew) {
      await _localDataSource.saveUnit(model);
    } else {
      await _localDataSource.updateUnit(
        model,
        previousNormalizedName: current?.normalizedName ?? unit.normalizedName,
      );
    }
    return item;
  }

  @override
  Future<int> countProductsForCategory(String normalizedName) =>
      _localDataSource.countProductsForCategory(normalizedName);

  @override
  Future<int> countProductsForSubcategory({
    required String categoryNormalizedName,
    required String subcategoryNormalizedName,
  }) => _localDataSource.countProductsForSubcategory(
    categoryNormalizedName: categoryNormalizedName,
    subcategoryNormalizedName: subcategoryNormalizedName,
  );

  @override
  Future<int> countProductsForUnit(String normalizedName) =>
      _localDataSource.countProductsForUnit(normalizedName);

  String _normalizeRequired(String value, String label) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      throw CatalogValidationException('$label es requerida.');
    }
    return CatalogTextNormalizer.normalize(trimmed);
  }

  String _newId(String prefix) {
    return '${prefix}_${DateTime.now().microsecondsSinceEpoch}';
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
