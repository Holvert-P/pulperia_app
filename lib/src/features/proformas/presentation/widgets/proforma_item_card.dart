import 'package:app/src/features/proformas/domain/entities/proforma_item.dart';
import 'package:app/src/features/proformas/presentation/widgets/quantity_selector.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:app/src/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';

class ProformaItemCard extends StatelessWidget {
  const ProformaItemCard({
    super.key,
    required this.item,
    required this.onRemove,
    required this.onQuantityChanged,
    required this.onPriceChanged,
  });

  final ProformaItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQuantityChanged;
  final ValueChanged<double> onPriceChanged;

  Future<void> _confirmRemove(BuildContext context) async {
    final ok = await showConfirmationBottomSheet(
      context: context,
      icon: Icons.delete_outline,
      title: 'Quitar producto',
      headline: item.name,
      supportingText: 'Se quitará de la proforma.',
      confirmLabel: 'Eliminar',
      confirmIcon: Icons.delete_outline,
    );

    if (ok != true) return;
    onRemove();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            QuantitySelector(
              quantity: item.quantity,
              onChanged: onQuantityChanged,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Precio: ${formatMoney(item.price)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sub-total: ${formatMoney(item.subtotal)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            IconButton(
              onPressed: () => _confirmRemove(context),
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: colorScheme.error,
              ),
              tooltip: 'Quitar',
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            ),
          ],
        ),
      ),
    );
  }
}
