import 'package:app/src/features/products/domain/entities/price_history_entry.dart';

class ProductPriceHistoryModel {
  const ProductPriceHistoryModel({
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

  factory ProductPriceHistoryModel.fromMap(Map<String, Object?> map) {
    return ProductPriceHistoryModel(
      id: map['id'] as int?,
      productId: map['product_id'] as String,
      costPrice: (map['cost_price'] as num).toDouble(),
      salePrice: (map['sale_price'] as num?)?.toDouble(),
      vatRateApplied: (map['vat_rate_applied'] as num?)?.toDouble(),
      taxType: map['tax_type'] as String?,
      recordedAt: DateTime.parse(map['recorded_at'] as String),
    );
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'product_id': productId,
      'cost_price': costPrice,
      'sale_price': salePrice,
      'vat_rate_applied': vatRateApplied,
      'tax_type': taxType,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }

  PriceHistoryEntry toEntity() {
    return PriceHistoryEntry(
      id: id,
      productId: productId,
      costPrice: costPrice,
      salePrice: salePrice,
      vatRateApplied: vatRateApplied,
      taxType: taxType,
      recordedAt: recordedAt,
    );
  }

  factory ProductPriceHistoryModel.fromEntity(PriceHistoryEntry entry) {
    return ProductPriceHistoryModel(
      id: entry.id,
      productId: entry.productId,
      costPrice: entry.costPrice,
      salePrice: entry.salePrice,
      vatRateApplied: entry.vatRateApplied,
      taxType: entry.taxType,
      recordedAt: entry.recordedAt,
    );
  }
}
