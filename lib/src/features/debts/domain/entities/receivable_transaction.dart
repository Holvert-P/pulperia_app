class ReceivableTransaction {
  const ReceivableTransaction({
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
}
