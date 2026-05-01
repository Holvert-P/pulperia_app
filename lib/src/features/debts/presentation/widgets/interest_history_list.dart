import 'package:app/src/features/debts/domain/entities/debt_interest_entry.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class InterestHistoryList extends StatelessWidget {
  const InterestHistoryList({super.key, required this.items});

  final List<DebtInterestEntry> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('Sin intereses generados'));
    }
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (context, index) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            leading: const Icon(Icons.percent_outlined),
            title: Text(formatMoney(item.interestAmount)),
            subtitle: Text(
              '${formatDateTime(item.date)} • ${formatPercent(item.rate * 100)}',
            ),
          ),
        );
      },
    );
  }
}
