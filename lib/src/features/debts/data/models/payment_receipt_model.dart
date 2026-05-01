class PaymentReceiptModel {
  const PaymentReceiptModel({
    required this.id,
    required this.receivableId,
    required this.totalAmount,
    required this.paidAt,
    required this.method,
    required this.note,
    required this.createdAt,
    required this.reversedAt,
    required this.reversedReason,
  });

  final String id;
  final String receivableId;
  final double totalAmount;
  final DateTime paidAt;
  final String? method;
  final String? note;
  final DateTime createdAt;
  final DateTime? reversedAt;
  final String? reversedReason;

  factory PaymentReceiptModel.fromMap(Map<String, Object?> map) {
    return PaymentReceiptModel(
      id: map['id'] as String,
      receivableId: map['receivable_id'] as String,
      totalAmount: (map['total_amount'] as num).toDouble(),
      paidAt: DateTime.parse(map['paid_at'] as String),
      method: map['method'] as String?,
      note: map['note'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      reversedAt: map['reversed_at'] == null
          ? null
          : DateTime.parse(map['reversed_at'] as String),
      reversedReason: map['reversed_reason'] as String?,
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'receivable_id': receivableId,
      'total_amount': totalAmount,
      'paid_at': paidAt.toIso8601String(),
      'method': method,
      'note': note,
      'created_at': createdAt.toIso8601String(),
      'reversed_at': reversedAt?.toIso8601String(),
      'reversed_reason': reversedReason,
    };
  }
}

