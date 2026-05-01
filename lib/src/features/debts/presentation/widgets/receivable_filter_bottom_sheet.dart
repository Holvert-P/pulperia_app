import 'package:app/src/features/debts/presentation/controllers/debt_list_controller.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

Future<ReceivableAdvancedFilter?> showReceivableFilterBottomSheet(
  BuildContext context, {
  required ReceivableAdvancedFilter initial,
}) {
  return showModalBottomSheet<ReceivableAdvancedFilter>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => _ReceivableFilterSheet(initial: initial),
  );
}

class _ReceivableFilterSheet extends StatefulWidget {
  const _ReceivableFilterSheet({required this.initial});

  final ReceivableAdvancedFilter initial;

  @override
  State<_ReceivableFilterSheet> createState() => _ReceivableFilterSheetState();
}

class _ReceivableFilterSheetState extends State<_ReceivableFilterSheet> {
  final Set<String> _statuses = {};
  late bool? _withInterestPending = widget.initial.withInterestPending;
  late bool _noRecentPayment = widget.initial.noRecentPaymentOnly;
  late DateTime? _dueFrom = widget.initial.dueFrom;
  late DateTime? _dueTo = widget.initial.dueTo;
  final _minController = TextEditingController();
  final _maxController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _statuses.addAll(widget.initial.statuses);
    if (widget.initial.minBalance != null) {
      _minController.text = widget.initial.minBalance!.toStringAsFixed(2);
    }
    if (widget.initial.maxBalance != null) {
      _maxController.text = widget.initial.maxBalance!.toStringAsFixed(2);
    }
  }

  @override
  void dispose() {
    _minController.dispose();
    _maxController.dispose();
    super.dispose();
  }

  Future<void> _pickDueFrom() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueFrom ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _dueFrom = picked);
  }

  Future<void> _pickDueTo() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueTo ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    setState(() => _dueTo = picked);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.tune_outlined),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Filtros avanzados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Estado',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  label: 'Activa',
                  value: 'active',
                  selected: _statuses.contains('active'),
                  onToggle: (v) {
                    setState(() {
                      v ? _statuses.add('active') : _statuses.remove('active');
                    });
                  },
                ),
                _StatusChip(
                  label: 'Vencida',
                  value: 'overdue',
                  selected: _statuses.contains('overdue'),
                  onToggle: (v) {
                    setState(() {
                      v
                          ? _statuses.add('overdue')
                          : _statuses.remove('overdue');
                    });
                  },
                ),
                _StatusChip(
                  label: 'Pagada',
                  value: 'paid',
                  selected: _statuses.contains('paid'),
                  onToggle: (v) {
                    setState(() {
                      v ? _statuses.add('paid') : _statuses.remove('paid');
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saldo',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _minController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Mínimo',
                      prefixText: 'C\$ ',
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _maxController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Máximo',
                      prefixText: 'C\$ ',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Vencimiento',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Desde'),
                    subtitle: Text(
                      _dueFrom == null ? '—' : formatDate(_dueFrom!),
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDueFrom,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.event_outlined),
                    title: const Text('Hasta'),
                    subtitle: Text(_dueTo == null ? '—' : formatDate(_dueTo!)),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickDueTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: scheme.outlineVariant),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Sin pago reciente'),
                      subtitle: const Text('Último pago hace 14+ días o nunca'),
                      value: _noRecentPayment,
                      onChanged: (v) => setState(() => _noRecentPayment = v),
                    ),
                    const Divider(height: 0),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(Icons.percent_outlined),
                      title: const Text('Interés pendiente'),
                      subtitle: Text(
                        _withInterestPending == null
                            ? 'Cualquiera'
                            : _withInterestPending == true
                            ? 'Solo con interés'
                            : 'Solo sin interés',
                      ),
                      trailing: DropdownButton<bool?>(
                        value: _withInterestPending,
                        items: const [
                          DropdownMenuItem(
                            value: null,
                            child: Text('Cualquiera'),
                          ),
                          DropdownMenuItem(
                            value: true,
                            child: Text('Con interés'),
                          ),
                          DropdownMenuItem(
                            value: false,
                            child: Text('Sin interés'),
                          ),
                        ],
                        onChanged: (v) =>
                            setState(() => _withInterestPending = v),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(
                        context,
                      ).pop(const ReceivableAdvancedFilter());
                    },
                    icon: const Icon(Icons.restart_alt_outlined),
                    label: const Text('Limpiar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      final minRaw = _minController.text.trim().replaceAll(
                        ',',
                        '.',
                      );
                      final maxRaw = _maxController.text.trim().replaceAll(
                        ',',
                        '.',
                      );
                      final min = minRaw.isEmpty
                          ? null
                          : double.tryParse(minRaw);
                      final max = maxRaw.isEmpty
                          ? null
                          : double.tryParse(maxRaw);
                      Navigator.of(context).pop(
                        ReceivableAdvancedFilter(
                          statuses: _statuses,
                          minBalance: min,
                          maxBalance: max,
                          dueFrom: _dueFrom,
                          dueTo: _dueTo,
                          withInterestPending: _withInterestPending,
                          noRecentPaymentOnly: _noRecentPayment,
                        ),
                      );
                    },
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
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.onToggle,
  });

  final String label;
  final String value;
  final bool selected;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      selected: selected,
      label: Text(label),
      onSelected: onToggle,
    );
  }
}
