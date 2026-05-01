import 'package:app/src/features/debts/domain/entities/receivable_detail.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ReceivableListItem extends StatelessWidget {
  const ReceivableListItem({
    super.key,
    required this.item,
    required this.onTap,
    required this.onQuickPay,
  });

  final ReceivableDetail item;
  final VoidCallback onTap;
  final VoidCallback? onQuickPay;

  String _statusText(String status) {
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

  (Color, IconData) _statusStyle(String status, ColorScheme scheme) {
    return switch (status) {
      'paid' => (Colors.green, Icons.verified_outlined),
      'overdue' => (scheme.error, Icons.warning_amber_outlined),
      'active' => (scheme.primary, Icons.play_circle_outline),
      _ => (scheme.onSurfaceVariant, Icons.info_outline),
    };
  }

  @override
  Widget build(BuildContext context) {
    final r = item.receivable;
    final b = item.balances;
    final scheme = Theme.of(context).colorScheme;
    final (statusColor, statusIcon) = _statusStyle(r.status, scheme);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundColor: statusColor.withValues(alpha: 0.12),
                    child: Icon(statusIcon, size: 18, color: statusColor),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r.customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Ref: ${r.receivableId} · Vence: ${formatDate(r.dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  _StatusChip(text: _statusText(r.status), color: statusColor),
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
                          style: Theme.of(context).textTheme.labelMedium
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(b.totalPending),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  if (b.isOverdue)
                    _StatusChip(
                      text: '${b.daysOverdue} días atraso',
                      color: statusColor,
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MiniStat(
                    icon: Icons.savings_outlined,
                    label: 'Capital',
                    value: formatMoney(b.principalPending),
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    icon: Icons.percent_outlined,
                    label: 'Interés',
                    value: formatMoney(b.interestPending),
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoLine(
                      icon: Icons.payments_outlined,
                      label: 'Último pago',
                      value: b.lastPaymentAt == null
                          ? '—'
                          : formatDateTime(b.lastPaymentAt!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoLine(
                      icon: Icons.auto_awesome_outlined,
                      label: 'Próximo interés',
                      value: b.nextInterestAt == null
                          ? '—'
                          : formatDateTime(b.nextInterestAt!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: onQuickPay != null
                        ? FilledButton.icon(
                            onPressed: onQuickPay,
                            icon: const Icon(Icons.payments_outlined),
                            label: const Text('Cobrar'),
                          )
                        : FilledButton.tonalIcon(
                            onPressed: onTap,
                            icon: const Icon(Icons.history_outlined),
                            label: const Text('Ver historial'),
                          ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.filledTonal(
                    onPressed: onTap,
                    tooltip: 'Ver detalle',
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.30)),
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

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Icon(icon, size: 18, color: scheme.onSurfaceVariant),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
    );
  }
}
