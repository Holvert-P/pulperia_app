import 'package:app/src/features/debts/data/repositories/receivable_repository_impl.dart';
import 'package:app/src/features/debts/domain/entities/collection_action.dart';
import 'package:app/src/features/debts/domain/entities/receivable_transaction.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';
import 'package:app/src/features/debts/presentation/controllers/debt_detail_controller.dart';
import 'package:app/src/features/debts/presentation/pages/add_payment_page.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DebtDetailArgs {
  const DebtDetailArgs({required this.debtId});

  final String debtId;
}

class DebtDetailPage extends StatelessWidget {
  const DebtDetailPage({super.key, required this.args});

  static const routeName = '/debts/detail';

  final DebtDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final repo = ReceivableRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) => DebtDetailController(
        getReceivableDetail: GetReceivableDetail(repo),
        getReceivableLedger: GetReceivableLedger(repo),
        getCollectionActions: GetCollectionActions(repo),
        generateReceivableInterest: GenerateReceivableInterest(repo),
        reverseReceivablePayment: ReverseReceivablePayment(repo),
        registerCollectionAction: RegisterCollectionAction(repo),
        debtId: args.debtId,
      )..load(),
      child: const _DebtDetailView(),
    );
  }
}

class _DebtDetailView extends StatelessWidget {
  const _DebtDetailView();

