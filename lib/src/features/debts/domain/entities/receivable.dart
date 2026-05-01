import 'package:app/src/features/debts/domain/entities/interest_policy.dart';

class Receivable {
  const Receivable({
    required this.receivableId,
    required this.customerId,
    required this.customerName,
    required this.saleId,
    required this.principalAmount,
    required this.dueDate,
    required this.status,
    required this.interestPolicy,
    required this.createdAt,
    required this.updatedAt,
    required this.closedAt,
  });

  final String receivableId;
  final String customerId;
  final String customerName;
  final String? saleId;
  final double principalAmount;
  final DateTime dueDate;
  final String status;
  final InterestPolicy interestPolicy;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;

  bool get isPaid => status == 'paid';

  bool get isClosedForPayments =>
      status == 'paid' ||
      status == 'cancelled' ||
      status == 'refinanced' ||
      status == 'frozen';
}
