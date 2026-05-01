import 'package:app/src/features/products/presentation/widgets/product_quick_filters.dart';
import 'package:flutter/material.dart';

class ProductListHeader extends StatelessWidget {
  const ProductListHeader({
    super.key,
    required this.total,
    required this.filter,
  });

  final int total;
  final ProductQuickFilter filter;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            filter == ProductQuickFilter.all ? 'Catálogo' : filter.label,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '$total',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}
