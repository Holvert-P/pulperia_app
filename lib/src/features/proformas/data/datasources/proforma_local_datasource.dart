import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/proformas/data/models/proforma_item_model.dart';
import 'package:app/src/features/proformas/data/models/proforma_model.dart';
import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';

class ProformaLocalDataSource {
  ProformaLocalDataSource({AppDatabase? database})
      : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> createProforma(ProformaModel proforma) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.insert('proformas', proforma.toMap());
      for (final item in proforma.items) {
        final model = ProformaItemModel.fromEntity(
          proformaId: proforma.id,
          item: item,
        );
        await txn.insert('proforma_items', model.toMap());
      }
    });
  }

  Future<void> updateProforma(ProformaModel proforma) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      await txn.update(
        'proformas',
        proforma.toMap(),
        where: 'id = ?',
        whereArgs: [proforma.id],
      );

      await txn.delete(
        'proforma_items',
        where: 'proforma_id = ?',
        whereArgs: [proforma.id],
      );

      for (final item in proforma.items) {
        final model = ProformaItemModel.fromEntity(
          proformaId: proforma.id,
          item: item,
        );
        await txn.insert('proforma_items', model.toMap());
      }
    });
  }

  Future<List<ProformaModel>> getProformas() async {
    final db = await _database.database;
    final rows = await db.query(
      'proformas',
      orderBy: 'created_at DESC',
    );
    return rows.map((r) => ProformaModel.fromMap(r)).toList();
  }

  Future<ProformaModel?> getProformaById(String id) async {
    final db = await _database.database;
    final proformaRows = await db.query(
      'proformas',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (proformaRows.isEmpty) return null;

    final itemRows = await db.query(
      'proforma_items',
      where: 'proforma_id = ?',
      whereArgs: [id],
      orderBy: 'id ASC',
    );
    final items = itemRows.map(ProformaItemModel.fromMap).map((m) => m.toEntity()).toList();

    return ProformaModel.fromMap(
      proformaRows.first,
      items: items,
    );
  }

  Future<void> deleteProforma(String id) async {
    final db = await _database.database;
    await db.delete('proformas', where: 'id = ?', whereArgs: [id]);
  }

  static double calculateSubtotal(int quantity, double price) {
    return quantity * price;
  }

  static double calculateTotal(List<ProformaItem> items) {
    return items.fold<double>(0, (sum, i) => sum + i.subtotal);
  }
}
