import 'package:app/src/features/debts/domain/entities/receivable.dart';

class ReceivableBalances {
  const ReceivableBalances({
    required this.principalPending,
    required this.interestPending,
    required this.interestPendingCurrent,
    required this.interestPendingOverdue,
    required this.totalPending,
    required this.lastPaymentAt,
    required this.nextInterestAt,
    required this.daysOverdue,
    required this.isOverdue,
  });

  final double principalPending;
  final double interestPending;
  final double interestPendingCurrent;
  final double interestPendingOverdue;
  final double totalPending;
  final DateTime? lastPaymentAt;
  final DateTime? nextInterestAt;
  final int daysOverdue;
  final bool isOverdue;
}

class ReceivableDetail {
  const ReceivableDetail({required this.receivable, required this.balances});

  final Receivable receivable;
  final ReceivableBalances balances;

  bool get isPaid => receivable.isPaid || balances.totalPending <= 0.005;

  bool get canRegisterPayment =>
      !receivable.isClosedForPayments && balances.totalPending > 0.005;
}
