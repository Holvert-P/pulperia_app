import 'package:app/src/features/products/domain/entities/price_history_entry.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/features/products/domain/repositories/product_repository.dart';
import 'package:app/src/features/products/domain/services/product_financials.dart';

class GetProducts {
  const GetProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call() => _repository.getProducts();
}

class GetAllProducts extends GetProducts {
  const GetAllProducts(super.repository);
}

class SearchProducts {
  const SearchProducts(this._repository);

  final ProductRepository _repository;

  Future<List<Product>> call(String query) => _repository.searchProducts(query);
}

class GetProductById {
  const GetProductById(this._repository);

  final ProductRepository _repository;

  Future<Product?> call(String id) => _repository.getProductById(id);
}

class CreateProduct {
  const CreateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(Product product) => _repository.createProduct(product);
}

class UpdateProduct {
  const UpdateProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(Product product) => _repository.updateProduct(product);
}

class DeleteProduct {
  const DeleteProduct(this._repository);

  final ProductRepository _repository;

  Future<void> call(String id) => _repository.deleteProduct(id);
}

class GetProductPriceHistory {
  const GetProductPriceHistory(this._repository);

  final ProductRepository _repository;

  Future<List<PriceHistoryEntry>> call(String productId) =>
      _repository.getProductPriceHistory(productId);
}

class GetPriceHistory extends GetProductPriceHistory {
  const GetPriceHistory(super.repository);
}

class ExportProductsToJson {
  const ExportProductsToJson(this._repository);

  final ProductRepository _repository;

  Future<String> call() => _repository.exportProductsToJson();
}

class ImportProductsFromJson {
  const ImportProductsFromJson(this._repository);

  final ProductRepository _repository;

  Future<ProductCatalogImportResult> call(String jsonContent) =>
      _repository.importProductsFromJson(jsonContent);
}

class ResetProductsCatalogFromJson {
  const ResetProductsCatalogFromJson(this._repository);

  final ProductRepository _repository;

  Future<ProductCatalogImportResult> call() =>
      _repository.resetAndImportProductsFromJson();
}

class ResetAndImportProductsFromJson extends ResetProductsCatalogFromJson {
  const ResetAndImportProductsFromJson(super.repository);
}

class SeedProductsCatalog {
  const SeedProductsCatalog(this._repository);

  final ProductRepository _repository;

  Future<void> call() => _repository.seedProductsCatalog();
}

class RecalculateProductFinancials {
  const RecalculateProductFinancials();

  ProductFinancialSnapshot call({
    required double costPrice,
    required double salePrice,
    required String taxType,
    required double vatRateApplied,
  }) {
    return ProductFinancials.normalize(
      costPrice: costPrice,
      salePrice: salePrice,
      taxType: taxType,
      vatRateApplied: vatRateApplied,
    );
  }
}

class CreateInitialPriceHistory {
  const CreateInitialPriceHistory();

  PriceHistoryEntry call({
    required String productId,
    required double costPrice,
    required double salePrice,
    required String taxType,
    required double vatRateApplied,
    required DateTime recordedAt,
  }) {
    return PriceHistoryEntry(
      id: null,
      productId: productId,
      costPrice: costPrice,
      salePrice: salePrice,
      vatRateApplied: vatRateApplied,
      taxType: taxType,
      recordedAt: recordedAt,
    );
  }
}
