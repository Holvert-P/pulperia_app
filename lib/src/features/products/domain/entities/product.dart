class Product {
  const Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.normalizedName,
    required this.brand,
    required this.category,
    required this.subcategory,
    required this.unitOfMeasure,
    required this.barcode,
    required this.costPrice,
    required this.costPriceWithoutVat,
    required this.salePrice,
    required this.marginAmount,
    required this.marginPercent,
    required this.currency,
    required this.taxType,
    required this.vatRateApplied,
    required this.vatAmountOnCost,
    required this.stock,
    required this.minStock,
    required this.isActive,
    required this.allowDecimalQuantity,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String sku;
  final String name;
  final String normalizedName;
  final String? brand;
  final String category;
  final String? subcategory;
  final String unitOfMeasure;
  final String? barcode;
  final double costPrice;
  final double costPriceWithoutVat;
  final double salePrice;
  final double marginAmount;
  final double marginPercent;
  final String currency;
  final String taxType;
  final double vatRateApplied;
  final double vatAmountOnCost;
  final double stock;
  final double minStock;
  final bool isActive;
  final bool allowDecimalQuantity;
  final DateTime createdAt;
  final DateTime updatedAt;

  Product copyWith({
    String? id,
    String? sku,
    String? name,
    String? normalizedName,
    String? brand,
    String? category,
    String? subcategory,
    String? unitOfMeasure,
    String? barcode,
    double? costPrice,
    double? costPriceWithoutVat,
    double? salePrice,
    double? marginAmount,
    double? marginPercent,
    String? currency,
    String? taxType,
    double? vatRateApplied,
    double? vatAmountOnCost,
    double? stock,
    double? minStock,
    bool? isActive,
    bool? allowDecimalQuantity,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Product(
      id: id ?? this.id,
      sku: sku ?? this.sku,
      name: name ?? this.name,
      normalizedName: normalizedName ?? this.normalizedName,
      brand: brand ?? this.brand,
      category: category ?? this.category,
      subcategory: subcategory ?? this.subcategory,
      unitOfMeasure: unitOfMeasure ?? this.unitOfMeasure,
      barcode: barcode ?? this.barcode,
      costPrice: costPrice ?? this.costPrice,
      costPriceWithoutVat: costPriceWithoutVat ?? this.costPriceWithoutVat,
      salePrice: salePrice ?? this.salePrice,
      marginAmount: marginAmount ?? this.marginAmount,
      marginPercent: marginPercent ?? this.marginPercent,
      currency: currency ?? this.currency,
      taxType: taxType ?? this.taxType,
      vatRateApplied: vatRateApplied ?? this.vatRateApplied,
      vatAmountOnCost: vatAmountOnCost ?? this.vatAmountOnCost,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      isActive: isActive ?? this.isActive,
      allowDecimalQuantity: allowDecimalQuantity ?? this.allowDecimalQuantity,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
