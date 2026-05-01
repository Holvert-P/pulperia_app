import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class DebtCard extends StatelessWidget {
  const DebtCard({super.key, required this.item, required this.onTap});

  final ReceivableDetail item;
  final VoidCallback onTap;

  String _statusText() {
    final status = item.receivable.status;
    return switch (status) {
      'active' => 'Activa',
      'overdue' => 'Vencida',
      'paid' => 'Pagada',
      'cancelled' => 'Cancelada',
      'refinanced' => 'Refinanciada',
      'frozen' => 'Congelada',
      _ => status,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = item.receivable.status;
    final statusColor = switch (status) {
      'paid' => Colors.green,
      'overdue' => Colors.red,
      'active' => Colors.blue,
      'cancelled' => Colors.grey,
      'refinanced' => Colors.deepPurple,
      'frozen' => Colors.blueGrey,
      _ => scheme.primary,
    };
    final initials = item.receivable.customerName.trim().isEmpty
        ? '?'
        : item.receivable.customerName.trim().characters.first.toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: statusColor.withValues(alpha: 0.95),
                width: 5,
              ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: statusColor.withValues(alpha: 0.16),
                      child: Text(
                        initials,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: statusColor,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.receivable.customerName,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Vence: ${formatDate(item.receivable.dueDate)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    _StatusPill(
                      text: _statusText(),
                      color: statusColor,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Saldo',
                            style:
                                Theme.of(context).textTheme.labelMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            formatMoney(item.balances.totalPending),
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right,
                      color: scheme.onSurfaceVariant,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _MiniStat(
                      icon: Icons.savings_outlined,
                      label: 'Capital',
                      value: formatMoney(item.balances.principalPending),
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 10),
                    _MiniStat(
                      icon: Icons.percent_outlined,
                      label: 'Interés',
                      value: formatMoney(item.balances.interestPending),
                      backgroundColor: scheme.secondaryContainer,
                      foregroundColor: scheme.onSecondaryContainer,
                    ),
                  ],
                ),
                if (item.balances.isOverdue) ...[
                  const SizedBox(height: 10),
                  Text(
                    '${item.balances.daysOverdue} días de atraso',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
              ),
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, size: 18, color: foregroundColor),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: foregroundColor,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: foregroundColor,
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
