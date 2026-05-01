import 'package:app/src/features/debts/domain/entities/debt_interest_entry.dart';

class DebtInterestEntryModel {
  const DebtInterestEntryModel({
    required this.id,
    required this.debtId,
    required this.interestAmount,
    required this.rate,
    required this.date,
  });

  final int? id;
  final String debtId;
  final double interestAmount;
  final double rate;
  final DateTime date;

  factory DebtInterestEntryModel.fromMap(Map<String, Object?> map) {
    return DebtInterestEntryModel(
      id: map['id'] as int?,
      debtId: map['debt_id'] as String,
      interestAmount: (map['interest_amount'] as num).toDouble(),
      rate: (map['rate'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      if (id != null) 'id': id,
      'debt_id': debtId,
      'interest_amount': interestAmount,
      'rate': rate,
      'date': date.toIso8601String(),
    };
  }

  DebtInterestEntry toEntity() {
    return DebtInterestEntry(
      id: id,
      debtId: debtId,
      interestAmount: interestAmount,
      rate: rate,
      date: date,
    );
  }
}
