class PriceHistoryEntry {
  const PriceHistoryEntry({
    required this.id,
    required this.productId,
    required this.costPrice,
    required this.salePrice,
    required this.vatRateApplied,
    required this.taxType,
    required this.recordedAt,
  });

  final int? id;
  final String productId;
  final double costPrice;
  final double? salePrice;
  final double? vatRateApplied;
  final String? taxType;
  final DateTime recordedAt;
}
