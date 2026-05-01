import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/products/data/datasources/product_local_datasource.dart';
import 'package:app/src/features/products/data/datasources/product_local_datasource_impl.dart';
import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/features/products/domain/repositories/product_repository.dart';
import 'package:app/src/features/products/domain/entities/price_history_entry.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    AppDatabase? database,
    ProductLocalDataSource? localDataSource,
  }) : _localDataSource =
           localDataSource ??
           ProductLocalDataSourceImpl(
             database: database ?? AppDatabase.instance,
           );

  final ProductLocalDataSource _localDataSource;

  @override
  Future<List<Product>> getProducts() async =>
      (await _localDataSource.getProducts()).map((m) => m.toEntity()).toList();

  @override
  Future<List<Product>> searchProducts(String query) async =>
      (await _localDataSource.searchProducts(
        query,
      )).map((m) => m.toEntity()).toList();

  @override
  Future<Product?> getProductById(String id) async =>
      (await _localDataSource.getProductById(id))?.toEntity();

  @override
  Future<void> createProduct(Product product) =>
      _localDataSource.createProduct(ProductModel.fromEntity(product));

  @override
  Future<void> updateProduct(Product product) =>
      _localDataSource.updateProduct(ProductModel.fromEntity(product));

  @override
  Future<void> deleteProduct(String id) => _localDataSource.deleteProduct(id);

  @override
  Future<List<PriceHistoryEntry>> getProductPriceHistory(
    String productId,
  ) async => (await _localDataSource.getProductPriceHistory(
    productId,
  )).map((m) => m.toEntity()).toList();

  @override
  Future<String> exportProductsToJson() =>
      _localDataSource.exportProductsToJson();

  @override
  Future<ProductCatalogImportResult> importProductsFromJson(
    String jsonContent,
  ) => _localDataSource.importProductsFromJsonString(jsonContent);

  @override
  Future<ProductCatalogImportResult> resetAndImportProductsFromJson() =>
      _localDataSource.resetAndImportProductsFromJson();

  @override
  Future<void> seedProductsCatalog() => _localDataSource.seedProductsCatalog();
}
