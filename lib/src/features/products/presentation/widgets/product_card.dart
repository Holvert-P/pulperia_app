import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  const ProductCard({
    super.key,
    required this.product,
    required this.onTap,
    this.onDelete,
  });

  final Product product;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (product.sku.isNotEmpty)
                          _ChipLabel(
                            icon: Icons.qr_code_2_outlined,
                            text: product.sku,
                          ),
                        _ChipLabel(
                          icon: Icons.category_outlined,
                          text: product.category,
                        ),
                        if ((product.brand ?? '').isNotEmpty)
                          _ChipLabel(
                            icon: Icons.branding_watermark_outlined,
                            text: product.brand!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _InfoBox(
                            label: 'Precio de venta',
                            value: formatMoney(product.salePrice),
                            backgroundColor: colorScheme.primaryContainer,
                            foregroundColor: colorScheme.onPrimaryContainer,
                            borderColor: colorScheme.primary.withValues(
                              alpha: 0.28,
                            ),
                            prominent: true,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _InfoBox(
                            label: 'Costo',
                            value: formatMoney(product.costPrice),
                            backgroundColor: colorScheme.surfaceContainerHigh,
                            foregroundColor: colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onDelete != null)
                PopupMenuButton<_ProductMenuAction>(
                  tooltip: 'Acciones',
                  onSelected: (value) {
                    if (value == _ProductMenuAction.delete) {
                      onDelete?.call();
                    }
                  },
                  itemBuilder: (context) {
                    final scheme = Theme.of(context).colorScheme;
                    return [
                      PopupMenuItem(
                        value: _ProductMenuAction.delete,
                        child: Row(
                          children: [
                            Icon(
                              Icons.delete_outline,
                              color: scheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              'Eliminar',
                              style: TextStyle(
                                color: scheme.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ];
                  },
                )
              else
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

enum _ProductMenuAction { delete }

class _ChipLabel extends StatelessWidget {
  const _ChipLabel({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: scheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
    this.borderColor,
    this.prominent = false,
  });

  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;
  final Color? borderColor;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: borderColor == null ? null : Border.all(color: borderColor!),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: foregroundColor.withValues(alpha: 0.9),
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
                  (prominent
                          ? Theme.of(context).textTheme.titleMedium
                          : Theme.of(context).textTheme.labelLarge)
                      ?.copyWith(
                        color: foregroundColor,
                        fontWeight: FontWeight.w900,
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
