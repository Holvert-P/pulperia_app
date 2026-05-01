import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ProductProfitSummaryCard extends StatelessWidget {
  const ProductProfitSummaryCard({
    super.key,
    required this.profit,
    required this.marginPercent,
    required this.isLoss,
  });

  final double profit;
  final double marginPercent;
  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = isLoss ? scheme.errorContainer : scheme.primaryContainer;
    final fg = isLoss ? scheme.onErrorContainer : scheme.onPrimaryContainer;

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(isLoss ? Icons.trending_down : Icons.trending_up, color: fg),
            const SizedBox(width: 12),
            Expanded(
              child: _Metric(
                label: 'Ganancia',
                value: formatMoney(profit),
                color: fg,
              ),
            ),
            _Metric(
              label: 'Margen',
              value: formatPercent(marginPercent),
              color: fg,
              alignEnd: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.color,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
