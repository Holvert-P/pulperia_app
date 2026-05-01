import 'package:app/src/features/debts/data/repositories/receivable_repository_impl.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';
import 'package:app/src/features/debts/presentation/controllers/debt_form_controller.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class DebtFormPage extends StatefulWidget {
  const DebtFormPage({super.key});

  static const routeName = '/debts/create';

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends State<DebtFormPage> {
  final _customerController = TextEditingController();
  final _amountController = TextEditingController();
  final _rateController = TextEditingController(text: '10');
  final _cycleDaysController = TextEditingController(text: '30');

  @override
  void dispose() {
    _customerController.dispose();
    _amountController.dispose();
    _rateController.dispose();
    _cycleDaysController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, DebtFormController c) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: c.dueDate,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
    );
    if (picked == null) return;
    c.setDueDate(picked);
  }

  Future<void> _save(BuildContext context, DebtFormController c) async {
    c.setCustomerName(_customerController.text);
    final raw = _amountController.text.trim().replaceAll(',', '.');
    c.setTotalAmount(double.tryParse(raw) ?? 0);
    final rawRate = _rateController.text.trim().replaceAll(',', '.');
    final parsedRate = double.tryParse(rawRate);
    c.setMonthlyRate(((parsedRate ?? 10) / 100).clamp(0, 1));
    final rawCycle = _cycleDaysController.text.trim();
    c.setGenerationCycleDays(int.tryParse(rawCycle) ?? 30);

    final ok = await c.save();
    final message = c.error;
    if (!context.mounted) return;

    if (!ok) {
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }

    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final repo = ReceivableRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) => DebtFormController(
        createReceivableFromCreditSale: CreateReceivableFromCreditSale(repo),
      ),
      child: Consumer<DebtFormController>(
        builder: (context, c, _) {
          final scheme = Theme.of(context).colorScheme;
          return Scaffold(
            appBar: AppBar(
              title: const Text('Nueva cuenta por cobrar'),
              actions: [
                IconButton(
                  onPressed: c.saving ? null : () => _save(context, c),
                  icon: const Icon(Icons.save_outlined),
                  tooltip: 'Guardar',
                ),
              ],
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: c.saving ? null : () => _save(context, c),
                  icon: c.saving
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.save_outlined),
                  label: const Text('Guardar'),
                ),
              ),
            ),
            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: scheme.primary.withValues(
                                alpha: 0.12,
                              ),
                              child: Icon(
                                Icons.account_balance_wallet_outlined,
                                color: scheme.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nueva cuenta por cobrar',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Venta al crédito con política de interés propia',
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: scheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w600,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            TextField(
                              controller: _customerController,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Cliente',
                                hintText: 'Nombre del cliente',
                                prefixIcon: Icon(Icons.person_outline),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _amountController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Capital (principal)',
                                hintText: '0.00',
                                prefixText: 'C\$ ',
                                prefixIcon: Icon(Icons.payments_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _rateController,
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              decoration: const InputDecoration(
                                labelText: 'Tasa mensual (%)',
                                hintText: '10',
                                prefixIcon: Icon(Icons.percent_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _cycleDaysController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Ciclo de interés (días)',
                                hintText: '30',
                                prefixIcon: Icon(Icons.autorenew_outlined),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Aplicar solo si está vencida'),
                              subtitle: const Text(
                                'No genera intereses antes del vencimiento',
                              ),
                              value: c.appliesOnOverdueOnly,
                              onChanged: c.saving
                                  ? null
                                  : (v) => c.setAppliesOnOverdueOnly(v),
                            ),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              title: const Text('Interés compuesto'),
                              subtitle: const Text(
                                'Calcula interés sobre capital + interés pendiente',
                              ),
                              value: c.compoundInterest,
                              onChanged: c.saving
                                  ? null
                                  : (v) => c.setCompoundInterest(v),
                            ),
                            const SizedBox(height: 8),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.calendar_today_outlined,
                              ),
                              title: const Text('Vence el'),
                              subtitle: Text(formatDate(c.dueDate)),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => _pickDate(context, c),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
