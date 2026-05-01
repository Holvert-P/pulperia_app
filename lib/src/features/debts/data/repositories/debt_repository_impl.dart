import 'package:app/src/features/debts/data/datasources/debt_local_datasource.dart';
import 'package:app/src/features/debts/data/models/debt_model.dart';
import 'package:app/src/features/debts/domain/entities/debt.dart';
import 'package:app/src/features/debts/domain/entities/debt_interest_entry.dart';
import 'package:app/src/features/debts/domain/entities/debt_payment.dart';
import 'package:app/src/features/debts/domain/repositories/debt_repository.dart';

class DebtRepositoryImpl implements DebtRepository {
  DebtRepositoryImpl({DebtLocalDataSource? localDataSource})
    : _localDataSource = localDataSource ?? DebtLocalDataSource();

  final DebtLocalDataSource _localDataSource;

  @override
  Future<void> createDebt(Debt debt) async {
    final model = DebtModel.fromEntity(debt);
    await _localDataSource.createDebt(model);
  }

  @override
  Future<Debt?> getDebtById(String id) async {
    final model = await _localDataSource.getDebtById(id);
    return model?.toEntity();
  }

  @override
  Future<List<Debt>> getDebts() async {
    final models = await _localDataSource.getDebts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DebtPayment>> getDebtPayments(String debtId) async {
    final models = await _localDataSource.getDebtPayments(debtId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<DebtInterestEntry>> getDebtInterestHistory(String debtId) async {
    final models = await _localDataSource.getDebtInterestHistory(debtId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> addPayment({
    required String debtId,
    required double amount,
    required String type,
    required DateTime date,
  }) async {
    await _localDataSource.addPayment(
      debtId: debtId,
      amount: amount,
      type: type,
      date: date,
    );
  }

  @override
  Future<void> updateInterestRate({
    required String debtId,
    required double interestRate,
  }) async {
    await _localDataSource.updateInterestRate(
      debtId: debtId,
      interestRate: interestRate,
    );
  }
}
