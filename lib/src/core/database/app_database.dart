import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

class AppDatabase {
  AppDatabase._();

  static final AppDatabase instance = AppDatabase._();

  static const int _version = 7;

  Database? _database;

  Future<Database> get database async {
    final existing = _database;
    if (existing != null) return existing;
    final db = await _open();
    _database = db;
    return db;
  }

  Future<Database> _open() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, 'pulperia.sqlite');
    return openDatabase(
      path,
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createProductsSchema(db);

        await db.execute('''
CREATE TABLE proformas (
  id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  total REAL NOT NULL,
  discount REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');
        await db.execute('''
CREATE TABLE proforma_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proforma_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY(proforma_id) REFERENCES proformas(id) ON DELETE CASCADE
)
''');
        await db.execute(
          'CREATE INDEX idx_proforma_items_proforma_id ON proforma_items(proforma_id)',
        );

        await _createReceivablesSchema(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS proformas (
  id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  total REAL NOT NULL,
  discount REAL NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL
)
''');
          await db.execute('''
CREATE TABLE IF NOT EXISTS proforma_items (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  proforma_id TEXT NOT NULL,
  product_id TEXT NOT NULL,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL,
  price REAL NOT NULL,
  subtotal REAL NOT NULL,
  FOREIGN KEY(proforma_id) REFERENCES proformas(id) ON DELETE CASCADE
)
''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_proforma_items_proforma_id ON proforma_items(proforma_id)',
          );
        }

        if (oldVersion < 3) {
          await db.execute('''
CREATE TABLE IF NOT EXISTS debts (
  id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  total_amount REAL NOT NULL,
  paid_amount REAL NOT NULL,
  status TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
          await db.execute('''
CREATE TABLE IF NOT EXISTS debt_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  debt_id TEXT NOT NULL,
  amount REAL NOT NULL,
  date TEXT NOT NULL,
  FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE
)
''');
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_id ON debt_payments(debt_id)',
          );
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_debts_status_created_at ON debts(status, created_at)',
          );
        }

        if (oldVersion < 4) {
          await db.transaction((txn) async {
            Future<bool> tableExists(String name) async {
              final rows = await txn.rawQuery(
                "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
                [name],
              );
              return rows.isNotEmpty;
            }

            final debtPaymentsHasType = await txn.rawQuery(
              "PRAGMA table_info('debt_payments')",
            );
            final hasTypeColumn = debtPaymentsHasType.any(
              (c) => (c['name'] as String?) == 'type',
            );

            final hasDebtsOld = await tableExists('debts_old');
            final hasDebtPaymentsOld = await tableExists('debt_payments_old');
            final hasDebts = await tableExists('debts');
            final hasDebtPayments = await tableExists('debt_payments');

            if (!hasDebtsOld && hasDebts) {
              await txn.execute('ALTER TABLE debts RENAME TO debts_old');
            }
            if (!hasDebtPaymentsOld && hasDebtPayments) {
              await txn.execute(
                'ALTER TABLE debt_payments RENAME TO debt_payments_old',
              );
            }

            await txn.execute('''
CREATE TABLE IF NOT EXISTS debts (
  id TEXT PRIMARY KEY,
  customer_name TEXT NOT NULL,
  principal_amount REAL NOT NULL,
  interest_rate REAL NOT NULL,
  accumulated_interest REAL NOT NULL,
  total_amount REAL NOT NULL,
  paid_amount REAL NOT NULL,
  last_interest_date TEXT NOT NULL,
  created_at TEXT NOT NULL
)
''');
            await txn.execute('''
CREATE TABLE IF NOT EXISTS debt_payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  debt_id TEXT NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  date TEXT NOT NULL,
  FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE
)
''');
            await txn.execute('''
CREATE TABLE IF NOT EXISTS debt_interest_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  debt_id TEXT NOT NULL,
  interest_amount REAL NOT NULL,
  rate REAL NOT NULL,
  date TEXT NOT NULL,
  FOREIGN KEY(debt_id) REFERENCES debts(id) ON DELETE CASCADE
)
''');

            if (await tableExists('debts_old')) {
              final rows = await txn.rawQuery(
                'SELECT id, customer_name, total_amount, paid_amount, created_at FROM debts_old',
              );
              for (final r in rows) {
                final total = (r['total_amount'] as num).toDouble();
                final paid = (r['paid_amount'] as num).toDouble();
                final createdAt = r['created_at'] as String;
                final principal = (total - paid) < 0 ? 0.0 : (total - paid);
                await txn.insert('debts', {
                  'id': r['id'] as String,
                  'customer_name': r['customer_name'] as String,
                  'principal_amount': principal,
                  'interest_rate': 0.10,
                  'accumulated_interest': 0.0,
                  'total_amount': principal,
                  'paid_amount': paid,
                  'last_interest_date': createdAt,
                  'created_at': createdAt,
                }, conflictAlgorithm: ConflictAlgorithm.replace);
              }
            }

            if (await tableExists('debt_payments_old')) {
              if (hasTypeColumn) {
                final paymentRows = await txn.rawQuery(
                  'SELECT id, debt_id, amount, type, date FROM debt_payments_old',
                );
                for (final p in paymentRows) {
                  await txn.insert('debt_payments', {
                    'id': p['id'],
                    'debt_id': p['debt_id'],
                    'amount': p['amount'],
                    'type': p['type'] ?? 'capital',
                    'date': p['date'],
                  }, conflictAlgorithm: ConflictAlgorithm.replace);
                }
              } else {
                final paymentRows = await txn.rawQuery(
                  'SELECT id, debt_id, amount, date FROM debt_payments_old',
                );
                for (final p in paymentRows) {
                  await txn.insert('debt_payments', {
                    'id': p['id'],
                    'debt_id': p['debt_id'],
                    'amount': p['amount'],
                    'type': 'capital',
                    'date': p['date'],
                  }, conflictAlgorithm: ConflictAlgorithm.replace);
                }
              }
            }

            await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_debt_payments_debt_id ON debt_payments(debt_id)',
            );
            await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_debts_created_at ON debts(created_at)',
            );
            await txn.execute(
              'CREATE INDEX IF NOT EXISTS idx_debt_interest_history_debt_id ON debt_interest_history(debt_id)',
            );

            if (await tableExists('debts_old')) {
              await txn.execute('DROP TABLE debts_old');
            }
            if (await tableExists('debt_payments_old')) {
              await txn.execute('DROP TABLE debt_payments_old');
            }
          });
        }

        if (oldVersion < 5) {
          final columns = await db.rawQuery("PRAGMA table_info('proformas')");
          final hasDiscount = columns.any(
            (c) => (c['name'] as String?) == 'discount',
          );
          if (!hasDiscount) {
            await db.execute(
              'ALTER TABLE proformas ADD COLUMN discount REAL NOT NULL DEFAULT 0',
            );
          }
        }

        if (oldVersion < 6) {
          await _resetProductsSchema(db);
        }

        if (oldVersion < 7) {
          await _migrateDebtsToReceivables(db);
        }
      },
    );
  }
}

