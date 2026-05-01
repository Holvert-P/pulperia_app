import 'package:app/src/features/debts/domain/entities/debt_payment.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class PaymentItem extends StatelessWidget {
  const PaymentItem({super.key, required this.payment});

  final DebtPayment payment;

  @override
  Widget build(BuildContext context) {
    final label = payment.type == 'interest' ? 'Interés' : 'Capital';
    return Card(
      child: ListTile(
        leading: const Icon(Icons.payments_outlined),
        title: Text(formatMoney(payment.amount)),
        subtitle: Text('$label • ${formatDateTime(payment.date)}'),
      ),
    );
  }
}
