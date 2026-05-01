import 'dart:convert';

import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/data/services/product_catalog_file_service.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:flutter/foundation.dart';

class CatalogSettingsController extends ChangeNotifier {
  CatalogSettingsController({
    ExportProductsToJson? exportProductsToJson,
    ImportProductsFromJson? importProductsFromJson,
    ResetProductsCatalogFromJson? resetProductsCatalogFromJson,
    ProductCatalogFileService? fileService,
  }) : _exportProductsToJson =
           exportProductsToJson ??
           ExportProductsToJson(ProductRepositoryImpl()),
       _importProductsFromJson =
           importProductsFromJson ??
           ImportProductsFromJson(ProductRepositoryImpl()),
       _resetProductsCatalogFromJson =
           resetProductsCatalogFromJson ??
           ResetProductsCatalogFromJson(ProductRepositoryImpl()),
       _fileService = fileService ?? const ProductCatalogFileService();

  final ExportProductsToJson _exportProductsToJson;
  final ImportProductsFromJson _importProductsFromJson;
  final ResetProductsCatalogFromJson _resetProductsCatalogFromJson;
  final ProductCatalogFileService _fileService;

  bool _working = false;

  bool get working => _working;

  Future<ProductCatalogExportResult> exportProducts() async {
    return _run(() async {
      final json = await _exportProductsToJson();
      final savedFile = await _fileService.saveExportedJson(json);
      final count = _extractProductsCount(json);
      return ProductCatalogExportResult(
        filePath: savedFile.file.path,
        storageMessage: savedFile.storageMessage,
        productsCount: count,
        exportedAt: _extractExportedAt(json) ?? DateTime.now(),
      );
    });
  }

  Future<ProductCatalogImportResult?> importProducts() async {
    return _run(() async {
      try {
        final json = await _fileService.pickJsonContent();
        return _importProductsFromJson(json);
      } on ProductCatalogFileCancelledException {
        return null;
      }
    });
  }

  Future<ProductCatalogImportResult> resetCatalog() async {
    return _run(_resetProductsCatalogFromJson.call);
  }

  Future<T> _run<T>(Future<T> Function() task) async {
    if (_working) {
      throw const CatalogSettingsBusyException();
    }

    _working = true;
    notifyListeners();

    try {
      return await task();
    } finally {
      _working = false;
      notifyListeners();
    }
  }

  int _extractProductsCount(String json) {
    final decoded = jsonDecode(json);
    if (decoded is Map<String, dynamic>) {
      final meta = decoded['meta'];
      if (meta is Map<String, dynamic>) {
        final total = meta['total_products'];
        if (total is num) return total.toInt();
      }
      return (decoded['products'] as List?)?.length ?? 0;
    }
    if (decoded is List) return decoded.length;
    return 0;
  }

  DateTime? _extractExportedAt(String json) {
    final decoded = jsonDecode(json);
    if (decoded is! Map<String, dynamic>) return null;
    final meta = decoded['meta'];
    if (meta is! Map<String, dynamic>) return null;
    final value = meta['exported_at'];
    if (value is! String) return null;
    return DateTime.tryParse(value);
  }
}

class CatalogSettingsBusyException implements Exception {
  const CatalogSettingsBusyException();
}