Future<void> _createProductsSchema(DatabaseExecutor db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS products (
  id TEXT PRIMARY KEY,
  sku TEXT,
  name TEXT NOT NULL,
  normalized_name TEXT,
  brand TEXT,
  category TEXT NOT NULL,
  subcategory TEXT,
  unit_of_measure TEXT NOT NULL DEFAULT 'unidad',
  barcode TEXT,
  cost_price REAL NOT NULL,
  cost_price_without_vat REAL,
  sale_price REAL NOT NULL,
  margin_amount REAL NOT NULL,
  margin_percent REAL NOT NULL,
  currency TEXT NOT NULL DEFAULT 'NIO',
  tax_type TEXT NOT NULL DEFAULT 'iva_incluido',
  vat_rate_applied REAL NOT NULL DEFAULT 0.15,
  vat_amount_on_cost REAL NOT NULL DEFAULT 0,
  stock REAL NOT NULL DEFAULT 0,
  min_stock REAL NOT NULL DEFAULT 0,
  is_active INTEGER NOT NULL DEFAULT 1,
  allow_decimal_quantity INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');

  await db.execute('''
CREATE TABLE IF NOT EXISTS product_price_history (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id TEXT NOT NULL,
  cost_price REAL NOT NULL,
  sale_price REAL,
  vat_rate_applied REAL,
  tax_type TEXT,
  recorded_at TEXT NOT NULL,
  FOREIGN KEY(product_id) REFERENCES products(id) ON DELETE CASCADE
)
''');

  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_name ON products(name COLLATE NOCASE)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_normalized_name ON products(normalized_name COLLATE NOCASE)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_category ON products(category COLLATE NOCASE)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_barcode ON products(barcode COLLATE NOCASE)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_products_sku ON products(sku COLLATE NOCASE)',
  );
  await db.execute(
    "CREATE UNIQUE INDEX IF NOT EXISTS ux_products_sku ON products(sku) WHERE sku IS NOT NULL AND sku <> ''",
  );
  await db.execute(
    "CREATE UNIQUE INDEX IF NOT EXISTS ux_products_barcode ON products(barcode) WHERE barcode IS NOT NULL AND barcode <> ''",
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_price_history_product_id ON product_price_history(product_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_price_history_recorded_at ON product_price_history(recorded_at)',
  );
}

Future<void> _resetProductsSchema(Database db) async {
  await db.transaction((txn) async {
    await txn.execute('DROP INDEX IF EXISTS idx_products_name');
    await txn.execute('DROP INDEX IF EXISTS idx_products_normalized_name');
    await txn.execute('DROP INDEX IF EXISTS idx_products_category');
    await txn.execute('DROP INDEX IF EXISTS idx_products_barcode');
    await txn.execute('DROP INDEX IF EXISTS idx_products_sku');
    await txn.execute('DROP INDEX IF EXISTS ux_products_sku');
    await txn.execute('DROP INDEX IF EXISTS ux_products_barcode');
    await txn.execute('DROP INDEX IF EXISTS idx_price_history_product_id');
    await txn.execute('DROP INDEX IF EXISTS idx_price_history_recorded_at');

    await txn.execute('DROP TABLE IF EXISTS product_price_history');
    await txn.execute('DROP TABLE IF EXISTS price_history');
    await txn.execute('DROP TABLE IF EXISTS products');

    await _createProductsSchema(txn);
  });
}

Future<void> _createReceivablesSchema(DatabaseExecutor db) async {
  await db.execute('''
CREATE TABLE IF NOT EXISTS customers (
  customer_id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  normalized_name TEXT NOT NULL,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL
)
''');
  await db.execute(
    'CREATE UNIQUE INDEX IF NOT EXISTS ux_customers_normalized_name ON customers(normalized_name COLLATE NOCASE)',
  );

  await db.execute('''
CREATE TABLE IF NOT EXISTS receivables (
  receivable_id TEXT PRIMARY KEY,
  customer_id TEXT NOT NULL,
  sale_id TEXT,
  principal_amount REAL NOT NULL,
  due_date TEXT NOT NULL,
  status TEXT NOT NULL,
  monthly_rate REAL NOT NULL,
  generation_cycle_days INTEGER NOT NULL,
  applies_on_overdue_only INTEGER NOT NULL DEFAULT 0,
  compound_interest INTEGER NOT NULL DEFAULT 0,
  created_at TEXT NOT NULL,
  updated_at TEXT NOT NULL,
  closed_at TEXT,
  FOREIGN KEY(customer_id) REFERENCES customers(customer_id) ON DELETE RESTRICT
)
''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivables_customer_id ON receivables(customer_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivables_due_date ON receivables(due_date)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivables_status ON receivables(status)',
  );

  await db.execute('''
CREATE TABLE IF NOT EXISTS payment_receipts (
  id TEXT PRIMARY KEY,
  receivable_id TEXT NOT NULL,
  total_amount REAL NOT NULL,
  paid_at TEXT NOT NULL,
  method TEXT,
  note TEXT,
  created_at TEXT NOT NULL,
  reversed_at TEXT,
  reversed_reason TEXT,
  FOREIGN KEY(receivable_id) REFERENCES receivables(receivable_id) ON DELETE CASCADE
)
''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_payment_receipts_receivable_id ON payment_receipts(receivable_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_payment_receipts_paid_at ON payment_receipts(paid_at)',
  );

  await db.execute('''
CREATE TABLE IF NOT EXISTS receivable_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receivable_id TEXT NOT NULL,
  type TEXT NOT NULL,
  amount REAL NOT NULL,
  occurred_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  receipt_id TEXT,
  related_transaction_id INTEGER,
  note TEXT,
  period_start TEXT,
  period_end TEXT,
  rate REAL,
  base_amount REAL,
  generated_amount REAL,
  FOREIGN KEY(receivable_id) REFERENCES receivables(receivable_id) ON DELETE CASCADE,
  FOREIGN KEY(receipt_id) REFERENCES payment_receipts(id) ON DELETE SET NULL
)
''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivable_transactions_receivable_id ON receivable_transactions(receivable_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivable_transactions_occurred_at ON receivable_transactions(occurred_at)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_receivable_transactions_type ON receivable_transactions(type)',
  );
  await db.execute(
    "CREATE UNIQUE INDEX IF NOT EXISTS ux_interest_period ON receivable_transactions(receivable_id, period_start, period_end) WHERE type = 'interest_charge'",
  );

  await db.execute('''
CREATE TABLE IF NOT EXISTS collection_actions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  receivable_id TEXT NOT NULL,
  type TEXT NOT NULL,
  note TEXT,
  action_at TEXT NOT NULL,
  created_at TEXT NOT NULL,
  FOREIGN KEY(receivable_id) REFERENCES receivables(receivable_id) ON DELETE CASCADE
)
''');
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_collection_actions_receivable_id ON collection_actions(receivable_id)',
  );
  await db.execute(
    'CREATE INDEX IF NOT EXISTS idx_collection_actions_action_at ON collection_actions(action_at)',
  );
}

Future<void> _migrateDebtsToReceivables(Database db) async {
  await db.transaction((txn) async {
    Future<bool> tableExists(String name) async {
      final rows = await txn.rawQuery(
        "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
        [name],
      );
      return rows.isNotEmpty;
    }

    await _createReceivablesSchema(txn);

    if (!await tableExists('debts')) {
      return;
    }

    final debts = await txn.query('debts');
    for (final d in debts) {
      final debtId = d['id'] as String;
      final customerName = (d['customer_name'] as String?) ?? '';
      final normalized = _normalizeCustomerName(customerName);
      final customerId = 'c_${_stableHash(normalized)}';
      final createdAt = DateTime.parse(d['created_at'] as String);
      final dueDate = createdAt.add(const Duration(days: 30));
      final monthlyRate = (d['interest_rate'] as num).toDouble();
      final remainingPrincipal = (d['principal_amount'] as num).toDouble();
      final remainingInterest = (d['accumulated_interest'] as num).toDouble();

      final paymentsRows = await txn.query(
        'debt_payments',
        where: 'debt_id = ?',
        whereArgs: [debtId],
      );
      var capitalPaid = 0.0;
      var interestPaid = 0.0;
      for (final p in paymentsRows) {
        final amount = (p['amount'] as num).toDouble();
        final type = (p['type'] as String?) ?? 'capital';
        if (type == 'interest') {
          interestPaid += amount;
        } else {
          capitalPaid += amount;
        }
      }
      final originalPrincipal = remainingPrincipal + capitalPaid;
      final originalInterest = remainingInterest + interestPaid;

      final now = DateTime.now().toIso8601String();
      await txn.insert('customers', {
        'customer_id': customerId,
        'name': customerName.trim().isEmpty ? 'Cliente' : customerName.trim(),
        'normalized_name': normalized,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);

      final status = (remainingPrincipal + remainingInterest) <= 0
          ? 'paid'
          : DateTime.now().isAfter(dueDate)
          ? 'overdue'
          : 'active';

      await txn.insert('receivables', {
        'receivable_id': debtId,
        'customer_id': customerId,
        'sale_id': null,
        'principal_amount': originalPrincipal,
        'due_date': dueDate.toIso8601String(),
        'status': status,
        'monthly_rate': monthlyRate,
        'generation_cycle_days': 30,
        'applies_on_overdue_only': 0,
        'compound_interest': 0,
        'created_at': createdAt.toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
        'closed_at': status == 'paid' ? DateTime.now().toIso8601String() : null,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      await txn.insert('receivable_transactions', {
        'receivable_id': debtId,
        'type': 'principal_charge',
        'amount': originalPrincipal,
        'occurred_at': createdAt.toIso8601String(),
        'created_at': DateTime.now().toIso8601String(),
      });

      final interestHistory = await txn.query(
        'debt_interest_history',
        where: 'debt_id = ?',
        whereArgs: [debtId],
        orderBy: 'date ASC, id ASC',
      );
      DateTime? prev = createdAt;
      for (final h in interestHistory) {
        final interestAmount = (h['interest_amount'] as num).toDouble();
        final date = DateTime.parse(h['date'] as String);
        final rate = (h['rate'] as num).toDouble();
        final ps = prev;
        await txn.insert('receivable_transactions', {
          'receivable_id': debtId,
          'type': 'interest_charge',
          'amount': interestAmount,
          'occurred_at': date.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'period_start': ps?.toIso8601String(),
          'period_end': date.toIso8601String(),
          'rate': rate,
          'base_amount': originalPrincipal,
          'generated_amount': interestAmount,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
        prev = date;
      }

      for (final p in paymentsRows) {
        final pid = p['id'] as int;
        final amount = (p['amount'] as num).toDouble();
        final type = (p['type'] as String?) ?? 'capital';
        final date = DateTime.parse(p['date'] as String);
        final receiptId = 'migr_${debtId}_$pid';
        await txn.insert('payment_receipts', {
          'id': receiptId,
          'receivable_id': debtId,
          'total_amount': amount,
          'paid_at': date.toIso8601String(),
          'method': null,
          'note': 'Migrado',
          'created_at': DateTime.now().toIso8601String(),
          'reversed_at': null,
          'reversed_reason': null,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);

        await txn.insert('receivable_transactions', {
          'receivable_id': debtId,
          'type': type == 'interest' ? 'payment_interest' : 'payment_principal',
          'amount': amount,
          'occurred_at': date.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'receipt_id': receiptId,
        });
      }

      if (originalInterest > 0 && interestHistory.isEmpty) {
        await txn.insert('receivable_transactions', {
          'receivable_id': debtId,
          'type': 'interest_charge',
          'amount': originalInterest,
          'occurred_at': createdAt.toIso8601String(),
          'created_at': DateTime.now().toIso8601String(),
          'period_start': createdAt.toIso8601String(),
          'period_end': createdAt.toIso8601String(),
          'rate': monthlyRate,
          'base_amount': originalPrincipal,
          'generated_amount': originalInterest,
        }, conflictAlgorithm: ConflictAlgorithm.ignore);
      }
    }

    await txn.execute('DROP TABLE IF EXISTS debt_interest_history');
    await txn.execute('DROP TABLE IF EXISTS debt_payments');
    await txn.execute('DROP TABLE IF EXISTS debts');
  });
}

String _normalizeCustomerName(String name) {
  final lower = name.toLowerCase().trim();
  final withoutDiacritics = lower
      .replaceAll('á', 'a')
      .replaceAll('à', 'a')
      .replaceAll('ä', 'a')
      .replaceAll('â', 'a')
      .replaceAll('ã', 'a')
      .replaceAll('é', 'e')
      .replaceAll('è', 'e')
      .replaceAll('ë', 'e')
      .replaceAll('ê', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ì', 'i')
      .replaceAll('ï', 'i')
      .replaceAll('î', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ò', 'o')
      .replaceAll('ö', 'o')
      .replaceAll('ô', 'o')
      .replaceAll('õ', 'o')
      .replaceAll('ú', 'u')
      .replaceAll('ù', 'u')
      .replaceAll('ü', 'u')
      .replaceAll('û', 'u')
      .replaceAll('ñ', 'n');
  final normalized = withoutDiacritics
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .trim();
  return normalized.isEmpty ? 'cliente' : normalized;
}

int _stableHash(String input) {
  var hash = 0;
  for (final unit in input.codeUnits) {
    hash = 0x1fffffff & (hash + unit);
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    hash ^= (hash >> 6);
  }
  hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
  hash ^= (hash >> 11);
  hash = 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  return hash & 0x7fffffff;
}
