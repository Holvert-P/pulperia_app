import 'package:app/src/core/services/notification_service.dart';
import 'package:app/src/features/debts/data/datasources/receivable_local_datasource.dart';
import 'package:app/src/features/debts/data/datasources/receivable_local_datasource_impl.dart';
import 'package:app/src/features/debts/data/models/collection_action_model.dart';
import 'package:app/src/features/debts/data/models/payment_receipt_model.dart';
import 'package:app/src/features/debts/data/models/receivable_model.dart';
import 'package:app/src/features/debts/data/models/receivable_transaction_model.dart';
import 'package:app/src/features/debts/domain/entities/collection_action.dart';
import 'package:app/src/features/debts/domain/entities/interest_policy.dart';
import 'package:app/src/features/debts/domain/entities/portfolio_summary.dart';
import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';
import 'package:app/src/features/debts/domain/repositories/receivable_repository.dart';
import 'package:sqflite/sqflite.dart';

class ReceivableRepositoryImpl implements ReceivableRepository {
  ReceivableRepositoryImpl({ReceivableLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? ReceivableLocalDataSourceImpl();

  final ReceivableLocalDataSource _localDataSource;

  @override
  Future<void> createReceivableFromCreditSale({
    required String customerName,
    required double principalAmount,
    required DateTime dueDate,
    required double monthlyRate,
    required int generationCycleDays,
    required bool appliesOnOverdueOnly,
    required bool compoundInterest,
  }) async {
    final now = DateTime.now();
    final customer = customerName.trim();
    if (customer.isEmpty) {
      throw ArgumentError('customerName is required');
    }
    if (principalAmount <= 0) {
      throw ArgumentError('principalAmount must be > 0');
    }

    final customerId = _customerIdForName(customer);
    final receivableId = now.microsecondsSinceEpoch.toString();

    await _localDataSource.upsertCustomer(
      customerId: customerId,
      name: customer,
      normalizedName: _normalizeName(customer),
      now: now,
    );

    final receivable = ReceivableModel(
      receivableId: receivableId,
      customerId: customerId,
      customerName: customer,
      saleId: null,
      principalAmount: principalAmount,
      dueDate: dueDate,
      status: 'active',
      interestPolicy: InterestPolicy(
        monthlyRate: monthlyRate,
        generationCycleDays: generationCycleDays,
        appliesOnOverdueOnly: appliesOnOverdueOnly,
        compoundInterest: compoundInterest,
      ),
      createdAt: now,
      updatedAt: now,
      closedAt: null,
    );

    await _localDataSource.createReceivable(receivable);
    await _localDataSource.insertTransaction(
      ReceivableTransactionModel(
        id: null,
        receivableId: receivableId,
        type: 'principal_charge',
        amount: principalAmount,
        occurredAt: now,
        createdAt: now,
        receiptId: null,
        relatedTransactionId: null,
        note: null,
        periodStart: null,
        periodEnd: null,
        rate: null,
        baseAmount: null,
        generatedAmount: null,
      ),
    );
  }

  @override
  Future<List<ReceivableDetail>> getCustomerReceivables(
    String customerId,
  ) async {
    final items = await _localDataSource.getCustomerReceivables(customerId);
    final details = <ReceivableDetail>[];
    for (final r in items) {
      final balances = await _balancesForReceivable(r.receivableId, r.dueDate);
      await _maybeUpdateStatus(
        receivableId: r.receivableId,
        currentStatus: r.status,
        balances: balances,
        dueDate: r.dueDate,
      );
      details.add(
        ReceivableDetail(receivable: r.toEntity(), balances: balances),
      );
    }
    await NotificationService.instance.syncPendingDebtNotifications(
      debts: details
          .map(
            (d) => PendingDebtNotificationData(
              debtId: d.receivable.receivableId,
              customerName: d.receivable.customerName,
              pendingAmount: d.balances.totalPending,
              isPaid: d.balances.totalPending <= 0.005,
            ),
          )
          .toList(),
      hour: 9,
      minute: 0,
    );
    return details;
  }

  @override
  Future<List<ReceivableDetail>> getReceivables({String? statusFilter}) async {
    final items = await _localDataSource.getReceivables(
      statusFilter: statusFilter,
    );
    final details = <ReceivableDetail>[];
    for (final r in items) {
      final balances = await _balancesForReceivable(r.receivableId, r.dueDate);
      await _maybeUpdateStatus(
        receivableId: r.receivableId,
        currentStatus: r.status,
        balances: balances,
        dueDate: r.dueDate,
      );
      details.add(
        ReceivableDetail(receivable: r.toEntity(), balances: balances),
      );
    }
    await NotificationService.instance.syncPendingDebtNotifications(
      debts: details
          .map(
            (d) => PendingDebtNotificationData(
              debtId: d.receivable.receivableId,
              customerName: d.receivable.customerName,
              pendingAmount: d.balances.totalPending,
              isPaid: d.balances.totalPending <= 0.005,
            ),
          )
          .toList(),
      hour: 9,
      minute: 0,
    );
    return details;
  }

  @override
  Future<ReceivableDetail?> getReceivableDetail(String receivableId) async {
    final model = await _localDataSource.getReceivableById(receivableId);
    if (model == null) return null;
    final balances = await _balancesForReceivable(
      model.receivableId,
      model.dueDate,
    );
    await _maybeUpdateStatus(
      receivableId: model.receivableId,
      currentStatus: model.status,
      balances: balances,
      dueDate: model.dueDate,
    );
    return ReceivableDetail(receivable: model.toEntity(), balances: balances);
  }

  @override
  Future<List<ReceivableTransaction>> getReceivableLedger(
    String receivableId,
  ) async {
    final models = await _localDataSource.getLedger(receivableId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<CollectionAction>> getCollectionActions(
    String receivableId,
  ) async {
    final models = await _localDataSource.getCollectionActions(receivableId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> registerReceivablePayment(RegisterPaymentRequest request) async {
    final now = DateTime.now();
    if (request.totalAmount <= 0) {
      throw ArgumentError('totalAmount must be > 0');
    }
    final detail = await getReceivableDetail(request.receivableId);
    if (detail == null) {
      throw StateError('Receivable not found');
    }
    if (!detail.canRegisterPayment) {
      throw StateError('La cuenta está cerrada o ya está saldada');
    }

    final balances = detail.balances;
    if (request.totalAmount > balances.totalPending + 0.001) {
      throw ArgumentError('El pago no puede exceder el saldo pendiente');
    }

    final allocation = _allocatePayment(
      mode: request.mode,
      totalAmount: request.totalAmount,
      principalPending: balances.principalPending,
      interestPendingOverdue: balances.interestPendingOverdue,
      interestPendingCurrent: balances.interestPendingCurrent,
      principalManual: request.principalAmount,
      interestManual: request.interestAmount,
    );

    final interestOverduePaid = allocation.interestAmountOverdue;
    final interestCurrentPaid = allocation.interestAmountCurrent;
    final principalPaid = allocation.principalAmount;

    final allocatedTotal =
        interestOverduePaid + interestCurrentPaid + principalPaid;
    if (allocatedTotal <= 0.005) {
      throw StateError('No hay saldo aplicable para registrar este pago');
    }

    final receiptId = now.microsecondsSinceEpoch.toString();
    await _localDataSource.insertReceipt(
      PaymentReceiptModel(
        id: receiptId,
        receivableId: request.receivableId,
        totalAmount: request.totalAmount,
        paidAt: request.paidAt,
        method: null,
        note: request.note,
        createdAt: now,
        reversedAt: null,
        reversedReason: null,
      ),
    );

    final txns = <ReceivableTransactionModel>[
      if (interestOverduePaid > 0)
        ReceivableTransactionModel(
          id: null,
          receivableId: request.receivableId,
          type: 'payment_interest_overdue',
          amount: interestOverduePaid,
          occurredAt: request.paidAt,
          createdAt: now,
          receiptId: receiptId,
          relatedTransactionId: null,
          note: request.note,
          periodStart: null,
          periodEnd: null,
          rate: null,
          baseAmount: null,
          generatedAmount: null,
        ),
      if (interestCurrentPaid > 0)
        ReceivableTransactionModel(
          id: null,
          receivableId: request.receivableId,
          type: 'payment_interest_current',
          amount: interestCurrentPaid,
          occurredAt: request.paidAt,
          createdAt: now,
          receiptId: receiptId,
          relatedTransactionId: null,
          note: request.note,
          periodStart: null,
          periodEnd: null,
          rate: null,
          baseAmount: null,
          generatedAmount: null,
        ),
      if (principalPaid > 0)
        ReceivableTransactionModel(
          id: null,
          receivableId: request.receivableId,
          type: 'payment_principal',
          amount: principalPaid,
          occurredAt: request.paidAt,
          createdAt: now,
          receiptId: receiptId,
          relatedTransactionId: null,
          note: request.note,
          periodStart: null,
          periodEnd: null,
          rate: null,
          baseAmount: null,
          generatedAmount: null,
        ),
    ];

    await _localDataSource.insertTransactions(txns);
    await _maybeCloseIfPaid(receivableId: request.receivableId);
  }

  @override
  Future<void> reverseReceivablePayment({
    required String receiptId,
    required String reason,
    required DateTime reversedAt,
  }) async {
    final receipt = await _localDataSource.getReceiptById(receiptId);
    if (receipt == null) {
      throw StateError('Receipt not found');
    }
    if (receipt.reversedAt != null) {
      throw StateError('Receipt already reversed');
    }
    if (reason.trim().isEmpty) {
      throw ArgumentError('reason is required');
    }

    final now = DateTime.now();
    final ledger = await _localDataSource.getLedger(receipt.receivableId);
    final related = ledger.where((t) => t.receiptId == receiptId).toList();
    final reversalTxns = <ReceivableTransactionModel>[];
    for (final t in related) {
      if (t.type == 'payment_principal') {
        reversalTxns.add(
          ReceivableTransactionModel(
            id: null,
            receivableId: t.receivableId,
            type: 'reversal_payment_principal',
            amount: t.amount,
            occurredAt: reversedAt,
            createdAt: now,
            receiptId: receiptId,
            relatedTransactionId: t.id,
            note: reason,
            periodStart: null,
            periodEnd: null,
            rate: null,
            baseAmount: null,
            generatedAmount: null,
          ),
        );
      }
      if (t.type == 'payment_interest' ||
          t.type == 'payment_interest_current' ||
          t.type == 'payment_interest_overdue') {
        final reversalType = switch (t.type) {
          'payment_interest_current' => 'reversal_payment_interest_current',
          'payment_interest_overdue' => 'reversal_payment_interest_overdue',
          _ => 'reversal_payment_interest',
        };
        reversalTxns.add(
          ReceivableTransactionModel(
            id: null,
            receivableId: t.receivableId,
            type: reversalType,
            amount: t.amount,
            occurredAt: reversedAt,
            createdAt: now,
            receiptId: receiptId,
            relatedTransactionId: t.id,
            note: reason,
            periodStart: null,
            periodEnd: null,
            rate: null,
            baseAmount: null,
            generatedAmount: null,
          ),
        );
      }
    }

    await _localDataSource.markReceiptReversed(
      receiptId: receiptId,
      reversedAt: reversedAt,
      reason: reason,
    );
    if (reversalTxns.isNotEmpty) {
      await _localDataSource.insertTransactions(reversalTxns);
    }
    await _maybeReopenIfNeeded(receivableId: receipt.receivableId);
  }

  @override
  Future<int> generateReceivableInterest({
    required String receivableId,
    DateTime? now,
  }) async {
    final currentNow = now ?? DateTime.now();
    final detail = await getReceivableDetail(receivableId);
    if (detail == null) return 0;

    final receivable = detail.receivable;
    final balances = detail.balances;
    if (balances.totalPending <= 0) return 0;
    if (receivable.status == 'paid' ||
        receivable.status == 'cancelled' ||
        receivable.status == 'refinanced' ||
        receivable.status == 'frozen') {
      return 0;
    }

    final policy = receivable.interestPolicy;
    if (policy.monthlyRate <= 0) return 0;
    if (policy.generationCycleDays <= 0) return 0;

    if (policy.appliesOnOverdueOnly &&
        currentNow.isBefore(receivable.dueDate)) {
      return 0;
    }

    final ledger = await getReceivableLedger(receivableId);
    final interestCharges =
        ledger
            .where((t) => t.type == 'interest_charge' && t.periodEnd != null)
            .toList()
          ..sort((a, b) => a.periodEnd!.compareTo(b.periodEnd!));

    DateTime start = receivable.createdAt;
    if (interestCharges.isNotEmpty) {
      start = interestCharges.last.periodEnd!;
    }
    if (policy.appliesOnOverdueOnly && start.isBefore(receivable.dueDate)) {
      start = receivable.dueDate;
    }

    var generatedCount = 0;
    var periodStart = start;
    var runningPrincipal = balances.principalPending;
    var runningInterest = balances.interestPending;
    while (currentNow.difference(periodStart).inDays >=
        policy.generationCycleDays) {
      final periodEnd = periodStart.add(
        Duration(days: policy.generationCycleDays),
      );
      final baseAmount = policy.compoundInterest
          ? (runningPrincipal + runningInterest)
          : runningPrincipal;
      final periodRate =
          policy.monthlyRate * (policy.generationCycleDays / 30.0);
      final interest = (baseAmount * periodRate);
      final rounded = double.parse(interest.toStringAsFixed(2));
      if (rounded > 0) {
        try {
          await _localDataSource.insertTransaction(
            ReceivableTransactionModel(
              id: null,
              receivableId: receivableId,
              type: 'interest_charge',
              amount: rounded,
              occurredAt: periodEnd,
              createdAt: DateTime.now(),
              receiptId: null,
              relatedTransactionId: null,
              note: null,
              periodStart: periodStart,
              periodEnd: periodEnd,
              rate: policy.monthlyRate,
              baseAmount: baseAmount,
              generatedAmount: rounded,
            ),
          );
          generatedCount += 1;
          runningInterest += rounded;
        } on DatabaseException catch (e) {
          final msg = e.toString().toLowerCase();
          if (msg.contains('unique') || msg.contains('constraint')) {
          } else {
            rethrow;
          }
        }
      }
      periodStart = periodEnd;
    }

    if (generatedCount > 0) {
      await _maybeCloseIfPaid(receivableId: receivableId);
      await _maybeUpdateStatus(
        receivableId: receivableId,
        currentStatus: receivable.status,
        balances: await _balancesForReceivable(
          receivableId,
          receivable.dueDate,
        ),
        dueDate: receivable.dueDate,
      );
    }
    return generatedCount;
  }

  @override
  Future<void> registerCollectionAction({
    required String receivableId,
    required String type,
    required String note,
    required DateTime actionAt,
  }) async {
    final now = DateTime.now();
    if (type.trim().isEmpty) throw ArgumentError('type is required');
    await _localDataSource.insertCollectionAction(
      CollectionActionModel(
        id: null,
        receivableId: receivableId,
        type: type.trim(),
        note: note.trim().isEmpty ? null : note.trim(),
        actionAt: actionAt,
        createdAt: now,
      ),
    );
  }

  @override
  Future<PortfolioSummary> getPortfolioSummary({DateTime? now}) async {
    final raw = await _localDataSource.getPortfolioSummary(now: now);
    final totalPortfolio = (raw['total_portfolio'] as num?)?.toDouble() ?? 0.0;
    final totalPrincipalPending =
        (raw['total_principal_pending'] as num?)?.toDouble() ?? 0.0;
    final totalInterestPending =
        (raw['total_interest_pending'] as num?)?.toDouble() ?? 0.0;
    final collectedToday = (raw['collected_today'] as num?)?.toDouble() ?? 0.0;
    final collectedThisMonth =
        (raw['collected_this_month'] as num?)?.toDouble() ?? 0.0;
    final overdueCount = (raw['overdue_count'] as num?)?.toInt() ?? 0;

    final aging = <PortfolioAgingBucket>[
      PortfolioAgingBucket(
        label: '0-30',
        fromDays: 0,
        toDays: 30,
        totalAmount: (raw['aging_0_30_total'] as num?)?.toDouble() ?? 0.0,
        count: (raw['aging_0_30_count'] as num?)?.toInt() ?? 0,
      ),
      PortfolioAgingBucket(
        label: '31-60',
        fromDays: 31,
        toDays: 60,
        totalAmount: (raw['aging_31_60_total'] as num?)?.toDouble() ?? 0.0,
        count: (raw['aging_31_60_count'] as num?)?.toInt() ?? 0,
      ),
      PortfolioAgingBucket(
        label: '61-90',
        fromDays: 61,
        toDays: 90,
        totalAmount: (raw['aging_61_90_total'] as num?)?.toDouble() ?? 0.0,
        count: (raw['aging_61_90_count'] as num?)?.toInt() ?? 0,
      ),
      PortfolioAgingBucket(
        label: '91+',
        fromDays: 91,
        toDays: null,
        totalAmount: (raw['aging_91_plus_total'] as num?)?.toDouble() ?? 0.0,
        count: (raw['aging_91_plus_count'] as num?)?.toInt() ?? 0,
      ),
    ];

    final topRows = await _localDataSource.getTopCustomers(limit: 5);
    final topCustomers = topRows
        .map(
          (r) => PortfolioTopCustomer(
            customerId: (r['customer_id'] as String?) ?? '',
            customerName: (r['customer_name'] as String?) ?? '',
            totalPending: (r['total_pending'] as num?)?.toDouble() ?? 0.0,
            receivableCount: (r['receivable_count'] as num?)?.toInt() ?? 0,
          ),
        )
        .where((c) => c.customerId.isNotEmpty)
        .toList();

    return PortfolioSummary(
      totalPortfolio: totalPortfolio,
      totalPrincipalPending: totalPrincipalPending,
      totalInterestPending: totalInterestPending,
      collectedToday: collectedToday,
      collectedThisMonth: collectedThisMonth,
      overdueCount: overdueCount,
      aging: aging,
      topCustomers: topCustomers,
    );
  }

  ReceivableBalances _mapBalances(Map<String, Object?> raw, DateTime dueDate) {
    final principal = (raw['principal_pending'] as num?)?.toDouble() ?? 0.0;
    final interest = (raw['interest_pending'] as num?)?.toDouble() ?? 0.0;
    final interestCurrent =
        (raw['interest_pending_current'] as num?)?.toDouble() ?? 0.0;
    final interestOverdue =
        (raw['interest_pending_overdue'] as num?)?.toDouble() ?? 0.0;
    final lastPaymentAtRaw = raw['last_payment_at'] as String?;
    final lastPaymentAt = lastPaymentAtRaw == null
        ? null
        : DateTime.tryParse(lastPaymentAtRaw);
    final lastInterestPeriodEndRaw = raw['last_interest_period_end'] as String?;
    final lastInterestPeriodEnd = lastInterestPeriodEndRaw == null
        ? null
        : DateTime.tryParse(lastInterestPeriodEndRaw);
    final now = DateTime.now();
    final overdueDays = now.isAfter(dueDate)
        ? now.difference(dueDate).inDays
        : 0;
    final isOverdue = overdueDays > 0;
    final total = principal + interest;

    final unbucketed = (interest - (interestCurrent + interestOverdue));
    final normalizedUnbucketed = unbucketed > 0 ? unbucketed : 0.0;
    final effectiveOverdue = (interestOverdue + normalizedUnbucketed) < 0
        ? 0.0
        : (interestOverdue + normalizedUnbucketed);
    final effectiveCurrent = interestCurrent < 0 ? 0.0 : interestCurrent;

    final nextInterestAt = () {
      final cycleDays = (raw['generation_cycle_days'] as num?)?.toInt();
      if (cycleDays == null || cycleDays <= 0) return null;
      final appliesOverdueOnly =
          ((raw['applies_on_overdue_only'] as num?)?.toInt() ?? 0) == 1;
      final createdAtRaw = raw['created_at'] as String?;
      final createdAt = createdAtRaw == null
          ? null
          : DateTime.tryParse(createdAtRaw);
      DateTime? base = lastInterestPeriodEnd ?? createdAt;
      if (appliesOverdueOnly) {
        if (base == null || base.isBefore(dueDate)) {
          base = dueDate;
        }
      }
      if (base == null) return null;
      return base.add(Duration(days: cycleDays));
    }();

    return ReceivableBalances(
      principalPending: principal < 0 ? 0.0 : principal,
      interestPending: interest < 0 ? 0.0 : interest,
      interestPendingCurrent: effectiveCurrent,
      interestPendingOverdue: effectiveOverdue,
      totalPending: total < 0 ? 0.0 : total,
      lastPaymentAt: lastPaymentAt,
      nextInterestAt: nextInterestAt,
      daysOverdue: overdueDays,
      isOverdue: isOverdue,
    );
  }

  Future<ReceivableBalances> _balancesForReceivable(
    String receivableId,
    DateTime dueDate,
  ) async {
    final raw = await _localDataSource.getBalances(receivableId);
    return _mapBalances(raw, dueDate);
  }

  Future<void> _maybeCloseIfPaid({required String receivableId}) async {
    final detail = await getReceivableDetail(receivableId);
    if (detail == null) return;
    final r = detail.receivable;
    final b = detail.balances;
    if (b.totalPending > 0.005) return;
    if (r.status == 'paid') return;

    await _localDataSource.updateReceivableStatus(
      receivableId: receivableId,
      status: 'paid',
      updatedAt: DateTime.now(),
      closedAt: DateTime.now(),
    );
  }

  Future<void> _maybeReopenIfNeeded({required String receivableId}) async {
    final detail = await getReceivableDetail(receivableId);
    if (detail == null) return;
    final r = detail.receivable;
    final b = detail.balances;
    if (b.totalPending <= 0.005) return;
    if (r.status != 'paid') return;

    final status = b.isOverdue ? 'overdue' : 'active';
    await _localDataSource.updateReceivableStatus(
      receivableId: receivableId,
      status: status,
      updatedAt: DateTime.now(),
      closedAt: null,
    );
  }

  Future<void> _maybeUpdateStatus({
    required String receivableId,
    required String currentStatus,
    required ReceivableBalances balances,
    required DateTime dueDate,
  }) async {
    if (currentStatus == 'paid' ||
        currentStatus == 'cancelled' ||
        currentStatus == 'refinanced' ||
        currentStatus == 'frozen') {
      return;
    }
    if (balances.totalPending <= 0.005) {
      await _localDataSource.updateReceivableStatus(
        receivableId: receivableId,
        status: 'paid',
        updatedAt: DateTime.now(),
        closedAt: DateTime.now(),
      );
      return;
    }

    final desired = balances.isOverdue ? 'overdue' : 'active';
    if (desired == currentStatus) return;
    await _localDataSource.updateReceivableStatus(
      receivableId: receivableId,
      status: desired,
      updatedAt: DateTime.now(),
      closedAt: null,
    );
  }

  String _customerIdForName(String name) {
    final normalized = _normalizeName(name);
    return 'c_${_stableHash(normalized)}';
  }

  String _normalizeName(String name) {
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
    return withoutDiacritics.replaceAll(RegExp(r'[^a-z0-9]+'), '_').trim();
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
}

class _PaymentAllocation {
  const _PaymentAllocation({
    required this.principalAmount,
    required this.interestAmountOverdue,
    required this.interestAmountCurrent,
  });

  final double principalAmount;
  final double interestAmountOverdue;
  final double interestAmountCurrent;
}

_PaymentAllocation _allocatePayment({
  required String mode,
  required double totalAmount,
  required double principalPending,
  required double interestPendingOverdue,
  required double interestPendingCurrent,
  required double? principalManual,
  required double? interestManual,
}) {
  final m = mode.trim().toLowerCase();
  final total = totalAmount;
  final interestTotal = interestPendingOverdue + interestPendingCurrent;

  if (m == 'interest_only') {
    if (total > interestTotal + 0.001) {
      throw ArgumentError('El pago no puede ser mayor al interés pendiente');
    }
    var remaining = total;
    final payOverdue = remaining > interestPendingOverdue
        ? interestPendingOverdue
        : remaining;
    remaining -= payOverdue;
    final payCurrent = remaining > interestPendingCurrent
        ? interestPendingCurrent
        : remaining;
    return _PaymentAllocation(
      principalAmount: 0.0,
      interestAmountOverdue: payOverdue,
      interestAmountCurrent: payCurrent,
    );
  }
  if (m == 'principal_only') {
    if (total > principalPending) {
      throw ArgumentError('El pago no puede ser mayor al capital pendiente');
    }
    return _PaymentAllocation(
      principalAmount: total,
      interestAmountOverdue: 0.0,
      interestAmountCurrent: 0.0,
    );
  }
  if (m == 'mixed_manual') {
    final p = principalManual ?? 0.0;
    final i = interestManual ?? 0.0;
    final sum = p + i;
    if (p < 0 || i < 0) {
      throw ArgumentError('No se permiten pagos negativos');
    }
    if ((sum - total).abs() > 0.001) {
      throw ArgumentError(
        'La suma de capital+interés debe coincidir con el total',
      );
    }
    if (p > principalPending + 0.001) {
      throw ArgumentError('El pago no puede ser mayor al capital pendiente');
    }
    if (i > interestTotal + 0.001) {
      throw ArgumentError('El pago no puede ser mayor al interés pendiente');
    }
    var remainingInterest = i;
    final payOverdue = remainingInterest > interestPendingOverdue
        ? interestPendingOverdue
        : remainingInterest;
    remainingInterest -= payOverdue;
    final payCurrent = remainingInterest > interestPendingCurrent
        ? interestPendingCurrent
        : remainingInterest;
    return _PaymentAllocation(
      principalAmount: p,
      interestAmountOverdue: payOverdue,
      interestAmountCurrent: payCurrent,
    );
  }

  var remaining = total;
  final payOverdueInterest = remaining > interestPendingOverdue
      ? interestPendingOverdue
      : remaining;
  remaining -= payOverdueInterest;
  final payCurrentInterest = remaining > interestPendingCurrent
      ? interestPendingCurrent
      : remaining;
  remaining -= payCurrentInterest;
  final payPrincipal = remaining > principalPending
      ? principalPending
      : remaining;
  return _PaymentAllocation(
    principalAmount: payPrincipal,
    interestAmountOverdue: payOverdueInterest,
    interestAmountCurrent: payCurrentInterest,
  );
}
