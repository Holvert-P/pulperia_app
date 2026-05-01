class ProductFinancialSnapshot {
  const ProductFinancialSnapshot({
    required this.costPriceWithoutVat,
    required this.marginAmount,
    required this.marginPercent,
    required this.vatAmountOnCost,
  });

  final double costPriceWithoutVat;
  final double marginAmount;
  final double marginPercent;
  final double vatAmountOnCost;
}

class ProductFinancials {
  ProductFinancials._();

  static ProductFinancialSnapshot normalize({
    required double costPrice,
    required double salePrice,
    required String taxType,
    required double vatRateApplied,
  }) {
    final normalizedTaxType = taxType.trim().isEmpty
        ? 'iva_incluido'
        : taxType.trim().toLowerCase();
    final rate = vatRateApplied < 0 ? 0.0 : vatRateApplied;
    final safeCost = costPrice < 0 ? 0.0 : costPrice;
    final safeSale = salePrice < 0 ? 0.0 : salePrice;

    final costWithoutVat = switch (normalizedTaxType) {
      'iva_excluido' => safeCost,
      _ => rate == 0 ? safeCost : safeCost / (1 + rate),
    };

    final vatAmount = switch (normalizedTaxType) {
      'iva_excluido' => safeCost * rate,
      _ => safeCost - costWithoutVat,
    };

    final marginAmount = safeSale - safeCost;
    final marginPercent = safeCost == 0 ? 0.0 : (marginAmount / safeCost) * 100;

    return ProductFinancialSnapshot(
      costPriceWithoutVat: _round(costWithoutVat),
      marginAmount: _round(marginAmount),
      marginPercent: _round(marginPercent),
      vatAmountOnCost: _round(vatAmount),
    );
  }

  static double _round(double value, {int decimals = 2}) {
    final factor = decimals == 0 ? 1.0 : _pow10(decimals);
    return (value * factor).roundToDouble() / factor;
  }

  static double _pow10(int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= 10;
    }
    return result;
  }
}
