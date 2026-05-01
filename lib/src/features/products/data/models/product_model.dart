import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/services/product_financials.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';

class ProductModel {
  const ProductModel({
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

  factory ProductModel.fromMap(Map<String, Object?> map) {
    final taxType = (map['tax_type'] as String?) ?? 'iva_incluido';
    final vatRateApplied =
        (map['vat_rate_applied'] as num?)?.toDouble() ?? 0.15;
    final costPrice = (map['cost_price'] as num).toDouble();
    final salePrice = (map['sale_price'] as num).toDouble();
    final financials = ProductFinancials.normalize(
      costPrice: costPrice,
      salePrice: salePrice,
      taxType: taxType,
      vatRateApplied: vatRateApplied,
    );

    return ProductModel(
      id: map['id'] as String,
      sku: (map['sku'] as String?) ?? '',
      name: map['name'] as String,
      normalizedName:
          (map['normalized_name'] as String?) ??
          ProductTextNormalizer.normalizeName(map['name'] as String),
      brand: map['brand'] as String?,
      category: map['category'] as String,
      subcategory: map['subcategory'] as String?,
      unitOfMeasure: (map['unit_of_measure'] as String?) ?? 'unidad',
      barcode: map['barcode'] as String?,
      costPrice: costPrice,
      costPriceWithoutVat:
          (map['cost_price_without_vat'] as num?)?.toDouble() ??
          financials.costPriceWithoutVat,
      salePrice: salePrice,
      marginAmount:
          (map['margin_amount'] as num?)?.toDouble() ?? financials.marginAmount,
      marginPercent:
          (map['margin_percent'] as num?)?.toDouble() ??
          financials.marginPercent,
      currency: (map['currency'] as String?) ?? 'NIO',
      taxType: taxType,
      vatRateApplied: vatRateApplied,
      vatAmountOnCost:
          (map['vat_amount_on_cost'] as num?)?.toDouble() ??
          financials.vatAmountOnCost,
      stock: (map['stock'] as num?)?.toDouble() ?? 0,
      minStock: (map['min_stock'] as num?)?.toDouble() ?? 0,
      isActive: ((map['is_active'] as num?)?.toInt() ?? 1) == 1,
      allowDecimalQuantity:
          ((map['allow_decimal_quantity'] as num?)?.toInt() ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  factory ProductModel.fromJson(Map<String, Object?> json) {
    final id = (json['id'] as String?)?.trim() ?? '';
    final name = (json['name'] as String?)?.trim() ?? '';
    final normalizedNameRaw = (json['normalized_name'] as String?)?.trim();
    final brandRaw = (json['brand'] as String?)?.trim();
    final category = ProductTextNormalizer.normalizeCategory(
      (json['category'] as String?)?.trim() ?? 'general',
    );
    final subcategoryRaw = (json['subcategory'] as String?)?.trim();
    final unitRaw = (json['unit_of_measure'] as String?)?.trim();
    final barcodeRaw = (json['barcode'] as String?)?.trim();
    final taxType = (json['tax_type'] as String?)?.trim() ?? 'iva_incluido';
    final vatRateApplied =
        (json['vat_rate_applied'] as num?)?.toDouble() ?? 0.15;
    final costPrice = (json['cost_price'] as num?)?.toDouble() ?? 0;
    final salePrice = (json['sale_price'] as num?)?.toDouble() ?? 0;
    final currencyRaw = (json['currency'] as String?)?.trim();
    final financials = ProductFinancials.normalize(
      costPrice: costPrice,
      salePrice: salePrice,
      taxType: taxType,
      vatRateApplied: vatRateApplied,
    );
    final createdAt =
        DateTime.tryParse((json['created_at'] as String?) ?? '') ??
        DateTime.now();
    final updatedAt =
        DateTime.tryParse((json['updated_at'] as String?) ?? '') ?? createdAt;

    return ProductModel(
      id: id,
      sku: (json['sku'] as String?)?.trim() ?? '',
      name: name,
      normalizedName: (normalizedNameRaw?.isNotEmpty ?? false)
          ? normalizedNameRaw!
          : ProductTextNormalizer.normalizeName(name),
      brand: (brandRaw?.isNotEmpty ?? false) ? brandRaw : null,
      category: category,
      subcategory: (subcategoryRaw?.isNotEmpty ?? false)
          ? ProductTextNormalizer.normalizeCategory(subcategoryRaw!)
          : null,
      unitOfMeasure: (unitRaw?.isNotEmpty ?? false) ? unitRaw! : 'unidad',
      barcode: (barcodeRaw?.isNotEmpty ?? false) ? barcodeRaw : null,
      costPrice: costPrice,
      costPriceWithoutVat: financials.costPriceWithoutVat,
      salePrice: salePrice,
      marginAmount: financials.marginAmount,
      marginPercent: financials.marginPercent,
      currency: (currencyRaw?.isNotEmpty ?? false) ? currencyRaw! : 'NIO',
      taxType: taxType,
      vatRateApplied: vatRateApplied,
      vatAmountOnCost: financials.vatAmountOnCost,
      stock: (json['stock'] as num?)?.toDouble() ?? 0,
      minStock: (json['min_stock'] as num?)?.toDouble() ?? 0,
      isActive: _readBool(json['is_active'], defaultValue: true),
      allowDecimalQuantity: _readBool(
        json['allow_decimal_quantity'],
        defaultValue: false,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, Object?> toJson() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'normalized_name': normalizedName,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'unit_of_measure': unitOfMeasure,
      'barcode': barcode,
      'cost_price': costPrice,
      'cost_price_without_vat': costPriceWithoutVat,
      'sale_price': salePrice,
      'margin_amount': marginAmount,
      'margin_percent': marginPercent,
      'currency': currency,
      'tax_type': taxType,
      'vat_rate_applied': vatRateApplied,
      'vat_amount_on_cost': vatAmountOnCost,
      'stock': stock,
      'min_stock': minStock,
      'is_active': isActive,
      'allow_decimal_quantity': allowDecimalQuantity,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'sku': sku,
      'name': name,
      'normalized_name': normalizedName,
      'brand': brand,
      'category': category,
      'subcategory': subcategory,
      'unit_of_measure': unitOfMeasure,
      'barcode': barcode,
      'cost_price': costPrice,
      'cost_price_without_vat': costPriceWithoutVat,
      'sale_price': salePrice,
      'margin_amount': marginAmount,
      'margin_percent': marginPercent,
      'currency': currency,
      'tax_type': taxType,
      'vat_rate_applied': vatRateApplied,
      'vat_amount_on_cost': vatAmountOnCost,
      'stock': stock,
      'min_stock': minStock,
      'is_active': isActive ? 1 : 0,
      'allow_decimal_quantity': allowDecimalQuantity ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Product toEntity() {
    return Product(
      id: id,
      sku: sku,
      name: name,
      normalizedName: normalizedName,
      brand: brand,
      category: category,
      subcategory: subcategory,
      unitOfMeasure: unitOfMeasure,
      barcode: barcode,
      costPrice: costPrice,
      costPriceWithoutVat: costPriceWithoutVat,
      salePrice: salePrice,
      marginAmount: marginAmount,
      marginPercent: marginPercent,
      currency: currency,
      taxType: taxType,
      vatRateApplied: vatRateApplied,
      vatAmountOnCost: vatAmountOnCost,
      stock: stock,
      minStock: minStock,
      isActive: isActive,
      allowDecimalQuantity: allowDecimalQuantity,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  static bool _readBool(Object? value, {required bool defaultValue}) {
    if (value is bool) return value;
    if (value is num) return value.toInt() == 1;
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      if (normalized == 'true' || normalized == '1') return true;
      if (normalized == 'false' || normalized == '0') return false;
    }
    return defaultValue;
  }

  static ProductModel fromEntity(Product product) {
    final financials = ProductFinancials.normalize(
      costPrice: product.costPrice,
      salePrice: product.salePrice,
      taxType: product.taxType,
      vatRateApplied: product.vatRateApplied,
    );

    return ProductModel(
      id: product.id,
      sku: product.sku,
      name: product.name,
      normalizedName: product.normalizedName,
      brand: product.brand,
      category: product.category,
      subcategory: product.subcategory,
      unitOfMeasure: product.unitOfMeasure,
      barcode: product.barcode,
      costPrice: product.costPrice,
      costPriceWithoutVat: financials.costPriceWithoutVat,
      salePrice: product.salePrice,
      marginAmount: financials.marginAmount,
      marginPercent: financials.marginPercent,
      currency: product.currency,
      taxType: product.taxType,
      vatRateApplied: product.vatRateApplied,
      vatAmountOnCost: financials.vatAmountOnCost,
      stock: product.stock,
      minStock: product.minStock,
      isActive: product.isActive,
      allowDecimalQuantity: product.allowDecimalQuantity,
      createdAt: product.createdAt,
      updatedAt: product.updatedAt,
    );
  }
}
