import 'package:app/src/features/debts/domain/entities/debt.dart';
import 'package:app/src/features/debts/domain/entities/debt_interest_entry.dart';
import 'package:app/src/features/debts/domain/entities/debt_payment.dart';

abstract class DebtRepository {
  Future<void> createDebt(Debt debt);
  Future<List<Debt>> getDebts();
  Future<Debt?> getDebtById(String id);
  Future<List<DebtPayment>> getDebtPayments(String debtId);
  Future<List<DebtInterestEntry>> getDebtInterestHistory(String debtId);
  Future<void> addPayment({
    required String debtId,
    required double amount,
    required String type,
    required DateTime date,
  });
  Future<void> updateInterestRate({
    required String debtId,
    required double interestRate,
  });
}
