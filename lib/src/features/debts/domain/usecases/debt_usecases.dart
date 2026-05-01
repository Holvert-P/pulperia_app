import 'package:app/src/features/debts/domain/entities/debt.dart';
import 'package:app/src/features/debts/domain/entities/debt_interest_entry.dart';
import 'package:app/src/features/debts/domain/entities/debt_payment.dart';
import 'package:app/src/features/debts/domain/repositories/debt_repository.dart';

class GetDebts {
  const GetDebts(this._repository);

  final DebtRepository _repository;

  Future<List<Debt>> call() => _repository.getDebts();
}

class GetDebtById {
  const GetDebtById(this._repository);

  final DebtRepository _repository;

  Future<Debt?> call(String id) => _repository.getDebtById(id);
}

class GetDebtPayments {
  const GetDebtPayments(this._repository);

  final DebtRepository _repository;

  Future<List<DebtPayment>> call(String debtId) =>
      _repository.getDebtPayments(debtId);
}

class GetDebtInterestHistory {
  const GetDebtInterestHistory(this._repository);

  final DebtRepository _repository;

  Future<List<DebtInterestEntry>> call(String debtId) =>
      _repository.getDebtInterestHistory(debtId);
}

class CreateDebt {
  const CreateDebt(this._repository);

  final DebtRepository _repository;

  Future<void> call(Debt debt) => _repository.createDebt(debt);
}

class AddDebtPayment {
  const AddDebtPayment(this._repository);

  final DebtRepository _repository;

  Future<void> call({
    required String debtId,
    required double amount,
    required String type,
    required DateTime date,
  }) => _repository.addPayment(
    debtId: debtId,
    amount: amount,
    type: type,
    date: date,
  );
}

class UpdateDebtInterestRate {
  const UpdateDebtInterestRate(this._repository);

  final DebtRepository _repository;

  Future<void> call({required String debtId, required double interestRate}) =>
      _repository.updateInterestRate(
        debtId: debtId,
        interestRate: interestRate,
      );
}
