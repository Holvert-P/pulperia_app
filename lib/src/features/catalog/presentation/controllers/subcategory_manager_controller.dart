import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/foundation.dart';

class SubcategoryManagerController extends ChangeNotifier {
  SubcategoryManagerController({
    GetCatalogCategories? getCategories,
    GetCatalogSubcategories? getSubcategories,
    SaveCatalogSubcategory? saveSubcategory,
  }) : _getCategories =
           getCategories ?? GetCatalogCategories(CatalogRepositoryImpl()),
       _getSubcategories =
           getSubcategories ?? GetCatalogSubcategories(CatalogRepositoryImpl()),
       _saveSubcategory =
           saveSubcategory ?? SaveCatalogSubcategory(CatalogRepositoryImpl());

  final GetCatalogCategories _getCategories;
  final GetCatalogSubcategories _getSubcategories;
  final SaveCatalogSubcategory _saveSubcategory;

  bool _loading = false;
  String _query = '';
  String? _categoryId;
  List<CatalogCategory> _categories = const [];
  List<CatalogSubcategory> _items = const [];

  bool get loading => _loading;
  String get query => _query;
  String? get categoryId => _categoryId;
  List<CatalogCategory> get categories => _categories;
  List<CatalogSubcategory> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _categories = await _getCategories(includeInactive: true);
      _items = await _getSubcategories(
        includeInactive: true,
        categoryId: _categoryId,
        query: _query,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    _query = value;
    await load();
  }

  Future<void> filterByCategory(String? categoryId) async {
    _categoryId = categoryId;
    await load();
  }

  Future<void> save(CatalogSubcategory subcategory) async {
    await _saveSubcategory(subcategory);
    await load();
  }

  Future<void> toggle(CatalogSubcategory subcategory) {
    return save(subcategory.copyWith(isActive: !subcategory.isActive));
  }
}
