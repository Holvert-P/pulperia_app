import 'package:app/src/features/debts/domain/entities/interest_policy.dart';
import 'package:app/src/features/debts/domain/entities/receivable.dart';

class ReceivableModel {
  const ReceivableModel({
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

  factory ReceivableModel.fromMap(Map<String, Object?> map) {
    return ReceivableModel(
      receivableId: map['receivable_id'] as String,
      customerId: map['customer_id'] as String,
      customerName: (map['customer_name'] as String?) ?? '',
      saleId: map['sale_id'] as String?,
      principalAmount: (map['principal_amount'] as num).toDouble(),
      dueDate: DateTime.parse(map['due_date'] as String),
      status: map['status'] as String,
      interestPolicy: InterestPolicy(
        monthlyRate: (map['monthly_rate'] as num).toDouble(),
        generationCycleDays: (map['generation_cycle_days'] as num).toInt(),
        appliesOnOverdueOnly:
            ((map['applies_on_overdue_only'] as num).toInt()) == 1,
        compoundInterest: ((map['compound_interest'] as num).toInt()) == 1,
      ),
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      closedAt: map['closed_at'] == null
          ? null
          : DateTime.parse(map['closed_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'receivable_id': receivableId,
      'customer_id': customerId,
      'sale_id': saleId,
      'principal_amount': principalAmount,
      'due_date': dueDate.toIso8601String(),
      'status': status,
      'monthly_rate': interestPolicy.monthlyRate,
      'generation_cycle_days': interestPolicy.generationCycleDays,
      'applies_on_overdue_only': interestPolicy.appliesOnOverdueOnly ? 1 : 0,
      'compound_interest': interestPolicy.compoundInterest ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'closed_at': closedAt?.toIso8601String(),
    };
  }

  Receivable toEntity() {
    return Receivable(
      receivableId: receivableId,
      customerId: customerId,
      customerName: customerName,
      saleId: saleId,
      principalAmount: principalAmount,
      dueDate: dueDate,
      status: status,
      interestPolicy: interestPolicy,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
    );
  }
}
