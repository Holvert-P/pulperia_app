import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/data/models/product_price_history_model.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';

abstract class ProductLocalDataSource {
  Future<List<ProductModel>> getProducts();
  Future<List<ProductModel>> searchProducts(String query);
  Future<ProductModel?> getProductById(String id);
  Future<void> createProduct(ProductModel product);
  Future<void> updateProduct(ProductModel product);
  Future<void> deleteProduct(String id);
  Future<List<ProductPriceHistoryModel>> getProductPriceHistory(
    String productId,
  );
  Future<String> exportProductsToJson();
  Future<ProductCatalogImportResult> importProductsFromJsonString(
    String jsonContent, {
    bool resetBeforeImport = false,
  });
  Future<ProductCatalogImportResult> resetAndImportProductsFromJson({
    String? assetPath,
  });
  Future<void> seedProductsCatalog({String? assetPath});
  Future<bool> hasProducts();
}
