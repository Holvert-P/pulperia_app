import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/data/models/product_price_history_model.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> getProductById(String id);
  Future<void> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<List<ProductPriceHistoryModel>> getProductPriceHistory(String productId);
  Future<void> resetAndImportProductsFromJson({String? assetPath});
  Future<void> seedProductsCatalog({String? assetPath});
  Future<bool> hasProducts();
}
