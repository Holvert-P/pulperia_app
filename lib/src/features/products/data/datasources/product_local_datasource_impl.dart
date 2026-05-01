import 'dart:convert';

import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/products/data/datasources/product_local_datasource.dart';
import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/data/models/product_price_history_model.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';

class ProductLocalDataSourceImpl implements ProductLocalDataSource {
  ProductLocalDataSourceImpl({
    AppDatabase? database,
    String assetPath = 'assets/data/products.json',
  }) : _database = database ?? AppDatabase.instance,
       _assetPath = assetPath;

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
  Future<void> resetAndImportProductsFromJson({String? assetPath}) async {
    final db = await _database.database;
    final products = await _readProductsFromAsset(assetPath ?? _assetPath);

    await db.transaction((txn) async {
      await txn.delete('product_price_history');
      await txn.delete('products');

      for (final product in _dedupeProducts(products)) {
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
          recordedAt: product.createdAt,
        );
      }
    });
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

  Future<List<ProductModel>> _readProductsFromAsset(String assetPath) async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw);
    late final List<Object?> source;
    if (decoded is List) {
      source = decoded.cast<Object?>();
    } else if (decoded is Map<String, dynamic>) {
      source = (decoded['products'] as List?)?.cast<Object?>() ?? const [];
    } else {
      source = const [];
    }

    return source
        .whereType<Map>()
        .map((e) => ProductModel.fromJson(e.cast<String, Object?>()))
        .where((model) => model.id.isNotEmpty && model.name.isNotEmpty)
        .toList();
  }

  List<ProductModel> _dedupeProducts(List<ProductModel> products) {
    final byId = <String, ProductModel>{};
    final usedSkus = <String>{};
    final usedBarcodes = <String>{};

    for (final product in products) {
      final sku = product.sku.trim().toLowerCase();
      final barcode = (product.barcode ?? '').trim().toLowerCase();
      if (byId.containsKey(product.id)) continue;
      if (sku.isNotEmpty && usedSkus.contains(sku)) continue;
      if (barcode.isNotEmpty && usedBarcodes.contains(barcode)) continue;

      byId[product.id] = product;
      if (sku.isNotEmpty) usedSkus.add(sku);
      if (barcode.isNotEmpty) usedBarcodes.add(barcode);
    }

    return byId.values.toList();
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
