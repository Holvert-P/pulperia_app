class PortfolioAgingBucket {
  const PortfolioAgingBucket({
    required this.label,
    required this.fromDays,
    required this.toDays,
    required this.totalAmount,
    required this.count,
  });

  final String label;
  final int fromDays;
  final int? toDays;
  final double totalAmount;
  final int count;
}

class PortfolioTopCustomer {
  const PortfolioTopCustomer({
    required this.customerId,
    required this.customerName,
    required this.totalPending,
    required this.receivableCount,
  });

  final String customerId;
  final String customerName;
  final double totalPending;
  final int receivableCount;
}

class PortfolioSummary {
  const PortfolioSummary({
    required this.totalPortfolio,
    required this.totalPrincipalPending,
    required this.totalInterestPending,
    required this.collectedToday,
    required this.collectedThisMonth,
    required this.overdueCount,
    required this.aging,
    required this.topCustomers,
  });

  final double totalPortfolio;
  final double totalPrincipalPending;
  final double totalInterestPending;
  final double collectedToday;
  final double collectedThisMonth;
  final int overdueCount;
  final List<PortfolioAgingBucket> aging;
  final List<PortfolioTopCustomer> topCustomers;
}
