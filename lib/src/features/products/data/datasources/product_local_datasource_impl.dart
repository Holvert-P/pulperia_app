import 'dart:convert';

import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/catalog/domain/services/catalog_text_normalizer.dart';
import 'package:app/src/features/products/data/datasources/product_local_datasource.dart';
import 'package:app/src/features/products/data/mappers/product_catalog_json_mapper.dart';
import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/data/models/product_price_history_model.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  ProductLocalDataSourceImpl({
    AppDatabase? database,
    String assetPath = 'assets/data/products.json',
  }) : _database = database ?? AppDatabase.instance,
       _assetPath = assetPath;

  static const _catalogJsonMapper = ProductCatalogJsonMapper();

  final AppDatabase _database;
  final String _assetPath;

  @override
  Future<List<ProductModel>> getProducts() async {
    final db = await _database.database;
    final rows = await db.query('products', orderBy: 'name COLLATE NOCASE ASC');
    return rows.map(ProductModel.fromMap).toList();
  }

  @override
  Future<List<ProductModel>> searchProducts(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return getProducts();

    final db = await _database.database;
    final normalized = ProductTextNormalizer.normalizeName(trimmed);
    final likeQuery = '%$trimmed%';
    final likeNormalized = '%$normalized%';

    final rows = await db.query(
      'products',
      where: '''
        name LIKE ? COLLATE NOCASE OR
        normalized_name LIKE ? COLLATE NOCASE OR
        sku LIKE ? COLLATE NOCASE OR
        barcode LIKE ? COLLATE NOCASE
      ''',
      whereArgs: [likeQuery, likeNormalized, likeQuery, likeQuery],
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows.map(ProductModel.fromMap).toList();
  }

  @override
  Future<ProductModel?> getProductById(String id) async {
    final db = await _database.database;
    final rows = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return ProductModel.fromMap(rows.first);
  }

  @override
  Future<void> createProduct(ProductModel product) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert(
        'products',
        product.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _insertPriceHistory(
        txn,
        productId: product.id,
        costPrice: product.costPrice,
        salePrice: product.salePrice,
        vatRateApplied: product.vatRateApplied,
        taxType: product.taxType,
        recordedAt: product.updatedAt,
      );
    });
  }

  @override
  Future<void> updateProduct(ProductModel product) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final existingRows = await txn.query(
        'products',
        where: 'id = ?',
        whereArgs: [product.id],
        limit: 1,
      );
      if (existingRows.isEmpty) {
        await txn.insert(
          'products',
          product.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await _insertPriceHistory(
          txn,
          productId: product.id,
          costPrice: product.costPrice,
          salePrice: product.salePrice,
          vatRateApplied: product.vatRateApplied,
          taxType: product.taxType,
          recordedAt: product.updatedAt,
        );
        return;
      }

      final existing = ProductModel.fromMap(existingRows.first);
      await txn.update(
        'products',
        product.toMap(),
        where: 'id = ?',
        whereArgs: [product.id],
      );

      final historyChanged =
          existing.costPrice != product.costPrice ||
          existing.salePrice != product.salePrice ||
          existing.taxType != product.taxType ||
          existing.vatRateApplied != product.vatRateApplied;

      if (historyChanged) {
        await _insertPriceHistory(
          txn,
          productId: product.id,
          costPrice: product.costPrice,
          salePrice: product.salePrice,
          vatRateApplied: product.vatRateApplied,
          taxType: product.taxType,
          recordedAt: product.updatedAt,
        );
      }
    });
  }

  @override
  Future<void> deleteProduct(String id) async {
    final db = await _database.database;
    await db.delete('products', where: 'id = ?', whereArgs: [id]);
  }

  @override
  Future<List<ProductPriceHistoryModel>> getProductPriceHistory(
    String productId,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'product_price_history',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'recorded_at DESC',
    );
    return rows.map(ProductPriceHistoryModel.fromMap).toList();
  }

  @override
  Future<String> exportProductsToJson() async {
    final products = await getProducts();
    if (products.isEmpty) {
      throw const ProductCatalogException('No hay productos para exportar.');
    }

    final payload = _catalogJsonMapper.buildExportPayload(
      products,
      exportedAt: DateTime.now(),
    );
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  @override
  Future<ProductCatalogImportResult> importProductsFromJsonString(
    String jsonContent, {
    bool resetBeforeImport = false,
  }) async {
    final db = await _database.database;
    final parsed = _parseProductsFromJsonString(jsonContent);
    final errors = <String>[...parsed.errors];
    final uniqueProducts = _dedupeProducts(parsed.products, errors);

    var created = 0;
    var updated = 0;
    var categoriesCreated = 0;
    var subcategoriesCreated = 0;
    var unitsCreated = 0;

    if (uniqueProducts.isEmpty) {
      return ProductCatalogImportResult(
        totalRead: parsed.totalRead,
        created: 0,
        updated: 0,
        skipped: parsed.totalRead,
        resetBeforeImport: resetBeforeImport,
        categoriesCreated: 0,
        subcategoriesCreated: 0,
        unitsCreated: 0,
        errors: List.unmodifiable(errors),
      );
    }

    await db.transaction((txn) async {
      if (resetBeforeImport) {
        // Nota técnica: las proformas actuales guardan product_id sin FK hacia
        // products y conservan snapshot de nombre/precio. Este reset limpia
        // solo catálogo e historial para no tocar deudas, pagos o proformas.
        await txn.delete('product_price_history');
        await txn.delete('products');
      }

      for (final item in uniqueProducts) {
        try {
          final catalogSync = await _ensureCatalogOptionsForProduct(
            txn,
            item.product,
          );
          categoriesCreated += catalogSync.categoriesCreated;
          subcategoriesCreated += catalogSync.subcategoriesCreated;
          unitsCreated += catalogSync.unitsCreated;
          final existed = await _upsertProduct(txn, item.product);
          if (existed) {
            updated += 1;
          } else {
            created += 1;
          }
        } catch (error) {
          errors.add(
            'Producto #${item.position}: no se pudo guardar "${item.product.name}". $error',
          );
        }
      }
    });

    return ProductCatalogImportResult(
      totalRead: parsed.totalRead,
      created: created,
      updated: updated,
      skipped: parsed.totalRead - created - updated,
      resetBeforeImport: resetBeforeImport,
      categoriesCreated: categoriesCreated,
      subcategoriesCreated: subcategoriesCreated,
      unitsCreated: unitsCreated,
      errors: List.unmodifiable(errors),
    );
  }

  @override
  Future<ProductCatalogImportResult> resetAndImportProductsFromJson({
    String? assetPath,
  }) async {
    final raw = await rootBundle.loadString(assetPath ?? _assetPath);
    return importProductsFromJsonString(raw, resetBeforeImport: true);
  }

  @override
  Future<void> seedProductsCatalog({String? assetPath}) async {
    if (await hasProducts()) return;
    await resetAndImportProductsFromJson(assetPath: assetPath);
  }

  @override
  Future<bool> hasProducts() async {
    final db = await _database.database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS total FROM products');
    final total = (rows.first['total'] as num?)?.toInt() ?? 0;
    return total > 0;
  }

  _ParsedCatalogProducts _parseProductsFromJsonString(String raw) {
    late final Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } on FormatException {
      throw const ProductCatalogException(
        'El archivo seleccionado no es un JSON válido.',
      );
    }

    late final List<Object?> source;

    if (decoded is List) {
      source = decoded.cast<Object?>();
    } else if (decoded is Map) {
      if (!decoded.containsKey('products')) {
        throw const ProductCatalogException(
          'El JSON debe contener el campo "products".',
        );
      }

      final productsNode = decoded['products'];
      if (productsNode is! List) {
        throw const ProductCatalogException(
          'El campo "products" debe ser una lista.',
        );
      }

      source = productsNode.cast<Object?>();
    } else {
      throw const ProductCatalogException(
        'El JSON debe ser un objeto con "products" o una lista de productos.',
      );
    }

    if (source.isEmpty) {
      throw const ProductCatalogException(
        'El JSON no contiene productos para importar.',
      );
    }

    final importedAt = DateTime.now();
    final products = <ProductCatalogParsedItem>[];
    final errors = <String>[];

    for (var i = 0; i < source.length; i++) {
      final position = i + 1;
      final item = source[i];
      if (item is! Map) {
        errors.add('Producto #$position: debe ser un objeto JSON.');
        continue;
      }

      try {
        products.add(
          _catalogJsonMapper.parseProduct(
            item.cast<String, Object?>(),
            position: position,
            importedAt: importedAt,
          ),
        );
      } on ProductCatalogException catch (error) {
        errors.add(error.message);
      } catch (error) {
        errors.add(
          'Producto #$position: no tiene una estructura válida. $error',
        );
      }
    }

    return _ParsedCatalogProducts(
      totalRead: source.length,
      products: products,
      errors: errors,
    );
  }

  List<ProductCatalogParsedItem> _dedupeProducts(
    List<ProductCatalogParsedItem> products,
    List<String> errors,
  ) {
    final byId = <String, ProductCatalogParsedItem>{};
    final usedSkus = <String>{};
    final usedBarcodes = <String>{};

    for (final item in products) {
      final product = item.product;
      final id = product.id.trim().toLowerCase();
      final sku = product.sku.trim().toLowerCase();
      final barcode = (product.barcode ?? '').trim().toLowerCase();

      if (byId.containsKey(id)) {
        errors.add('Producto #${item.position}: id duplicado "${product.id}".');
        continue;
      }
      if (sku.isNotEmpty && usedSkus.contains(sku)) {
        errors.add(
          'Producto #${item.position}: sku duplicado "${product.sku}".',
        );
        continue;
      }
      if (barcode.isNotEmpty && usedBarcodes.contains(barcode)) {
        errors.add(
          'Producto #${item.position}: barcode duplicado "${product.barcode}".',
        );
        continue;
      }

      byId[id] = item;
      if (sku.isNotEmpty) usedSkus.add(sku);
      if (barcode.isNotEmpty) usedBarcodes.add(barcode);
    }

    return byId.values.toList();
  }

  Future<bool> _upsertProduct(Transaction txn, ProductModel product) async {
    final sku = product.sku.trim().toLowerCase();
    final barcode = (product.barcode ?? '').trim().toLowerCase();
    final existingRows = await txn.rawQuery(
      '''
      SELECT * FROM products
      WHERE id = ?
         OR (? != '' AND lower(sku) = ?)
         OR (? != '' AND lower(barcode) = ?)
      LIMIT 1
      ''',
      [product.id, sku, sku, barcode, barcode],
    );
    final existed = existingRows.isNotEmpty;
    final effectiveId = existed
        ? existingRows.first['id'] as String
        : product.id;
    final productMap = product.toMap()..['id'] = effectiveId;

    if (!existed) {
      await txn.insert(
        'products',
        productMap,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _insertPriceHistory(
        txn,
        productId: effectiveId,
        costPrice: product.costPrice,
        salePrice: product.salePrice,
        vatRateApplied: product.vatRateApplied,
        taxType: product.taxType,
        recordedAt: product.createdAt,
      );
      return false;
    }

    final existing = ProductModel.fromMap(existingRows.first);
    productMap['created_at'] = existing.createdAt.toIso8601String();
    await txn.update(
      'products',
      productMap,
      where: 'id = ?',
      whereArgs: [effectiveId],
    );

    final historyChanged =
        existing.costPrice != product.costPrice ||
        existing.salePrice != product.salePrice ||
        existing.taxType != product.taxType ||
        existing.vatRateApplied != product.vatRateApplied;

    if (historyChanged) {
      await _insertPriceHistory(
        txn,
        productId: effectiveId,
        costPrice: product.costPrice,
        salePrice: product.salePrice,
        vatRateApplied: product.vatRateApplied,
        taxType: product.taxType,
        recordedAt: product.updatedAt,
      );
    }

    return true;
  }

  Future<_CatalogSyncCounts> _ensureCatalogOptionsForProduct(
    Transaction txn,
    ProductModel product,
  ) async {
    final now = DateTime.now().toIso8601String();
    var categoriesCreated = 0;
    var subcategoriesCreated = 0;
    var unitsCreated = 0;

    final categoryNormalized = CatalogTextNormalizer.normalize(
      product.category,
    );
    final categoryRows = await txn.query(
      'categories',
      where: 'normalized_name = ?',
      whereArgs: [categoryNormalized],
      limit: 1,
    );

    String categoryId;
    if (categoryRows.isEmpty) {
      categoryId = 'cat_$categoryNormalized';
      await txn.insert('categories', {
        'id': categoryId,
        'name': CatalogTextNormalizer.displayName(categoryNormalized),
        'normalized_name': categoryNormalized,
        'description': null,
        'icon_name': null,
        'color_hex': null,
        'sort_order': 999,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      categoriesCreated += 1;
    } else {
      categoryId = categoryRows.first['id'] as String;
    }

    final subcategoryNormalized = product.subcategory == null
        ? null
        : CatalogTextNormalizer.normalize(product.subcategory!);
    if (subcategoryNormalized != null && subcategoryNormalized.isNotEmpty) {
      final subcategoryRows = await txn.query(
        'subcategories',
        where: 'category_id = ? AND normalized_name = ?',
        whereArgs: [categoryId, subcategoryNormalized],
        limit: 1,
      );
      if (subcategoryRows.isEmpty) {
        await txn.insert('subcategories', {
          'id': 'sub_${categoryId}_$subcategoryNormalized',
          'category_id': categoryId,
          'name': CatalogTextNormalizer.displayName(subcategoryNormalized),
          'normalized_name': subcategoryNormalized,
          'description': null,
          'sort_order': 999,
          'is_active': 1,
          'created_at': now,
          'updated_at': now,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        subcategoriesCreated += 1;
      }
    }

    final unitNormalized = CatalogTextNormalizer.normalize(
      product.unitOfMeasure,
    );
    final unitRows = await txn.query(
      'units_of_measure',
      where: 'normalized_name = ?',
      whereArgs: [unitNormalized],
      limit: 1,
    );
    if (unitRows.isEmpty) {
      await txn.insert('units_of_measure', {
        'id': 'unit_$unitNormalized',
        'name': CatalogTextNormalizer.displayName(unitNormalized),
        'normalized_name': unitNormalized,
        'symbol': null,
        'allows_decimal': product.allowDecimalQuantity ? 1 : 0,
        'description': null,
        'sort_order': 999,
        'is_active': 1,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
      unitsCreated += 1;
    }

    return _CatalogSyncCounts(
      categoriesCreated: categoriesCreated,
      subcategoriesCreated: subcategoriesCreated,
      unitsCreated: unitsCreated,
    );
  }

  Future<void> _insertPriceHistory(
    Transaction txn, {
    required String productId,
    required double costPrice,
    required double salePrice,
    required double vatRateApplied,
    required String taxType,
    required DateTime recordedAt,
  }) async {
    await txn.insert('product_price_history', {
      'product_id': productId,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'vat_rate_applied': vatRateApplied,
      'tax_type': taxType,
      'recorded_at': recordedAt.toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.abort);
  }
}

class _ParsedCatalogProducts {
  const _ParsedCatalogProducts({
    required this.totalRead,
    required this.products,
    required this.errors,
  });

  final int totalRead;
  final List<ProductCatalogParsedItem> products;
  final List<String> errors;
}

class _CatalogSyncCounts {
  const _CatalogSyncCounts({
    required this.categoriesCreated,
    required this.subcategoriesCreated,
    required this.unitsCreated,
  });

  final int categoriesCreated;
  final int subcategoriesCreated;
  final int unitsCreated;
}
