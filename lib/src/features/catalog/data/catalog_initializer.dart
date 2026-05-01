import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';

class CatalogInitializer {
  CatalogInitializer({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> ensureCatalogReady() async {
    final repository = CatalogRepositoryImpl(database: _database);
    await EnsureCatalogReady(repository)();
  }
}
