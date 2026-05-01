import 'package:app/src/core/database/app_database.dart';
import 'package:app/src/core/services/notification_service.dart';
import 'package:app/src/features/debts/data/models/debt_interest_entry_model.dart';
import 'package:app/src/features/debts/data/models/debt_model.dart';
import 'package:app/src/features/debts/data/models/debt_payment_model.dart';
import 'package:sqflite/sqflite.dart';

class _InterestGenerated {
  const _InterestGenerated({required this.customerName, required this.amount});

  final String customerName;
  final double amount;
}

class DebtLocalDataSource {
  DebtLocalDataSource({AppDatabase? database})
    : _database = database ?? AppDatabase.instance;

  final AppDatabase _database;

  Future<void> createDebt(DebtModel debt) async {
    final db = await _database.database;
    final shouldGenerateInitialInterest =
        debt.principalAmount > 0 &&
        debt.interestRate > 0 &&
        debt.accumulatedInterest <= 0;
    final initialInterest = shouldGenerateInitialInterest
        ? debt.principalAmount * debt.interestRate
        : 0.0;

    await db.transaction((txn) async {
      await txn.insert('debts', {
        ...debt.toMap(),
        if (shouldGenerateInitialInterest)
          'accumulated_interest': initialInterest,
        if (shouldGenerateInitialInterest)
          'total_amount': debt.principalAmount + initialInterest,
      });

      if (!shouldGenerateInitialInterest) return;
      await txn.insert(
        'debt_interest_history',
        DebtInterestEntryModel(
          id: null,
          debtId: debt.id,
          interestAmount: initialInterest,
          rate: debt.interestRate,
          date: debt.createdAt,
        ).toMap(),
      );
    });
    await NotificationService.instance.ensureDailyPendingDebtNotification(
      debtId: debt.id,
      customerName: debt.customerName,
      pendingAmount:
          debt.principalAmount + debt.accumulatedInterest + initialInterest,
      hour: 9,
      minute: 0,
    );
  }

  Future<void> applyInterestForAllIfNeeded({DateTime? now}) async {
    final db = await _database.database;
    final currentNow = now ?? DateTime.now();
    final generated = <_InterestGenerated>[];
    await db.transaction((txn) async {
      final debts = await txn.query(
        'debts',
        columns: [
          'id',
          'customer_name',
          'principal_amount',
          'interest_rate',
          'accumulated_interest',
          'last_interest_date',
        ],
      );
      for (final d in debts) {
        final gen = await _applyInterestForDebtRow(
          txn,
          d,
          currentNow: currentNow,
        );
        if (gen != null) generated.add(gen);
      }
    });

    for (final gen in generated) {
      if (gen.customerName.trim().isEmpty) continue;
      await NotificationService.instance.showInstantNotification(
        title: 'Intereses generados',
        body:
            'Se generaron C\$ ${gen.amount.toStringAsFixed(2)} de interés para ${gen.customerName}',
      );
    }
  }

  Future<void> applyInterestForDebtIfNeeded(
    String debtId, {
    DateTime? now,
  }) async {
    final db = await _database.database;
    final currentNow = now ?? DateTime.now();
    _InterestGenerated? generated;
    await db.transaction((txn) async {
      final rows = await txn.query(
        'debts',
        where: 'id = ?',
        whereArgs: [debtId],
        limit: 1,
      );
      if (rows.isEmpty) return;
      generated = await _applyInterestForDebtRow(
        txn,
        rows.first,
        currentNow: currentNow,
      );
    });

    final gen = generated;
    if (gen == null) return;
    if (gen.customerName.trim().isEmpty) return;
    await NotificationService.instance.showInstantNotification(
      title: 'Intereses generados',
      body:
          'Se generaron C\$ ${gen.amount.toStringAsFixed(2)} de interés para ${gen.customerName}',
    );
  }

