import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';

class ReceivableTransactionModel {
  const ReceivableTransactionModel({
    required this.id,
    required this.receivableId,
    required this.type,
    required this.amount,
    required this.occurredAt,
    required this.createdAt,
    required this.receiptId,
    required this.relatedTransactionId,
    required this.note,
    required this.periodStart,
    required this.periodEnd,
    required this.rate,
    required this.baseAmount,
    required this.generatedAmount,
  });

  final int? id;
  final String receivableId;
  final String type;
  final double amount;
  final DateTime occurredAt;
  final DateTime createdAt;
  final String? receiptId;
  final int? relatedTransactionId;
  final String? note;
  final DateTime? periodStart;
  final DateTime? periodEnd;
  final double? rate;
  final double? baseAmount;
  final double? generatedAmount;

  factory ReceivableTransactionModel.fromMap(Map<String, Object?> map) {
    return ReceivableTransactionModel(
      id: map['id'] as int?,
      receivableId: map['receivable_id'] as String,
      type: map['type'] as String,
      amount: (map['amount'] as num).toDouble(),
      occurredAt: DateTime.parse(map['occurred_at'] as String),
      createdAt: DateTime.parse(map['created_at'] as String),
      receiptId: map['receipt_id'] as String?,
      relatedTransactionId: map['related_transaction_id'] as int?,
      note: map['note'] as String?,
      periodStart: map['period_start'] == null
          ? null
          : DateTime.parse(map['period_start'] as String),
      periodEnd: map['period_end'] == null
          ? null
          : DateTime.parse(map['period_end'] as String),
      rate: (map['rate'] as num?)?.toDouble(),
      baseAmount: (map['base_amount'] as num?)?.toDouble(),
      generatedAmount: (map['generated_amount'] as num?)?.toDouble(),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'receivable_id': receivableId,
      'type': type,
      'amount': amount,
      'occurred_at': occurredAt.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'receipt_id': receiptId,
      'related_transaction_id': relatedTransactionId,
      'note': note,
      'period_start': periodStart?.toIso8601String(),
      'period_end': periodEnd?.toIso8601String(),
      'rate': rate,
      'base_amount': baseAmount,
      'generated_amount': generatedAmount,
    };
  }

  ReceivableTransaction toEntity() {
    return ReceivableTransaction(
      id: id,
      receivableId: receivableId,
      type: type,
      amount: amount,
      occurredAt: occurredAt,
      createdAt: createdAt,
      receiptId: receiptId,
      relatedTransactionId: relatedTransactionId,
      note: note,
      periodStart: periodStart,
      periodEnd: periodEnd,
      rate: rate,
      baseAmount: baseAmount,
      generatedAmount: generatedAmount,
    );
  }
}
