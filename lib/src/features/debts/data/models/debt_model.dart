import 'package:app/src/features/debts/domain/entities/debt.dart';

class DebtModel {
  const DebtModel({
    required this.id,
    required this.customerName,
    required this.principalAmount,
    required this.interestRate,
    required this.accumulatedInterest,
    required this.totalAmount,
    required this.paidAmount,
    required this.lastInterestDate,
    required this.createdAt,
  });

  final String id;
  final String customerName;
  final double principalAmount;
  final double interestRate;
  final double accumulatedInterest;
  final double totalAmount;
  final double paidAmount;
  final DateTime lastInterestDate;
  final DateTime createdAt;

  factory DebtModel.fromMap(Map<String, Object?> map) {
    return DebtModel(
      id: map['id'] as String,
      customerName: map['customer_name'] as String,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      interestRate: (map['interest_rate'] as num).toDouble(),
      accumulatedInterest: (map['accumulated_interest'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAmount: (map['paid_amount'] as num).toDouble(),
      lastInterestDate: DateTime.parse(map['last_interest_date'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'customer_name': customerName,
      'principal_amount': principalAmount,
      'interest_rate': interestRate,
      'accumulated_interest': accumulatedInterest,
      'total_amount': totalAmount,
      'paid_amount': paidAmount,
      'last_interest_date': lastInterestDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  Debt toEntity() {
    return Debt(
      id: id,
      customerName: customerName,
      principalAmount: principalAmount,
      interestRate: interestRate,
      accumulatedInterest: accumulatedInterest,
      totalAmount: totalAmount,
      paidAmount: paidAmount,
      lastInterestDate: lastInterestDate,
      createdAt: createdAt,
    );
  }

  factory DebtModel.fromEntity(Debt entity) {
    return DebtModel(
      id: entity.id,
      customerName: entity.customerName,
      principalAmount: entity.principalAmount,
      interestRate: entity.interestRate,
      accumulatedInterest: entity.accumulatedInterest,
      totalAmount: entity.totalAmount,
      paidAmount: entity.paidAmount,
      lastInterestDate: entity.lastInterestDate,
      createdAt: entity.createdAt,
    );
  }
}
