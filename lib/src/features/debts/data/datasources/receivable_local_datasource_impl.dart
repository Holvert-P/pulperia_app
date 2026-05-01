import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/features/debts/data/datasources/receivable_local_datasource.dart';
import 'package:app/src/features/debts/data/models/collection_action_model.dart';
import 'package:app/src/features/debts/data/models/payment_receipt_model.dart';
import 'package:app/src/features/debts/data/models/receivable_model.dart';
import 'package:app/src/features/debts/data/models/receivable_transaction_model.dart';
import 'package:sqflite/sqflite.dart';

class ReceivableLocalDataSourceImpl implements ReceivableLocalDataSource {
  ReceivableLocalDataSourceImpl({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  @override
  Future<void> upsertCustomer({
    required String customerId,
    required String name,
    required String normalizedName,
    DateTime? now,
  }) async {
    final db = await _database.database;
    final ts = (now ?? DateTime.now()).toIso8601String();
    await db.insert('customers', {
      'customer_id': customerId,
      'name': name,
      'normalized_name': normalizedName,
      'created_at': ts,
      'updated_at': ts,
    }, conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> createReceivable(ReceivableModel receivable) async {
    final db = await _database.database;
    await db.insert(
      'receivables',
      receivable.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ReceivableModel>> getReceivables({String? statusFilter}) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
SELECT
  r.*,
  c.name AS customer_name
FROM receivables r
JOIN customers c ON c.customer_id = r.customer_id
${statusFilter == null ? '' : 'WHERE r.status = ?'}
ORDER BY r.created_at DESC
''', statusFilter == null ? const [] : [statusFilter]);
    return rows.map((r) => ReceivableModel.fromMap(r)).toList();
  }

  @override
  Future<ReceivableModel?> getReceivableById(String receivableId) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT
  r.*,
  c.name AS customer_name
FROM receivables r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.receivable_id = ?
LIMIT 1
''',
      [receivableId],
    );
    if (rows.isEmpty) return null;
    return ReceivableModel.fromMap(rows.first);
  }

  @override
  Future<List<ReceivableModel>> getCustomerReceivables(
    String customerId,
  ) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
SELECT
  r.*,
  c.name AS customer_name
FROM receivables r
JOIN customers c ON c.customer_id = r.customer_id
WHERE r.customer_id = ?
ORDER BY r.created_at DESC
''',
      [customerId],
    );
    return rows.map((r) => ReceivableModel.fromMap(r)).toList();
  }

  @override
  Future<List<ReceivableTransactionModel>> getLedger(
    String receivableId,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'receivable_transactions',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
      orderBy: 'occurred_at DESC, id DESC',
    );
    return rows.map(ReceivableTransactionModel.fromMap).toList();
  }

  @override
  Future<List<CollectionActionModel>> getCollectionActions(
    String receivableId,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'collection_actions',
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
      orderBy: 'action_at DESC, id DESC',
    );
    return rows.map(CollectionActionModel.fromMap).toList();
  }

  @override
  Future<void> insertTransaction(ReceivableTransactionModel transaction) async {
    final db = await _database.database;
    await db.insert(
      'receivable_transactions',
      transaction.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> insertTransactions(
    List<ReceivableTransactionModel> transactions,
  ) async {
    final db = await _database.database;
    await db.transaction((txn) async {
      final batch = txn.batch();
      for (final t in transactions) {
        batch.insert(
          'receivable_transactions',
          t.toMap()..remove('id'),
          conflictAlgorithm: ConflictAlgorithm.abort,
        );
      }
      await batch.commit(noResult: true);
    });
  }

  @override
  Future<void> insertReceipt(PaymentReceiptModel receipt) async {
    final db = await _database.database;
    await db.insert(
      'payment_receipts',
      receipt.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<PaymentReceiptModel?> getReceiptById(String receiptId) async {
    final db = await _database.database;
    final rows = await db.query(
      'payment_receipts',
      where: 'id = ?',
      whereArgs: [receiptId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return PaymentReceiptModel.fromMap(rows.first);
  }

  @override
  Future<void> markReceiptReversed({
    required String receiptId,
    required DateTime reversedAt,
    required String reason,
  }) async {
    final db = await _database.database;
    await db.update(
      'payment_receipts',
      {'reversed_at': reversedAt.toIso8601String(), 'reversed_reason': reason},
      where: 'id = ?',
      whereArgs: [receiptId],
    );
  }

  @override
  Future<void> insertCollectionAction(CollectionActionModel action) async {
    final db = await _database.database;
    await db.insert(
      'collection_actions',
      action.toMap()..remove('id'),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  @override
  Future<void> updateReceivableStatus({
    required String receivableId,
    required String status,
    required DateTime updatedAt,
    DateTime? closedAt,
  }) async {
    final db = await _database.database;
    await db.update(
      'receivables',
      {
        'status': status,
        'updated_at': updatedAt.toIso8601String(),
        'closed_at': closedAt?.toIso8601String(),
      },
      where: 'receivable_id = ?',
      whereArgs: [receivableId],
    );
  }

  @override
  Future<Map<String, Object?>> getBalances(
    String receivableId, {
    DateTime? now,
  }) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
WITH r AS (
  SELECT receivable_id, due_date, monthly_rate, generation_cycle_days, applies_on_overdue_only, compound_interest, created_at
  FROM receivables
  WHERE receivable_id = ?
  LIMIT 1
)
SELECT
  (SELECT generation_cycle_days FROM r) AS generation_cycle_days,
  (SELECT applies_on_overdue_only FROM r) AS applies_on_overdue_only,
  (SELECT created_at FROM r) AS created_at,
  COALESCE(SUM(CASE
    WHEN t.type IN ('principal_charge','principal_adjust') THEN t.amount
    WHEN t.type IN ('payment_principal') THEN -t.amount
    WHEN t.type IN ('reversal_payment_principal') THEN t.amount
    ELSE 0
  END), 0) AS principal_pending,
  COALESCE(SUM(CASE
    WHEN t.type IN ('interest_charge','interest_adjust') THEN t.amount
    WHEN t.type IN ('payment_interest','payment_interest_current','payment_interest_overdue') THEN -t.amount
    WHEN t.type IN ('reversal_payment_interest','reversal_payment_interest_current','reversal_payment_interest_overdue') THEN t.amount
    ELSE 0
  END), 0) AS interest_pending,
  COALESCE(SUM(CASE
    WHEN t.type IN ('interest_charge','interest_adjust')
      AND date(COALESCE(t.period_end, t.occurred_at)) <= date((SELECT due_date FROM r))
      THEN t.amount
    WHEN t.type IN ('payment_interest_current') THEN -t.amount
    WHEN t.type IN ('reversal_payment_interest_current') THEN t.amount
    ELSE 0
  END), 0) AS interest_pending_current,
  COALESCE(SUM(CASE
    WHEN t.type IN ('interest_charge','interest_adjust')
      AND date(COALESCE(t.period_end, t.occurred_at)) > date((SELECT due_date FROM r))
      THEN t.amount
    WHEN t.type IN ('payment_interest_overdue') THEN -t.amount
    WHEN t.type IN ('reversal_payment_interest_overdue') THEN t.amount
    ELSE 0
  END), 0) AS interest_pending_overdue,
  MAX(CASE
    WHEN t.type IN (
      'payment_principal',
      'payment_interest',
      'payment_interest_current',
      'payment_interest_overdue'
    )
    THEN t.occurred_at
    ELSE NULL
  END) AS last_payment_at,
  MAX(CASE WHEN t.type = 'interest_charge' THEN t.period_end ELSE NULL END) AS last_interest_period_end
FROM receivable_transactions t
WHERE t.receivable_id = ?
''',
      [receivableId, receivableId],
    );
    if (rows.isEmpty) {
      return {
        'principal_pending': 0.0,
        'interest_pending': 0.0,
        'interest_pending_current': 0.0,
        'interest_pending_overdue': 0.0,
        'last_payment_at': null,
        'last_interest_period_end': null,
      };
    }
    return rows.first;
  }

  @override
  Future<Map<String, Object?>> getPortfolioSummary({DateTime? now}) async {
    final db = await _database.database;
    final rows = await db.rawQuery('''
WITH balances AS (
  SELECT
    r.receivable_id,
    r.due_date,
    r.status,
    COALESCE(SUM(CASE
      WHEN t.type IN ('principal_charge','principal_adjust') THEN t.amount
      WHEN t.type IN ('payment_principal') THEN -t.amount
      WHEN t.type IN ('reversal_payment_principal') THEN t.amount
      ELSE 0
    END), 0) AS principal_pending,
    COALESCE(SUM(CASE
      WHEN t.type IN ('interest_charge','interest_adjust') THEN t.amount
      WHEN t.type IN ('payment_interest','payment_interest_current','payment_interest_overdue') THEN -t.amount
      WHEN t.type IN ('reversal_payment_interest','reversal_payment_interest_current','reversal_payment_interest_overdue') THEN t.amount
      ELSE 0
    END), 0) AS interest_pending
  FROM receivables r
  LEFT JOIN receivable_transactions t ON t.receivable_id = r.receivable_id
  WHERE r.status IN ('active','overdue')
  GROUP BY r.receivable_id
),
aging AS (
  SELECT
    CASE
      WHEN date(due_date) >= date('now') THEN 0
      ELSE CAST((julianday('now') - julianday(due_date)) AS INTEGER)
    END AS days_overdue,
    (principal_pending + interest_pending) AS total_pending
  FROM balances
  WHERE (principal_pending + interest_pending) > 0
),
payments_today AS (
  SELECT COALESCE(SUM(total_amount), 0) AS total
  FROM payment_receipts
  WHERE date(paid_at) = date('now') AND reversed_at IS NULL
),
payments_month AS (
  SELECT COALESCE(SUM(total_amount), 0) AS total
  FROM payment_receipts
  WHERE strftime('%Y-%m', paid_at) = strftime('%Y-%m', 'now') AND reversed_at IS NULL
)
SELECT
  COALESCE((SELECT SUM(principal_pending + interest_pending) FROM balances), 0) AS total_portfolio,
  COALESCE((SELECT SUM(principal_pending) FROM balances), 0) AS total_principal_pending,
  COALESCE((SELECT SUM(interest_pending) FROM balances), 0) AS total_interest_pending,
  (SELECT total FROM payments_today) AS collected_today,
  (SELECT total FROM payments_month) AS collected_this_month,
  COALESCE(
    (SELECT SUM(CASE WHEN date(due_date) < date('now') AND (principal_pending + interest_pending) > 0 THEN 1 ELSE 0 END) FROM balances),
    0
  ) AS overdue_count,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 0 AND 30 THEN total_pending ELSE 0 END) FROM aging), 0) AS aging_0_30_total,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 0 AND 30 THEN 1 ELSE 0 END) FROM aging), 0) AS aging_0_30_count,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 31 AND 60 THEN total_pending ELSE 0 END) FROM aging), 0) AS aging_31_60_total,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 31 AND 60 THEN 1 ELSE 0 END) FROM aging), 0) AS aging_31_60_count,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 61 AND 90 THEN total_pending ELSE 0 END) FROM aging), 0) AS aging_61_90_total,
  COALESCE((SELECT SUM(CASE WHEN days_overdue BETWEEN 61 AND 90 THEN 1 ELSE 0 END) FROM aging), 0) AS aging_61_90_count,
  COALESCE((SELECT SUM(CASE WHEN days_overdue >= 91 THEN total_pending ELSE 0 END) FROM aging), 0) AS aging_91_plus_total,
  COALESCE((SELECT SUM(CASE WHEN days_overdue >= 91 THEN 1 ELSE 0 END) FROM aging), 0) AS aging_91_plus_count
''');
    if (rows.isEmpty) {
      return {
        'total_portfolio': 0.0,
        'total_principal_pending': 0.0,
        'total_interest_pending': 0.0,
        'collected_today': 0.0,
        'collected_this_month': 0.0,
        'overdue_count': 0,
        'aging_0_30_total': 0.0,
        'aging_0_30_count': 0,
        'aging_31_60_total': 0.0,
        'aging_31_60_count': 0,
        'aging_61_90_total': 0.0,
        'aging_61_90_count': 0,
        'aging_91_plus_total': 0.0,
        'aging_91_plus_count': 0,
      };
    }
    return rows.first;
  }

  @override
  Future<List<Map<String, Object?>>> getTopCustomers({int limit = 5}) async {
    final db = await _database.database;
    final rows = await db.rawQuery(
      '''
WITH balances AS (
  SELECT
    r.receivable_id,
    r.customer_id,
    COALESCE(SUM(CASE
      WHEN t.type IN ('principal_charge','principal_adjust') THEN t.amount
      WHEN t.type IN ('payment_principal') THEN -t.amount
      WHEN t.type IN ('reversal_payment_principal') THEN t.amount
      ELSE 0
    END), 0) AS principal_pending,
    COALESCE(SUM(CASE
      WHEN t.type IN ('interest_charge','interest_adjust') THEN t.amount
      WHEN t.type IN ('payment_interest','payment_interest_current','payment_interest_overdue') THEN -t.amount
      WHEN t.type IN ('reversal_payment_interest','reversal_payment_interest_current','reversal_payment_interest_overdue') THEN t.amount
      ELSE 0
    END), 0) AS interest_pending
  FROM receivables r
  LEFT JOIN receivable_transactions t ON t.receivable_id = r.receivable_id
  WHERE r.status IN ('active','overdue')
  GROUP BY r.receivable_id
)
SELECT
  c.customer_id,
  c.name AS customer_name,
  COUNT(*) AS receivable_count,
  COALESCE(SUM(principal_pending + interest_pending), 0) AS total_pending
FROM balances b
JOIN customers c ON c.customer_id = b.customer_id
WHERE (principal_pending + interest_pending) > 0
GROUP BY c.customer_id
ORDER BY total_pending DESC
LIMIT ?
''',
      [limit],
    );
    return rows;
  }
}
