import 'package:app/src/features/debts/presentation/controllers/debt_list_controller.dart';
import 'package:flutter/material.dart';

Future<ReceivableSortOption?> showReceivableSortSheet(
  BuildContext context, {
  required ReceivableSortOption initial,
}) {
  return showModalBottomSheet<ReceivableSortOption>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      var value = initial;
      return StatefulBuilder(
        builder: (context, setState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.sort_outlined),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Ordenar',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  RadioGroup<ReceivableSortOption>(
                    groupValue: value,
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => value = v);
                    },
                    child: Column(
                      children: [
                        for (final opt in ReceivableSortOption.values)
                          RadioListTile<ReceivableSortOption>(
                            value: opt,
                            title: Text(_label(opt)),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.close),
                          label: const Text('Cancelar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => Navigator.of(context).pop(value),
                          icon: const Icon(Icons.check),
                          label: const Text('Aplicar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

String _label(ReceivableSortOption opt) {
  return switch (opt) {
    ReceivableSortOption.highestBalance => 'Mayor saldo',
    ReceivableSortOption.mostOverdue => 'Más vencida',
    ReceivableSortOption.lastPayment => 'Último pago',
    ReceivableSortOption.customerName => 'Nombre del cliente',
    ReceivableSortOption.mostRecent => 'Más reciente',
  };
}
