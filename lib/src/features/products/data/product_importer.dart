import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';

class ProductImporter {
  ProductImporter({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> seedProductsCatalogIfNeeded() async {
    final repo = ProductRepositoryImpl(database: _database);
    await SeedProductsCatalog(repo)();
  }
}
