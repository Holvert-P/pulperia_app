import 'package:app/src/features/debts/presentation/controllers/debt_list_controller.dart';
import 'package:flutter/material.dart';

class ReceivableQuickFilters extends StatelessWidget {
  const ReceivableQuickFilters({
    super.key,
    required this.selected,
    required this.counts,
    required this.onSelected,
  });

  final ReceivableQuickFilter selected;
  final Map<ReceivableQuickFilter, int> counts;
  final ValueChanged<ReceivableQuickFilter> onSelected;

  String _label(ReceivableQuickFilter f) {
    return switch (f) {
      ReceivableQuickFilter.all => 'Todas',
      ReceivableQuickFilter.active => 'Activas',
      ReceivableQuickFilter.overdue => 'Vencidas',
      ReceivableQuickFilter.paid => 'Pagadas',
      ReceivableQuickFilter.withInterest => 'Con interés',
      ReceivableQuickFilter.noRecentPayment => 'Sin pago reciente',
    };
  }

  IconData _icon(ReceivableQuickFilter f) {
    return switch (f) {
      ReceivableQuickFilter.all => Icons.list_alt_outlined,
      ReceivableQuickFilter.active => Icons.play_circle_outline,
      ReceivableQuickFilter.overdue => Icons.warning_amber_outlined,
      ReceivableQuickFilter.paid => Icons.verified_outlined,
      ReceivableQuickFilter.withInterest => Icons.percent_outlined,
      ReceivableQuickFilter.noRecentPayment => Icons.schedule_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filters = ReceivableQuickFilter.values;

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final f = filters[index];
          final isSelected = f == selected;
          final count = counts[f] ?? 0;
          final text = '${_label(f)} ($count)';

          return ChoiceChip(
            selected: isSelected,
            label: Text(
              text,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: isSelected ? scheme.onSecondaryContainer : null,
              ),
            ),
            avatar: Icon(
              _icon(f),
              size: 18,
              color: isSelected ? scheme.onSecondaryContainer : null,
            ),
            onSelected: (_) => onSelected(f),
          );
        },
      ),
    );
  }
}
