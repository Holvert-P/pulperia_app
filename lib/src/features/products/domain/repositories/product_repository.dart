import 'package:app/src/features/products/domain/entities/price_history_entry.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<List<Product>> searchProducts(String query);

  Future<Product?> getProductById(String id);
  Future<void> createProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);

  Future<List<PriceHistoryEntry>> getProductPriceHistory(String productId);
  Future<String> exportProductsToJson();
  Future<ProductCatalogImportResult> importProductsFromJson(String jsonContent);
  Future<ProductCatalogImportResult> resetAndImportProductsFromJson();
  Future<void> seedProductsCatalog();
}
