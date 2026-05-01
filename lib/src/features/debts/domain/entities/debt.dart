class Debt {
  const Debt({
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

  double get remainingCapital => principalAmount;

  double get totalDebt => remainingCapital + accumulatedInterest;

  bool get isPaid => totalDebt <= 0;

  Debt copyWith({
    String? id,
    String? customerName,
    double? principalAmount,
    double? interestRate,
    double? accumulatedInterest,
    double? totalAmount,
    double? paidAmount,
    DateTime? lastInterestDate,
    DateTime? createdAt,
  }) {
    return Debt(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      principalAmount: principalAmount ?? this.principalAmount,
      interestRate: interestRate ?? this.interestRate,
      accumulatedInterest: accumulatedInterest ?? this.accumulatedInterest,
      totalAmount: totalAmount ?? this.totalAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      lastInterestDate: lastInterestDate ?? this.lastInterestDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
