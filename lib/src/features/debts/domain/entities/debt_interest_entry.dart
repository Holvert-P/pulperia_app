class DebtInterestEntry {
  const DebtInterestEntry({
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
}
