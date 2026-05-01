import 'package:app/src/features/debts/domain/entities/debt_payment.dart';

class DebtPaymentModel {
  const DebtPaymentModel({
    required this.id,
    required this.debtId,
    required this.amount,
    required this.type,
    required this.date,
  });

  final int? id;
  final String debtId;
  final double amount;
  final String type;
  final DateTime date;

  factory DebtPaymentModel.fromMap(Map<String, Object?> map) {
    return DebtPaymentModel(
      id: map['id'] as int?,
      debtId: map['debt_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      type: map['type'] as String,
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  DebtPayment toEntity() {
    return DebtPayment(
      id: id,
      debtId: debtId,
      amount: amount,
      type: type,
      date: date,
    );
  }
}