  Future<_InterestGenerated?> _applyInterestForDebtRow(
    Transaction txn,
    Map<String, Object?> debtRow, {
    required DateTime currentNow,
  }) async {
    final debtId = debtRow['id'] as String;
    final customerName = (debtRow['customer_name'] as String?) ?? '';
    final principal = (debtRow['principal_amount'] as num).toDouble();
    final rate = (debtRow['interest_rate'] as num).toDouble();
    var accumulated = (debtRow['accumulated_interest'] as num).toDouble();
    var lastDate = DateTime.parse(debtRow['last_interest_date'] as String);
    var generatedInterest = 0.0;

    if (principal <= 0) return null;
    if (rate <= 0) return null;

    while (currentNow.difference(lastDate).inDays >= 30) {
      final nextDate = lastDate.add(const Duration(days: 30));
      final interest = principal * rate;
      accumulated += interest;
      generatedInterest += interest;

      await txn.insert(
        'debt_interest_history',
        DebtInterestEntryModel(
          id: null,
          debtId: debtId,
          interestAmount: interest,
          rate: rate,
          date: nextDate,
        ).toMap(),
      );

      lastDate = nextDate;
    }

    await txn.update(
      'debts',
      {
        'accumulated_interest': accumulated,
        'total_amount': principal + accumulated,
        'last_interest_date': lastDate.toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [debtId],
    );

    if (generatedInterest <= 0) return null;
    if (customerName.trim().isEmpty) return null;
    return _InterestGenerated(
      customerName: customerName,
      amount: generatedInterest,
    );
  }

  Future<List<DebtModel>> getDebts() async {
    await applyInterestForAllIfNeeded();
    final db = await _database.database;
    final rows = await db.query(
      'debts',
      orderBy:
          "CASE WHEN (principal_amount + accumulated_interest) <= 0 THEN 1 ELSE 0 END, created_at DESC",
    );
    final models = rows.map(DebtModel.fromMap).toList();
    await NotificationService.instance.syncPendingDebtNotifications(
      debts: models
          .map(
            (d) => PendingDebtNotificationData(
              debtId: d.id,
              customerName: d.customerName,
              pendingAmount: d.principalAmount + d.accumulatedInterest,
              isPaid: (d.principalAmount + d.accumulatedInterest) <= 0,
            ),
          )
          .toList(),
      hour: 9,
      minute: 0,
    );
    return models;
  }

  Future<DebtModel?> getDebtById(String id) async {
    await applyInterestForDebtIfNeeded(id);
    final db = await _database.database;
    final rows = await db.query(
      'debts',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final model = DebtModel.fromMap(rows.first);
    final total = model.principalAmount + model.accumulatedInterest;
    if (total > 0) {
      await NotificationService.instance.ensureDailyPendingDebtNotification(
        debtId: model.id,
        customerName: model.customerName,
        pendingAmount: total,
        hour: 9,
        minute: 0,
      );
    } else {
      await NotificationService.instance.cancelPendingDebtNotification(
        model.id,
      );
      await NotificationService.instance.cancelDebtReminder(model.id);
    }
    return model;
  }

  Future<List<DebtPaymentModel>> getDebtPayments(String debtId) async {
    final db = await _database.database;
    final rows = await db.query(
      'debt_payments',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(DebtPaymentModel.fromMap).toList();
  }

  Future<List<DebtInterestEntryModel>> getDebtInterestHistory(
    String debtId,
  ) async {
    final db = await _database.database;
    final rows = await db.query(
      'debt_interest_history',
      where: 'debt_id = ?',
      whereArgs: [debtId],
      orderBy: 'date DESC, id DESC',
    );
    return rows.map(DebtInterestEntryModel.fromMap).toList();
  }

  Future<void> addPayment({
    required String debtId,
    required double amount,
    required String type,
    required DateTime date,
  }) async {
    final db = await _database.database;
    String? customerName;
    double? nextTotalDebt;
    await db.transaction((txn) async {
      final debtRows = await txn.query(
        'debts',
        where: 'id = ?',
        whereArgs: [debtId],
        limit: 1,
      );
      if (debtRows.isEmpty) {
        throw StateError('Debt not found');
      }

      customerName = debtRows.first['customer_name'] as String?;
      final currentPaid = (debtRows.first['paid_amount'] as num).toDouble();
      final principal = (debtRows.first['principal_amount'] as num).toDouble();
      final accumulated = (debtRows.first['accumulated_interest'] as num)
          .toDouble();
      final nextPaid = currentPaid + amount;

      double nextPrincipal = principal;
      double nextAccumulated = accumulated;

      if (type == 'capital') {
        nextPrincipal = principal - amount;
        if (nextPrincipal < 0) nextPrincipal = 0;
      } else {
        nextAccumulated = accumulated - amount;
        if (nextAccumulated < 0) nextAccumulated = 0;
      }

      await txn.insert(
        'debt_payments',
        DebtPaymentModel(
          id: null,
          debtId: debtId,
          amount: amount,
          type: type,
          date: date,
        ).toMap(),
      );

      await txn.update(
        'debts',
        {
          'principal_amount': nextPrincipal,
          'accumulated_interest': nextAccumulated,
          'total_amount': nextPrincipal + nextAccumulated,
          'paid_amount': nextPaid,
        },
        where: 'id = ?',
        whereArgs: [debtId],
      );

      nextTotalDebt = nextPrincipal + nextAccumulated;
    });

    final name = (customerName ?? '').trim();
    final total = nextTotalDebt ?? 0;
    if (name.isEmpty) return;

    if (total <= 0) {
      await NotificationService.instance.cancelPendingDebtNotification(debtId);
      await NotificationService.instance.cancelDebtReminder(debtId);
      return;
    }
    await NotificationService.instance.ensureDailyPendingDebtNotification(
      debtId: debtId,
      customerName: name,
      pendingAmount: total,
      hour: 9,
      minute: 0,
    );
  }

  Future<void> updateInterestRate({
    required String debtId,
    required double interestRate,
  }) async {
    final db = await _database.database;
    await db.update(
      'debts',
      {'interest_rate': interestRate},
      where: 'id = ?',
      whereArgs: [debtId],
    );
  }
}
