import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:flutter/material.dart';

enum ProductQuickFilter { all, available, lowStock, outOfStock, inactive }

extension ProductQuickFilterX on ProductQuickFilter {
  String get label {
    switch (this) {
      case ProductQuickFilter.all:
        return 'Todos';
      case ProductQuickFilter.available:
        return 'Disponibles';
      case ProductQuickFilter.lowStock:
        return 'Stock bajo';
      case ProductQuickFilter.outOfStock:
        return 'Sin stock';
      case ProductQuickFilter.inactive:
        return 'Inactivos';
    }
  }

  IconData get icon {
    switch (this) {
      case ProductQuickFilter.all:
        return Icons.inventory_2_outlined;
      case ProductQuickFilter.available:
        return Icons.check_circle_outline;
      case ProductQuickFilter.lowStock:
        return Icons.warning_amber_outlined;
      case ProductQuickFilter.outOfStock:
        return Icons.error_outline;
      case ProductQuickFilter.inactive:
        return Icons.visibility_off_outlined;
    }
  }
}

class ProductQuickFilters extends StatelessWidget {
  const ProductQuickFilters({
    super.key,
    required this.selected,
    required this.products,
    required this.onSelected,
    required this.countByFilter,
  });

  final ProductQuickFilter selected;
  final List<Product> products;
  final ValueChanged<ProductQuickFilter> onSelected;
  final int Function(List<Product>, ProductQuickFilter) countByFilter;

  @override
  Widget build(BuildContext context) {
    final filters = ProductQuickFilter.values;

    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selected == filter;
          final count = countByFilter(products, filter);

          return FilterChip(
            selected: isSelected,
            avatar: Icon(filter.icon, size: 18),
            label: Text('${filter.label} ($count)'),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}
