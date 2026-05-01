import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/catalog/data/datasources/catalog_local_datasource.dart';
import 'package:app/src/features/catalog/data/models/category_model.dart';
import 'package:app/src/features/catalog/data/models/subcategory_model.dart';
import 'package:app/src/features/catalog/data/models/unit_of_measure_model.dart';
import 'package:app/src/features/catalog/data/seed/catalog_seed_data.dart';
import 'package:app/src/features/catalog/domain/services/catalog_text_normalizer.dart';
import 'package:sqflite/sqflite.dart';

class CatalogLocalDataSourceImpl implements CatalogLocalDataSource {
  CatalogLocalDataSourceImpl({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<void> ensureCatalogReady() async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await _seedBaseCatalog(txn);
      await _syncCatalogFromProducts(txn);
    });
  }

  @override
  Future<List<CategoryModel>> getCategories({
    bool includeInactive = false,
    String? query,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (!includeInactive) {
      where.add('c.is_active = 1');
    }
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      where.add('(c.name LIKE ? COLLATE NOCASE OR c.normalized_name LIKE ?)');
      args.addAll([
        '%$trimmed%',
        '%${CatalogTextNormalizer.normalize(trimmed)}%',
      ]);
    }

    final rows = await db.rawQuery('''
      SELECT c.*,
        (SELECT COUNT(*) FROM subcategories s WHERE s.category_id = c.id) AS subcategory_count,
        (SELECT COUNT(*) FROM products p WHERE p.category = c.normalized_name) AS product_count
      FROM categories c
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY c.sort_order ASC, c.name COLLATE NOCASE ASC
      ''', args);
    return rows.map(CategoryModel.fromMap).toList();
  }

  @override
  Future<CategoryModel?> getCategoryById(String id) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT c.*,
        (SELECT COUNT(*) FROM subcategories s WHERE s.category_id = c.id) AS subcategory_count,
        (SELECT COUNT(*) FROM products p WHERE p.category = c.normalized_name) AS product_count
      FROM categories c
      WHERE c.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }

  @override
  Future<CategoryModel?> getCategoryByNormalizedName(
    String normalizedName,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'categories',
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }

  @override
  Future<void> saveCategory(CategoryModel category) async {
    final db = await _database.database;
    await db.insert(
      'categories',
      category.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateCategory(
    CategoryModel category, {
    required String previousNormalizedName,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'categories',
        category.toMap(),
        where: 'id = ?',
        whereArgs: [category.id],
      );
      if (previousNormalizedName != category.normalizedName) {
        await txn.update(
          'products',
          {'category': category.normalizedName},
          where: 'category = ?',
          whereArgs: [previousNormalizedName],
        );
      }
    });
  }

  @override
  Future<List<SubcategoryModel>> getSubcategories({
    bool includeInactive = false,
    String? categoryId,
    String? query,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (!includeInactive) {
      where.add('s.is_active = 1');
    }
    if (categoryId != null && categoryId.isNotEmpty) {
      where.add('s.category_id = ?');
      args.add(categoryId);
    }
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      where.add('(s.name LIKE ? COLLATE NOCASE OR s.normalized_name LIKE ?)');
      args.addAll([
        '%$trimmed%',
        '%${CatalogTextNormalizer.normalize(trimmed)}%',
      ]);
    }

    final rows = await db.rawQuery('''
      SELECT s.*, c.name AS category_name, c.normalized_name AS category_normalized_name,
        (SELECT COUNT(*) FROM products p
         WHERE p.category = c.normalized_name AND p.subcategory = s.normalized_name) AS product_count
      FROM subcategories s
      INNER JOIN categories c ON c.id = s.category_id
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY c.sort_order ASC, c.name COLLATE NOCASE ASC,
        s.sort_order ASC, s.name COLLATE NOCASE ASC
      ''', args);
    return rows.map(SubcategoryModel.fromMap).toList();
  }

  @override
  Future<SubcategoryModel?> getSubcategoryById(String id) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT s.*, c.name AS category_name, c.normalized_name AS category_normalized_name,
        (SELECT COUNT(*) FROM products p
         WHERE p.category = c.normalized_name AND p.subcategory = s.normalized_name) AS product_count
      FROM subcategories s
      INNER JOIN categories c ON c.id = s.category_id
      WHERE s.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return SubcategoryModel.fromMap(rows.first);
  }

  @override
  Future<SubcategoryModel?> getSubcategoryByNormalizedName({
    required String categoryId,
    required String normalizedName,
  }) async {
    final db = await _database.database;
    final rows = await db.query(
      'subcategories',
      where: 'category_id = ? AND normalized_name = ?',
      whereArgs: [categoryId, normalizedName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return SubcategoryModel.fromMap(rows.first);
  }

  @override
  Future<void> saveSubcategory(SubcategoryModel subcategory) async {
    final db = await _database.database;
    await db.insert(
      'subcategories',
      subcategory.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateSubcategory(
    SubcategoryModel subcategory, {
    required String previousCategoryId,
    required String previousNormalizedName,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final previousCategory = await _categoryById(txn, previousCategoryId);
      final newCategory = await _categoryById(txn, subcategory.categoryId);
      await txn.update(
        'subcategories',
        subcategory.toMap(),
        where: 'id = ?',
        whereArgs: [subcategory.id],
      );
      if (previousCategory == null || newCategory == null) return;
      if (previousCategory.normalizedName != newCategory.normalizedName ||
          previousNormalizedName != subcategory.normalizedName) {
        await txn.update(
          'products',
          {
            'category': newCategory.normalizedName,
            'subcategory': subcategory.normalizedName,
          },
          where: 'category = ? AND subcategory = ?',
          whereArgs: [previousCategory.normalizedName, previousNormalizedName],
        );
      }
    });
  }

  @override
  Future<List<UnitOfMeasureModel>> getUnits({
    bool includeInactive = false,
    String? query,
  }) async {
    final db = await _database.database;
    final where = <String>[];
    final args = <Object?>[];

    if (!includeInactive) {
      where.add('u.is_active = 1');
    }
    final trimmed = query?.trim();
    if (trimmed != null && trimmed.isNotEmpty) {
      where.add('(u.name LIKE ? COLLATE NOCASE OR u.normalized_name LIKE ?)');
      args.addAll([
        '%$trimmed%',
        '%${CatalogTextNormalizer.normalize(trimmed)}%',
      ]);
    }

    final rows = await db.rawQuery('''
      SELECT u.*,
        (SELECT COUNT(*) FROM products p WHERE p.unit_of_measure = u.normalized_name) AS product_count
      FROM units_of_measure u
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      ORDER BY u.sort_order ASC, u.name COLLATE NOCASE ASC
      ''', args);
    return rows.map(UnitOfMeasureModel.fromMap).toList();
  }

  @override
  Future<UnitOfMeasureModel?> getUnitById(String id) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT u.*,
        (SELECT COUNT(*) FROM products p WHERE p.unit_of_measure = u.normalized_name) AS product_count
      FROM units_of_measure u
      WHERE u.id = ?
      LIMIT 1
      ''',
      [id],
    );
    if (rows.isEmpty) return null;
    return UnitOfMeasureModel.fromMap(rows.first);
  }

  @override
  Future<UnitOfMeasureModel?> getUnitByNormalizedName(
    String normalizedName,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'units_of_measure',
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return UnitOfMeasureModel.fromMap(rows.first);
  }

  @override
  Future<void> saveUnit(UnitOfMeasureModel unit) async {
    final db = await _database.database;
    await db.insert(
      'units_of_measure',
      unit.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateUnit(
    UnitOfMeasureModel unit, {
    required String previousNormalizedName,
  }) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'units_of_measure',
        unit.toMap(),
        where: 'id = ?',
        whereArgs: [unit.id],
      );
      if (previousNormalizedName != unit.normalizedName) {
        await txn.update(
          'products',
          {'unit_of_measure': unit.normalizedName},
          where: 'unit_of_measure = ?',
          whereArgs: [previousNormalizedName],
        );
      }
    });
  }

  @override
  Future<int> countProductsForCategory(String normalizedName) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM products WHERE category = ?',
      [normalizedName],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> countProductsForSubcategory({
    required String categoryNormalizedName,
    required String subcategoryNormalizedName,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
      SELECT COUNT(*) AS total
      FROM products
      WHERE category = ? AND subcategory = ?
      ''',
      [categoryNormalizedName, subcategoryNormalizedName],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  @override
  Future<int> countProductsForUnit(String normalizedName) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM products WHERE unit_of_measure = ?',
      [normalizedName],
    );
    return (rows.first['total'] as num?)?.toInt() ?? 0;
  }

  Future<void> _seedBaseCatalog(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    var order = 0;
    for (final category in CatalogSeedData.categories) {
      order += 10;
      await _ensureCategory(
        txn,
        normalizedName: category.normalizedName,
        name: CatalogTextNormalizer.displayName(category.normalizedName),
        sortOrder: order,
        now: now,
      );
      final categoryRow = await _categoryByNormalizedName(
        txn,
        category.normalizedName,
      );
      if (categoryRow == null) continue;

      var subOrder = 0;
      for (final subcategory in category.subcategories) {
        subOrder += 10;
        await _ensureSubcategory(
          txn,
          categoryId: categoryRow.id,
          normalizedName: subcategory,
          name: CatalogTextNormalizer.displayName(subcategory),
          sortOrder: subOrder,
          now: now,
        );
      }
    }

    order = 0;
    for (final unit in CatalogSeedData.units) {
      order += 10;
      await _ensureUnit(
        txn,
        normalizedName: unit.normalizedName,
        name: CatalogTextNormalizer.displayName(unit.normalizedName),
        allowsDecimal: unit.allowsDecimal,
        sortOrder: order,
        now: now,
      );
    }
  }

  Future<void> _syncCatalogFromProducts(Transaction txn) async {
    final now = DateTime.now().toIso8601String();
    final rows = await txn.query(
      'products',
      columns: ['category', 'subcategory', 'unit_of_measure'],
    );

    for (final row in rows) {
      final categoryNormalized = _safeNormalized(row['category']);
      if (categoryNormalized == null) continue;
      await _ensureCategory(
        txn,
        normalizedName: categoryNormalized,
        name: CatalogTextNormalizer.displayName(categoryNormalized),
        sortOrder: 999,
        now: now,
      );
      final category = await _categoryByNormalizedName(txn, categoryNormalized);
      if (category == null) continue;

      final subcategoryNormalized = _safeNormalized(row['subcategory']);
      if (subcategoryNormalized != null) {
        await _ensureSubcategory(
          txn,
          categoryId: category.id,
          normalizedName: subcategoryNormalized,
          name: CatalogTextNormalizer.displayName(subcategoryNormalized),
          sortOrder: 999,
          now: now,
        );
      }

      final unitNormalized =
          _safeNormalized(row['unit_of_measure']) ?? 'unidad';
      await _ensureUnit(
        txn,
        normalizedName: unitNormalized,
        name: CatalogTextNormalizer.displayName(unitNormalized),
        allowsDecimal: false,
        sortOrder: 999,
        now: now,
      );
    }
  }

  String? _safeNormalized(Object? value) {
    final raw = (value as String?)?.trim();
    if (raw == null || raw.isEmpty) return null;
    return CatalogTextNormalizer.normalize(raw);
  }

  Future<void> _ensureCategory(
    Transaction txn, {
    required String normalizedName,
    required String name,
    required int sortOrder,
    required String now,
  }) async {
    await txn.insert('categories', {
      'id': 'cat_$normalizedName',
      'name': name,
      'normalized_name': normalizedName,
      'description': null,
      'icon_name': null,
      'color_hex': null,
      'sort_order': sortOrder,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureSubcategory(
    Transaction txn, {
    required String categoryId,
    required String normalizedName,
    required String name,
    required int sortOrder,
    required String now,
  }) async {
    await txn.insert('subcategories', {
      'id': 'sub_${categoryId}_$normalizedName',
      'category_id': categoryId,
      'name': name,
      'normalized_name': normalizedName,
      'description': null,
      'sort_order': sortOrder,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<void> _ensureUnit(
    Transaction txn, {
    required String normalizedName,
    required String name,
    required bool allowsDecimal,
    required int sortOrder,
    required String now,
  }) async {
    await txn.insert('units_of_measure', {
      'id': 'unit_$normalizedName',
      'name': name,
      'normalized_name': normalizedName,
      'symbol': null,
      'allows_decimal': allowsDecimal ? 1 : 0,
      'description': null,
      'sort_order': sortOrder,
      'is_active': 1,
      'created_at': now,
      'updated_at': now,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  Future<CategoryModel?> _categoryById(Transaction txn, String id) async {
    final rows = await txn.query(
      'categories',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }

  Future<CategoryModel?> _categoryByNormalizedName(
    Transaction txn,
    String normalizedName,
  ) async {
    final rows = await txn.query(
      'categories',
      where: 'normalized_name = ?',
      whereArgs: [normalizedName],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CategoryModel.fromMap(rows.first);
  }
}
