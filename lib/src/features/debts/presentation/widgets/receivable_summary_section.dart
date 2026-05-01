import 'package:app/src/features/debts/domain/entities/portfolio_summary.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ReceivableSummarySection extends StatelessWidget {
  const ReceivableSummarySection({super.key, required this.summary});

  final PortfolioSummary? summary;

  @override
  Widget build(BuildContext context) {
    final s = summary;
    if (s == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: scheme.primary.withValues(alpha: 0.12),
              child: Icon(Icons.insights_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Resumen',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _MetricCard(
              label: 'Cartera',
              value: formatMoney(s.totalPortfolio),
              icon: Icons.account_balance_wallet_outlined,
              color: scheme.primary,
            ),
            _MetricCard(
              label: 'Vencidas',
              value: '${s.overdueCount}',
              icon: Icons.warning_amber_outlined,
              color: scheme.error,
            ),
            _MetricCard(
              label: 'Cobrado hoy',
              value: formatMoney(s.collectedToday),
              icon: Icons.today_outlined,
              color: scheme.tertiary,
            ),
            _MetricCard(
              label: 'Interés pendiente',
              value: formatMoney(s.totalInterestPending),
              icon: Icons.percent_outlined,
              color: scheme.secondary,
            ),
          ],
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 160),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

