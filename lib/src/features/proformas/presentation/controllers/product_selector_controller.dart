import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:flutter/foundation.dart';

class ProductSelectorController extends ChangeNotifier {
  ProductSelectorController({
    required GetProducts getProducts,
    required SearchProducts searchProducts,
  })  : _getProducts = getProducts,
        _searchProducts = searchProducts;

  final GetProducts _getProducts;
  final SearchProducts _searchProducts;

  bool _loading = true;
  bool get loading => _loading;

  List<Product> _products = const [];
  List<Product> get products => _products;

  String _query = '';
  String get query => _query;

  Future<void> loadAll() async {
    _query = '';
    _setLoading(true);
    _products = await _getProducts();
    _setLoading(false);
  }

  Future<void> search(String query) async {
    _query = query;
    _setLoading(true);
    _products = await _searchProducts(query);
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }
}