  Future<void> _openAddPayment(BuildContext context) async {
    final c = context.read<DebtDetailController>();
    final detail = c.detail;
    if (detail == null) return;
    if (!detail.canRegisterPayment) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cuenta saldada: no admite pagos')),
      );
      return;
    }

    final ok = await Navigator.of(context).pushNamed<bool>(
      AddPaymentPage.routeName,
      arguments: AddPaymentArgs(
        receivableId: detail.receivable.receivableId,
        maxPrincipalAmount: detail.balances.principalPending,
        maxInterestAmount: detail.balances.interestPending,
      ),
    );

    if (ok == true && context.mounted) {
      await c.load();
    }
  }

  Future<void> _openRegisterCollectionAction(BuildContext context) async {
    final c = context.read<DebtDetailController>();
    final detail = c.detail;
    if (detail == null) return;

    String type = 'llamada';
    final noteController = TextEditingController();
    final result = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  16,
                  8,
                  16,
                  16 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.support_agent_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Registrar gestión de cobranza',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: type,
                      decoration: const InputDecoration(
                        labelText: 'Tipo',
                        prefixIcon: Icon(Icons.flag_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'llamada',
                          child: Text('Llamada'),
                        ),
                        DropdownMenuItem(
                          value: 'mensaje',
                          child: Text('Mensaje'),
                        ),
                        DropdownMenuItem(
                          value: 'visita',
                          child: Text('Visita'),
                        ),
                        DropdownMenuItem(
                          value: 'promesa_pago',
                          child: Text('Promesa de pago'),
                        ),
                        DropdownMenuItem(
                          value: 'nota',
                          child: Text('Nota interna'),
                        ),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setState(() => type = v);
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Nota',
                        hintText: 'Detalle de la gestión',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(false),
                            icon: const Icon(Icons.close),
                            label: const Text('Cancelar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => Navigator.of(context).pop(true),
                            icon: const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
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

    if (result != true) return;
    final ok = await c.addCollectionAction(
      type: type,
      note: noteController.text,
      actionAt: DateTime.now(),
    );
    if (!context.mounted) return;
    if (!ok) {
      final message = c.error ?? 'No se pudo registrar la gestión';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Color _statusColor(String status, ColorScheme scheme) {
    return switch (status) {
      'paid' => Colors.green,
      'overdue' => Colors.red,
      'active' => Colors.blue,
      'cancelled' => Colors.grey,
      'refinanced' => Colors.deepPurple,
      'frozen' => Colors.blueGrey,
      _ => scheme.primary,
    };
  }

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

  Future<void> _generateInterest(BuildContext context) async {
    final c = context.read<DebtDetailController>();
    final count = await c.generateInterest();
    if (!context.mounted) return;
    if (c.error != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(c.error!)));
      return;
    }
    if (count <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay intereses por generar')),
      );
      return;
    }
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Intereses generados: $count')));
  }

  Future<void> _openReverseReceipt(
    BuildContext context, {
    required String receiptId,
  }) async {
    final c = context.read<DebtDetailController>();
    final reasonController = TextEditingController();
    final ok = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              8,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.undo_outlined),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Revertir pago',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: reasonController,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Motivo',
                    hintText: 'Ej: Pago duplicado / error de caja',
                    prefixIcon: Icon(Icons.report_problem_outlined),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(false),
                        icon: const Icon(Icons.close),
                        label: const Text('Cancelar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () => Navigator.of(context).pop(true),
                        icon: const Icon(Icons.undo_outlined),
                        label: const Text('Revertir'),
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
    if (ok != true) return;

    final success = await c.reverseReceipt(
      receiptId: receiptId,
      reason: reasonController.text,
      reversedAt: DateTime.now(),
    );
    if (!context.mounted) return;
    if (!success) {
      final message = c.error ?? 'No se pudo revertir el pago';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<DebtDetailController>();
    final detail = c.detail;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.receivable.customerName ?? 'Detalle'),
        actions: [
          IconButton(
            onPressed: c.loading ? null : c.load,
            icon: const Icon(Icons.refresh_outlined),
            tooltip: 'Refrescar',
          ),
          IconButton(
            onPressed: detail == null || c.working
                ? null
                : () => _generateInterest(context),
            icon: const Icon(Icons.auto_awesome_outlined),
            tooltip: 'Generar intereses',
          ),
          IconButton(
            onPressed: detail == null || c.working
                ? null
                : () => _openRegisterCollectionAction(context),
            icon: const Icon(Icons.support_agent_outlined),
            tooltip: 'Registrar gestión',
          ),
        ],
      ),
      floatingActionButton: detail == null || c.working
          ? null
          : !detail.canRegisterPayment
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openAddPayment(context),
              icon: const Icon(Icons.payments_outlined),
              label: const Text('Registrar pago'),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) {
              if (c.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.error != null && detail == null) {
                return Center(child: Text(c.error!));
              }
              if (detail == null) {
                return const Center(
                  child: Text('Cuenta por cobrar no encontrada'),
                );
              }

              final r = detail.receivable;
              final b = detail.balances;
              final statusColor = _statusColor(r.status, scheme);

              final receipts = _groupReceipts(c.ledger);
              final otherTxns = c.ledger
                  .where((t) => t.receiptId == null)
                  .toList();

              return ListView(
                children: [
                  _DebtSummaryCard(
                    customerName: r.customerName,
                    createdAt: r.createdAt,
                    dueDate: r.dueDate,
                    statusText: _statusText(r.status),
                    statusColor: statusColor,
                    total: b.totalPending,
                    capital: b.principalPending,
                    interest: b.interestPending,
                    daysOverdue: b.daysOverdue,
                    lastPaymentAt: b.lastPaymentAt,
                    nextInterestAt: b.nextInterestAt,
                  ),
                  const SizedBox(height: 12),
                  if (!detail.canRegisterPayment)
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        leading: const Icon(Icons.lock_outline),
                        title: const Text('Cuenta cerrada'),
                        subtitle: const Text(
                          'Esta cuenta está saldada o marcada como cerrada. No admite nuevos pagos.',
                        ),
                      ),
                    ),
                  if (!detail.canRegisterPayment)
                    const SizedBox(height: 12),
                  Text(
                    'Movimientos',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (receipts.isEmpty && otherTxns.isEmpty)
                    Text(
                      'Sin movimientos',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  for (final receipt in receipts) ...[
                    const SizedBox(height: 10),
                    _ReceiptTile(
                      receipt: receipt,
                      onReverse: receipt.isReversed || c.working
                          ? null
                          : () => _openReverseReceipt(
                              context,
                              receiptId: receipt.receiptId,
                            ),
                    ),
                  ],
                  for (final t in otherTxns) ...[
                    const SizedBox(height: 10),
                    _TxnTile(txn: t),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'Gestión de cobranza',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (c.collectionActions.isEmpty)
                    Text(
                      'Sin gestiones registradas',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  for (final a in c.collectionActions) ...[
                    const SizedBox(height: 10),
                    _CollectionTile(action: a),
                  ],
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ReceiptGroup {
  const _ReceiptGroup({
    required this.receiptId,
    required this.paidAt,
    required this.principalAmount,
    required this.interestAmount,
    required this.reversalAmount,
  });

  final String receiptId;
  final DateTime paidAt;
  final double principalAmount;
  final double interestAmount;
  final double reversalAmount;

  bool get isReversed =>
      reversalAmount >= (principalAmount + interestAmount) - 0.005;
  double get total => (principalAmount + interestAmount) - reversalAmount;
}

List<_ReceiptGroup> _groupReceipts(List<ReceivableTransaction> ledger) {
  final groups = <String, _ReceiptGroup>{};
  for (final t in ledger) {
    if (t.receiptId == null) continue;
    final id = t.receiptId!;
    final existing = groups[id];
    var principal = existing?.principalAmount ?? 0.0;
    var interest = existing?.interestAmount ?? 0.0;
    var reversal = existing?.reversalAmount ?? 0.0;

    final type = t.type;
    final amount = t.amount;
    if (type == 'payment_principal') principal += amount;
    if (type.startsWith('payment_interest')) interest += amount;
    if (type.startsWith('reversal_payment')) reversal += amount;

    groups[id] = _ReceiptGroup(
      receiptId: id,
      paidAt: t.occurredAt,
      principalAmount: principal,
      interestAmount: interest,
      reversalAmount: reversal,
    );
  }
  final list = groups.values.toList()
    ..sort((a, b) => b.paidAt.compareTo(a.paidAt));
  return list;
}

class _ReceiptTile extends StatelessWidget {
  const _ReceiptTile({required this.receipt, required this.onReverse});

  final _ReceiptGroup receipt;
  final VoidCallback? onReverse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = receipt.isReversed ? 'Pago revertido' : 'Pago';
    final subtitle = [
      'Capital: ${formatMoney(receipt.principalAmount)}',
      'Interés: ${formatMoney(receipt.interestAmount)}',
      if (receipt.reversalAmount > 0)
        'Reversión: ${formatMoney(receipt.reversalAmount)}',
    ].join(' · ');

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.primary.withValues(alpha: 0.12),
          child: Icon(Icons.receipt_long_outlined, color: scheme.primary),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          '$subtitle\n${formatDateTime(receipt.paidAt)}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        isThreeLine: true,
        trailing: onReverse == null
            ? null
            : IconButton(
                onPressed: onReverse,
                icon: const Icon(Icons.undo_outlined),
                tooltip: 'Revertir',
              ),
      ),
    );
  }
}

class _TxnTile extends StatelessWidget {
  const _TxnTile({required this.txn});

  final ReceivableTransaction txn;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (title, icon) = switch (txn.type) {
      'principal_charge' => ('Cargo de capital', Icons.add_circle_outline),
      'interest_charge' => ('Cargo de interés', Icons.percent_outlined),
      'principal_adjust' => ('Ajuste de capital', Icons.tune_outlined),
      'interest_adjust' => ('Ajuste de interés', Icons.tune_outlined),
      _ => (txn.type, Icons.swap_horiz_outlined),
    };

    final subtitleParts = <String>[
      formatDateTime(txn.occurredAt),
      if (txn.periodStart != null && txn.periodEnd != null)
        '${formatDateTime(txn.periodStart!)} → ${formatDateTime(txn.periodEnd!)}',
      if (txn.note != null && txn.note!.trim().isNotEmpty) txn.note!.trim(),
    ];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.surfaceContainerHigh,
          child: Icon(icon, color: scheme.onSurfaceVariant),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          subtitleParts.join(' · '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Text(
          formatMoney(txn.amount),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class _CollectionTile extends StatelessWidget {
  const _CollectionTile({required this.action});

  final CollectionAction action;

  String _label(String type) {
    return switch (type) {
      'llamada' => 'Llamada',
      'mensaje' => 'Mensaje',
      'visita' => 'Visita',
      'promesa_pago' => 'Promesa de pago',
      'nota' => 'Nota interna',
      _ => type,
    };
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: scheme.secondary.withValues(alpha: 0.12),
          child: Icon(Icons.support_agent_outlined, color: scheme.secondary),
        ),
        title: Text(
          _label(action.type),
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        subtitle: Text(
          [
            formatDateTime(action.actionAt),
            if (action.note != null && action.note!.trim().isNotEmpty)
              action.note!.trim(),
          ].join(' · '),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _DebtSummaryCard extends StatelessWidget {
  const _DebtSummaryCard({
    required this.customerName,
    required this.createdAt,
    required this.dueDate,
    required this.statusText,
    required this.statusColor,
    required this.total,
    required this.capital,
    required this.interest,
    required this.daysOverdue,
    required this.lastPaymentAt,
    required this.nextInterestAt,
  });

  final String customerName;
  final DateTime createdAt;
  final DateTime dueDate;
  final String statusText;
  final Color statusColor;
  final double total;
  final double capital;
  final double interest;
  final int daysOverdue;
  final DateTime? lastPaymentAt;
  final DateTime? nextInterestAt;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initials = customerName.trim().isEmpty
        ? '?'
        : customerName.trim().characters.first.toUpperCase();

    return Card(
      clipBehavior: Clip.antiAlias,
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
                          customerName,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Creada: ${formatDateTime(createdAt)} · Vence: ${formatDate(dueDate)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: scheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  _StatusPill(text: statusText, color: statusColor),
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
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          formatMoney(total),
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                  ),
                  if (daysOverdue > 0)
                    _StatusPill(
                      text: '$daysOverdue días atraso',
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
                    value: formatMoney(capital),
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 10),
                  _MiniStat(
                    icon: Icons.percent_outlined,
                    label: 'Interés',
                    value: formatMoney(interest),
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MiniInfo(
                      label: 'Último pago',
                      value: lastPaymentAt == null
                          ? '—'
                          : formatDateTime(lastPaymentAt!),
                      icon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MiniInfo(
                      label: 'Próximo interés',
                      value: nextInterestAt == null
                          ? '—'
                          : formatDateTime(nextInterestAt!),
                      icon: Icons.auto_awesome_outlined,
                    ),
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

class _MiniInfo extends StatelessWidget {
  const _MiniInfo({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
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
