import 'package:app/src/features/debts/data/models/collection_action_model.dart';
import 'package:app/src/features/debts/data/models/payment_receipt_model.dart';
import 'package:app/src/features/debts/data/models/receivable_model.dart';
import 'package:app/src/features/debts/data/models/receivable_transaction_model.dart';

abstract class ReceivableLocalDataSource {
  Future<void> upsertCustomer({
    required String customerId,
    required String name,
    required String normalizedName,
    DateTime? now,
  });
  Future<void> createReceivable(ReceivableModel receivable);
  Future<List<ReceivableModel>> getReceivables({String? statusFilter});
  Future<ReceivableModel?> getReceivableById(String receivableId);
  Future<List<ReceivableModel>> getCustomerReceivables(String customerId);

  Future<List<ReceivableTransactionModel>> getLedger(String receivableId);
  Future<List<CollectionActionModel>> getCollectionActions(String receivableId);

  Future<void> insertTransaction(ReceivableTransactionModel transaction);
  Future<void> insertTransactions(
    List<ReceivableTransactionModel> transactions,
  );

  Future<void> insertReceipt(PaymentReceiptModel receipt);
  Future<PaymentReceiptModel?> getReceiptById(String receiptId);
  Future<void> markReceiptReversed({
    required String receiptId,
    required DateTime reversedAt,
    required String reason,
  });

  Future<void> insertCollectionAction(CollectionActionModel action);

  Future<void> updateReceivableStatus({
    required String receivableId,
    required String status,
    required DateTime updatedAt,
    DateTime? closedAt,
  });

  Future<Map<String, Object?>> getBalances(
    String receivableId, {
    DateTime? now,
  });
  Future<Map<String, Object?>> getPortfolioSummary({DateTime? now});

  Future<List<Map<String, Object?>>> getTopCustomers({int limit = 5});
}
