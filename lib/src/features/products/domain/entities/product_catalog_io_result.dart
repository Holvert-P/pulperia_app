class ProductCatalogExportResult {
  const ProductCatalogExportResult({
    required this.filePath,
    required this.storageMessage,
    required this.productsCount,
    required this.exportedAt,
  });

  final String filePath;
  final String storageMessage;
  final int productsCount;
  final DateTime exportedAt;
}

class ProductCatalogImportResult {
  const ProductCatalogImportResult({
    required this.totalRead,
    required this.created,
    required this.updated,
    required this.skipped,
    required this.resetBeforeImport,
    this.categoriesCreated = 0,
    this.subcategoriesCreated = 0,
    this.unitsCreated = 0,
    this.errors = const [],
  });

  final int totalRead;
  final int created;
  final int updated;
  final int skipped;
  final bool resetBeforeImport;
  final int categoriesCreated;
  final int subcategoriesCreated;
  final int unitsCreated;
  final List<String> errors;

  int get applied => created + updated;

  bool get hasChanges =>
      applied > 0 ||
      categoriesCreated > 0 ||
      subcategoriesCreated > 0 ||
      unitsCreated > 0 ||
      resetBeforeImport;

  bool get hasErrors => errors.isNotEmpty;
}

class ProductCatalogException implements Exception {
  const ProductCatalogException(this.message);

  final String message;

  @override
  String toString() => message;
}
