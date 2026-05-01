import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:app/src/features/products/domain/entities/price_history_entry.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:flutter/foundation.dart';

class ProductDetailController extends ChangeNotifier {
  ProductDetailController({
    required String productId,
    required GetProductById getProductById,
    required GetProductPriceHistory getPriceHistory,
    required DeleteProduct deleteProduct,
    required GetCatalogCategories getCategories,
    required GetCatalogSubcategories getSubcategories,
    required GetUnitsOfMeasure getUnits,
  }) : _productId = productId,
       _getProductById = getProductById,
       _getPriceHistory = getPriceHistory,
       _deleteProduct = deleteProduct,
       _getCategories = getCategories,
       _getSubcategories = getSubcategories,
       _getUnits = getUnits;

  final String _productId;
  final GetProductById _getProductById;
  final GetProductPriceHistory _getPriceHistory;
  final DeleteProduct _deleteProduct;
  final GetCatalogCategories _getCategories;
  final GetCatalogSubcategories _getSubcategories;
  final GetUnitsOfMeasure _getUnits;

  bool _loading = true;
  bool get loading => _loading;

  Product? _product;
  Product? get product => _product;

  String? _categoryLabel;
  String? get categoryLabel => _categoryLabel;

  String? _subcategoryLabel;
  String? get subcategoryLabel => _subcategoryLabel;

  String? _unitLabel;
  String? get unitLabel => _unitLabel;

  List<PriceHistoryEntry> _history = const [];
  List<PriceHistoryEntry> get history => _history;

  Future<void> load() async {
    _setLoading(true);

    final product = await _getProductById(_productId);
    final history = await _getPriceHistory(_productId);

    _product = product;
    _history = history;

    if (product == null) {
      _categoryLabel = null;
      _subcategoryLabel = null;
      _unitLabel = null;
      _setLoading(false);
      return;
    }

    await _loadCatalogLabels(product);
    _setLoading(false);
  }

  Future<void> _loadCatalogLabels(Product product) async {
    final categories = await _getCategories(includeInactive: true);
    final subcategories = await _getSubcategories(includeInactive: true);
    final units = await _getUnits(includeInactive: true);

    final category = _findCategory(categories, product.category);
    final subcategory = _findSubcategory(
      subcategories,
      category: category,
      normalizedName: product.subcategory,
    );
    final unit = _findUnit(units, product.unitOfMeasure);

    _categoryLabel = category?.name ?? _humanize(product.category);
    _subcategoryLabel = product.subcategory == null || product.subcategory!.isEmpty
        ? null
        : subcategory?.name ?? _humanize(product.subcategory!);
    _unitLabel = unit?.name ?? _humanize(product.unitOfMeasure);
  }

  CatalogCategory? _findCategory(
    List<CatalogCategory> categories,
    String normalizedName,
  ) {
    for (final category in categories) {
      if (category.normalizedName == normalizedName) return category;
    }
    return null;
  }

  CatalogSubcategory? _findSubcategory(
    List<CatalogSubcategory> subcategories, {
    required CatalogCategory? category,
    required String? normalizedName,
  }) {
    if (normalizedName == null || normalizedName.isEmpty) return null;

    for (final subcategory in subcategories) {
      final sameName = subcategory.normalizedName == normalizedName;
      final sameCategory = category == null || subcategory.categoryId == category.id;
      if (sameName && sameCategory) return subcategory;
    }
    return null;
  }

  UnitOfMeasure? _findUnit(
    List<UnitOfMeasure> units,
    String normalizedName,
  ) {
    for (final unit in units) {
      if (unit.normalizedName == normalizedName) return unit;
    }
    return null;
  }

  String _humanize(String value) {
    final words = value
        .replaceAll('_', ' ')
        .replaceAll('-', ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    return words
        .map((word) {
          if (word.length <= 2) return word.toUpperCase();
          return '${word[0].toUpperCase()}${word.substring(1)}';
        })
        .join(' ');
  }

  Future<void> delete() async {
    await _deleteProduct(_productId);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}
