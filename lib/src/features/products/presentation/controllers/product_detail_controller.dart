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
  }) : _productId = productId,
       _getProductById = getProductById,
       _getPriceHistory = getPriceHistory,
       _deleteProduct = deleteProduct;

  final String _productId;
  final GetProductById _getProductById;
  final GetProductPriceHistory _getPriceHistory;
  final DeleteProduct _deleteProduct;

  bool _loading = true;
  bool get loading => _loading;

  Product? _product;
  Product? get product => _product;

  List<PriceHistoryEntry> _history = const [];
  List<PriceHistoryEntry> get history => _history;

  Future<void> load() async {
    _setLoading(true);
    final product = await _getProductById(_productId);
    final history = await _getPriceHistory(_productId);
    _product = product;
    _history = history;
    _setLoading(false);
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
