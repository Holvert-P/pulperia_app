import 'package:app/src/features/catalog/domain/services/catalog_text_normalizer.dart';
import 'package:app/src/features/products/data/models/product_model.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/features/products/domain/services/product_financials.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';

class ProductCatalogJsonMapper {
  const ProductCatalogJsonMapper();

  static const double defaultVatRate = 0.15;

  Map<String, Object?> buildExportPayload(
    List<ProductModel> products, {
    required DateTime exportedAt,
  }) {
    final productItems = <Map<String, Object?>>[
      for (var i = 0; i < products.length; i++)
        toCatalogJson(products[i], fallbackIndex: i + 1),
    ];

    return {
      'meta': {
        'source_file': 'sqlite_export',
        'exported_from': 'pulperia_perez_app',
        'exported_at': exportedAt.toIso8601String(),
        'currency': 'NIO',
        'total_products': productItems.length,
        'notes': const [
          'Catálogo exportado desde SQLite.',
          'Este archivo puede modificarse masivamente con IA y luego reimportarse en la app.',
          'Revisar precios, categorías, stock, código de barras y unidad de medida antes de reimportar.',
          'Los campos financieros deben recalcularse al importar para evitar inconsistencias.',
        ],
        'vat_rate_applied_to_costs_without_vat': defaultVatRate,
        'products_updated_with_vat': products
            .where((product) => product.vatRateApplied > 0)
            .length,
      },
      'products': productItems,
    };
  }

  Map<String, Object?> toCatalogJson(
    ProductModel product, {
    int? fallbackIndex,
  }) {
    final taxType = _safeString(product.taxType) ?? 'iva_incluido';
    final currency = _safeString(product.currency) ?? 'NIO';
    final financials = ProductFinancials.normalize(
      costPrice: product.costPrice,
      salePrice: product.salePrice,
      taxType: taxType,
      vatRateApplied: product.vatRateApplied,
    );

    return {
      'id': product.id,
      'legacy_batch': null,
      'legacy_index': fallbackIndex,
      'sku': _safeString(product.sku),
      'name': product.name,
      'normalized_name': ProductTextNormalizer.normalizeName(product.name),
      'description': null,
      'brand': _safeString(product.brand),
      'category': CatalogTextNormalizer.normalize(product.category),
      'subcategory': product.subcategory == null
          ? null
          : CatalogTextNormalizer.normalize(product.subcategory!),
      'unit_of_measure': CatalogTextNormalizer.normalize(product.unitOfMeasure),
      'barcode': _safeString(product.barcode),
      'cost_price': _roundMoney(product.costPrice),
      'sale_price': _roundMoney(product.salePrice),
      'margin_amount': financials.marginAmount,
      'margin_percent': financials.marginPercent,
      'currency': currency,
      'tax_type': taxType,
      'stock': product.stock,
      'min_stock': product.minStock,
      'is_active': product.isActive,
      'allow_decimal_quantity': product.allowDecimalQuantity,
      'created_from': 'sqlite_export',
      'cost_price_without_vat': financials.costPriceWithoutVat,
      'vat_rate_applied': product.vatRateApplied,
      'vat_amount_on_cost': financials.vatAmountOnCost,
    };
  }

  ProductCatalogParsedItem parseProduct(
    Map<String, Object?> json, {
    required int position,
    required DateTime importedAt,
  }) {
    final id = _readString(json['id']);
    if (id == null) {
      throw ProductCatalogException('Producto #$position: falta id.');
    }

    final name = _readString(json['name']);
    if (name == null) {
      throw ProductCatalogException('Producto #$position: falta nombre.');
    }

    final categoryRaw = _readString(json['category']);
    if (categoryRaw == null) {
      throw ProductCatalogException('Producto #$position: falta categoría.');
    }

    final costPrice = _readNumber(json['cost_price']);
    if (costPrice == null) {
      throw ProductCatalogException('Producto #$position: falta cost_price.');
    }
    if (costPrice < 0) {
      throw ProductCatalogException(
        'Producto #$position: cost_price no puede ser negativo.',
      );
    }

    final salePrice = _readNumber(json['sale_price']);
    if (salePrice == null) {
      throw ProductCatalogException('Producto #$position: falta sale_price.');
    }
    if (salePrice < 0) {
      throw ProductCatalogException(
        'Producto #$position: sale_price no puede ser negativo.',
      );
    }

    final taxType = _readString(json['tax_type']) ?? 'iva_incluido';
    final vatRateApplied = _readNumber(json['vat_rate_applied']) ?? 0.0;
    final financials = ProductFinancials.normalize(
      costPrice: costPrice,
      salePrice: salePrice,
      taxType: taxType,
      vatRateApplied: vatRateApplied,
    );
    final category = CatalogTextNormalizer.normalize(categoryRaw);
    final subcategoryRaw = _readString(json['subcategory']);
    final createdAt =
        DateTime.tryParse(_readString(json['created_at']) ?? '') ?? importedAt;

    return ProductCatalogParsedItem(
      position: position,
      product: ProductModel(
        id: id,
        sku: _readString(json['sku']) ?? '',
        name: name,
        normalizedName: ProductTextNormalizer.normalizeName(name),
        brand: _readString(json['brand']),
        category: category,
        subcategory: subcategoryRaw == null
            ? null
            : CatalogTextNormalizer.normalize(subcategoryRaw),
        unitOfMeasure: CatalogTextNormalizer.normalize(
          _readString(json['unit_of_measure']) ?? 'unidad',
        ),
        barcode: _readString(json['barcode']),
        costPrice: _roundMoney(costPrice),
        costPriceWithoutVat: financials.costPriceWithoutVat,
        salePrice: _roundMoney(salePrice),
        marginAmount: financials.marginAmount,
        marginPercent: financials.marginPercent,
        currency: _readString(json['currency']) ?? 'NIO',
        taxType: taxType,
        vatRateApplied: vatRateApplied < 0 ? 0.0 : vatRateApplied,
        vatAmountOnCost: financials.vatAmountOnCost,
        stock: _readNumber(json['stock']) ?? 0,
        minStock: _readNumber(json['min_stock']) ?? 0,
        isActive: _readBool(json['is_active'], defaultValue: true),
        allowDecimalQuantity: _readBool(
          json['allow_decimal_quantity'],
          defaultValue: false,
        ),
        createdAt: createdAt,
        updatedAt: importedAt,
      ),
    );
  }

  static String? _safeString(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  static String? _readString(Object? value) {
    if (value == null) return null;
    if (value is String) return _safeString(value);
    if (value is num || value is bool) return value.toString();
    return null;
  }

  static double? _readNumber(Object? value) {
    if (value is num) return value.toDouble();
    if (value is String) {
      final normalized = value.trim().replaceAll(',', '.');
      if (normalized.isEmpty) return null;
      return double.tryParse(normalized);
    }
    return null;
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

  static double _roundMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}

class ProductCatalogParsedItem {
  const ProductCatalogParsedItem({
    required this.position,
    required this.product,
  });

  final int position;
  final ProductModel product;
}
