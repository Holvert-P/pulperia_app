class DebtPayment {
  const DebtPayment({
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
}
