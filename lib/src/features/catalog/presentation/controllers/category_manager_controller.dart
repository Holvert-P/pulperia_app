import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/foundation.dart';

class CategoryManagerController extends ChangeNotifier {
  CategoryManagerController({
    GetCatalogCategories? getCategories,
    SaveCatalogCategory? saveCategory,
  }) : _getCategories =
           getCategories ?? GetCatalogCategories(CatalogRepositoryImpl()),
       _saveCategory =
           saveCategory ?? SaveCatalogCategory(CatalogRepositoryImpl());

  final GetCatalogCategories _getCategories;
  final SaveCatalogCategory _saveCategory;

  bool _loading = false;
  String _query = '';
  List<CatalogCategory> _items = const [];

  bool get loading => _loading;
  String get query => _query;
  List<CatalogCategory> get items => _items;

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    try {
      _items = await _getCategories(includeInactive: true, query: _query);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> search(String value) async {
    _query = value;
    await load();
  }

  Future<void> save(CatalogCategory category) async {
    await _saveCategory(category);
    await load();
  }

  Future<void> toggle(CatalogCategory category) {
    return save(category.copyWith(isActive: !category.isActive));
  }
}
