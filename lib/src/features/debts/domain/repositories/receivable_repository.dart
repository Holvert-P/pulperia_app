import 'package:app/src/features/debts/domain/entities/collection_action.dart';
import 'package:app/src/features/debts/domain/entities/portfolio_summary.dart';
import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';

class RegisterPaymentRequest {
  const RegisterPaymentRequest({
    required this.receivableId,
    required this.totalAmount,
    required this.paidAt,
    required this.mode,
    required this.principalAmount,
    required this.interestAmount,
    required this.note,
  });

  final String receivableId;
  final double totalAmount;
  final DateTime paidAt;
  final String mode;
  final double? principalAmount;
  final double? interestAmount;
  final String? note;
}

abstract class ReceivableRepository {
  Future<void> createReceivableFromCreditSale({
    required String customerName,
    required double principalAmount,
    required DateTime dueDate,
    required double monthlyRate,
    required int generationCycleDays,
    required bool appliesOnOverdueOnly,
    required bool compoundInterest,
  });

  Future<List<ReceivableDetail>> getCustomerReceivables(String customerId);
  Future<ReceivableDetail?> getReceivableDetail(String receivableId);
  Future<List<ReceivableTransaction>> getReceivableLedger(String receivableId);
  Future<List<CollectionAction>> getCollectionActions(String receivableId);

  Future<void> registerReceivablePayment(RegisterPaymentRequest request);
  Future<void> reverseReceivablePayment({
    required String receiptId,
    required String reason,
    required DateTime reversedAt,
  });

  Future<int> generateReceivableInterest({
    required String receivableId,
    DateTime? now,
  });

  Future<void> registerCollectionAction({
    required String receivableId,
    required String type,
    required String note,
    required DateTime actionAt,
  });

  Future<PortfolioSummary> getPortfolioSummary({DateTime? now});
  Future<List<ReceivableDetail>> getReceivables({String? statusFilter});
}
