import 'package:app/src/features/debts/domain/entities/collection_action.dart';
import 'package:app/src/features/debts/domain/entities/portfolio_summary.dart';
import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';
import 'package:app/src/features/debts/domain/repositories/receivable_repository.dart';

class CreateReceivableFromCreditSale {
  const CreateReceivableFromCreditSale(this._repository);

  final ReceivableRepository _repository;

  Future<void> call({
    required String customerName,
    required double principalAmount,
    required DateTime dueDate,
    required double monthlyRate,
    required int generationCycleDays,
    required bool appliesOnOverdueOnly,
    required bool compoundInterest,
  }) {
    return _repository.createReceivableFromCreditSale(
      customerName: customerName,
      principalAmount: principalAmount,
      dueDate: dueDate,
      monthlyRate: monthlyRate,
      generationCycleDays: generationCycleDays,
      appliesOnOverdueOnly: appliesOnOverdueOnly,
      compoundInterest: compoundInterest,
    );
  }
}

class GetReceivables {
  const GetReceivables(this._repository);

  final ReceivableRepository _repository;

  Future<List<ReceivableDetail>> call({String? statusFilter}) =>
      _repository.getReceivables(statusFilter: statusFilter);
}

class GetCustomerReceivables {
  const GetCustomerReceivables(this._repository);

  final ReceivableRepository _repository;

  Future<List<ReceivableDetail>> call(String customerId) =>
      _repository.getCustomerReceivables(customerId);
}

class GetReceivableDetail {
  const GetReceivableDetail(this._repository);

  final ReceivableRepository _repository;

  Future<ReceivableDetail?> call(String receivableId) =>
      _repository.getReceivableDetail(receivableId);
}

class GetReceivableLedger {
  const GetReceivableLedger(this._repository);

  final ReceivableRepository _repository;

  Future<List<ReceivableTransaction>> call(String receivableId) =>
      _repository.getReceivableLedger(receivableId);
}

class RegisterReceivablePayment {
  const RegisterReceivablePayment(this._repository);

  final ReceivableRepository _repository;

  Future<void> call(RegisterPaymentRequest request) =>
      _repository.registerReceivablePayment(request);
}

class GenerateReceivableInterest {
  const GenerateReceivableInterest(this._repository);

  final ReceivableRepository _repository;

  Future<int> call({required String receivableId, DateTime? now}) =>
      _repository.generateReceivableInterest(receivableId: receivableId, now: now);
}

class ReverseReceivablePayment {
  const ReverseReceivablePayment(this._repository);

  final ReceivableRepository _repository;

  Future<void> call({
    required String receiptId,
    required String reason,
    required DateTime reversedAt,
  }) =>
      _repository.reverseReceivablePayment(
        receiptId: receiptId,
        reason: reason,
        reversedAt: reversedAt,
      );
}

class RegisterCollectionAction {
  const RegisterCollectionAction(this._repository);

  final ReceivableRepository _repository;

  Future<void> call({
    required String receivableId,
    required String type,
    required String note,
    required DateTime actionAt,
  }) =>
      _repository.registerCollectionAction(
        receivableId: receivableId,
        type: type,
        note: note,
        actionAt: actionAt,
      );
}

class GetCollectionActions {
  const GetCollectionActions(this._repository);

  final ReceivableRepository _repository;

  Future<List<CollectionAction>> call(String receivableId) =>
      _repository.getCollectionActions(receivableId);
}

class GetPortfolioSummary {
  const GetPortfolioSummary(this._repository);

  final ReceivableRepository _repository;

  Future<PortfolioSummary> call({DateTime? now}) =>
      _repository.getPortfolioSummary(now: now);
}

