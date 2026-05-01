import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class AddPaymentResult {
  const AddPaymentResult({required this.amount, required this.date});

  final double amount;
  final DateTime date;
}

class AddPaymentDialog extends StatefulWidget {
  const AddPaymentDialog({super.key, required this.maxAmount});

  final double maxAmount;

  static Future<AddPaymentResult?> show(
    BuildContext context, {
    required double maxAmount,
  }) {
    return showModalBottomSheet<AddPaymentResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => AddPaymentDialog(maxAmount: maxAmount),
    );
  }

  @override
  State<AddPaymentDialog> createState() => _AddPaymentDialogState();
}

class _AddPaymentDialogState extends State<AddPaymentDialog> {
  final _amountController = TextEditingController();
  DateTime _date = DateTime.now();
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  void _submit() {
    final raw = _amountController.text.trim().replaceAll(',', '.');
    final value = double.tryParse(raw);
    if (value == null) {
      setState(() => _error = 'Monto inválido');
      return;
    }
    if (value <= 0) {
      setState(() => _error = 'El monto debe ser mayor a 0');
      return;
    }
    if (value > widget.maxAmount) {
      setState(() => _error = 'El pago no puede ser mayor al saldo');
      return;
    }

    Navigator.of(context).pop(AddPaymentResult(amount: value, date: _date));
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Registrar pago',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Monto',
              helperText: 'Máximo: ${formatMoney(widget.maxAmount)}',
              errorText: _error,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(formatDate(_date)),
                ),
              ),
              const SizedBox(width: 12),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Guardar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
