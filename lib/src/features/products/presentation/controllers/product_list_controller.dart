import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:flutter/foundation.dart';

class ProductListController extends ChangeNotifier {
  ProductListController({
    required GetAllProducts getAllProducts,
    required SearchProducts searchProducts,
    required DeleteProduct deleteProduct,
  }) : _getAllProducts = getAllProducts,
       _searchProducts = searchProducts,
       _deleteProduct = deleteProduct;

  final GetAllProducts _getAllProducts;
  final SearchProducts _searchProducts;
  final DeleteProduct _deleteProduct;

  bool _loading = true;
  bool get loading => _loading;

  List<Product> _products = const [];
  List<Product> get products => _products;

  String _query = '';
  String get query => _query;

  Future<void> loadAll() async {
    _query = '';
    _setLoading(true);
    final items = await _getAllProducts();
    _products = items;
    _setLoading(false);
  }

  Future<void> loadSearch(String query) async {
    _query = query;
    _setLoading(true);
    final items = await _searchProducts(query);
    _products = items;
    _setLoading(false);
  }

  Future<void> refresh() async {
    final q = _query.trim();
    if (q.isEmpty) {
      await loadAll();
    } else {
      await loadSearch(q);
    }
  }

  Future<void> deleteById(String id) async {
    await _deleteProduct(id);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}
