import 'package:app/src/features/debts/data/repositories/receivable_repository_impl.dart';
import 'package:app/src/features/debts/domain/repositories/receivable_repository.dart';
import 'package:app/src/features/debts/domain/usecases/receivable_usecases.dart';
import 'package:app/src/features/debts/presentation/widgets/payment_type_selector.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class AddPaymentPage extends StatefulWidget {
  const AddPaymentPage({
    super.key,
    required this.receivableId,
    required this.maxPrincipalAmount,
    required this.maxInterestAmount,
  });

  static const routeName = '/debts/add-payment';

  final String receivableId;
  final double maxPrincipalAmount;
  final double maxInterestAmount;

  @override
  State<AddPaymentPage> createState() => _AddPaymentPageState();
}

class AddPaymentArgs {
  const AddPaymentArgs({
    required this.receivableId,
    required this.maxPrincipalAmount,
    required this.maxInterestAmount,
  });

  final String receivableId;
  final double maxPrincipalAmount;
  final double maxInterestAmount;
}

class _AddPaymentPageState extends State<AddPaymentPage> {
  final _totalController = TextEditingController();
  final _principalController = TextEditingController();
  final _interestController = TextEditingController();
  final _mode = ValueNotifier<String>('auto');
  DateTime _date = DateTime.now();
  bool _saving = false;
  bool _blocked = false;
  String? _blockedMessage;

  @override
  void initState() {
    super.initState();
    _validateReceivableState();
  }

  @override
  void dispose() {
    _totalController.dispose();
    _principalController.dispose();
    _interestController.dispose();
    _mode.dispose();
    super.dispose();
  }

  double get _maxTotal => widget.maxPrincipalAmount + widget.maxInterestAmount;

  Future<void> _validateReceivableState() async {
    if (_maxTotal <= 0.005) {
      if (!mounted) return;
      setState(() {
        _blocked = true;
        _blockedMessage = 'Cuenta saldada: no admite pagos';
      });
      return;
    }
    try {
      final repo = ReceivableRepositoryImpl();
      final get = GetReceivableDetail(repo);
      final detail = await get(widget.receivableId);
      if (!mounted) return;
      if (detail == null || !detail.canRegisterPayment) {
        setState(() {
          _blocked = true;
          _blockedMessage = 'Cuenta cerrada o saldada: no admite pagos';
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _blocked = true;
        _blockedMessage =
            'No se puede registrar pago porque no se pudo validar el estado de la cuenta';
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked == null) return;
    setState(() => _date = picked);
  }

  Future<void> _save(BuildContext context) async {
    if (_saving) return;
    if (_blocked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_blockedMessage ?? 'Cuenta no admite pagos')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final rawTotal = _totalController.text.trim().replaceAll(',', '.');
      final total = double.tryParse(rawTotal) ?? 0;
      final mode = _mode.value;
      if (total <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El monto debe ser mayor a 0')),
        );
        return;
      }
      if (total > _maxTotal + 0.001) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El pago no puede exceder el saldo')),
        );
        return;
      }

      double? principalManual;
      double? interestManual;
      if (mode == 'mixed_manual') {
        final rawP = _principalController.text.trim().replaceAll(',', '.');
        final rawI = _interestController.text.trim().replaceAll(',', '.');
        principalManual = double.tryParse(rawP) ?? 0;
        interestManual = double.tryParse(rawI) ?? 0;
        final sum = principalManual + interestManual;
        if (principalManual < 0 || interestManual < 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No se permiten valores negativos')),
          );
          return;
        }
        if ((sum - total).abs() > 0.01) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Capital + interés debe coincidir con el total'),
            ),
          );
          return;
        }
      }

      final repo = ReceivableRepositoryImpl();
      final register = RegisterReceivablePayment(repo);
      await register(
        RegisterPaymentRequest(
          receivableId: widget.receivableId,
          totalAmount: total,
          paidAt: _date,
          mode: mode,
          principalAmount: principalManual,
          interestAmount: interestManual,
          note: null,
        ),
      );
      if (!context.mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo registrar el pago')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar pago')),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving || _blocked ? null : () => _save(context),
            icon: _saving
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_blocked) ...[
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListTile(
                    leading: const Icon(Icons.lock_outline),
                    title: const Text('Cuenta cerrada'),
                    subtitle: Text(_blockedMessage ?? 'Cuenta no admite pagos'),
                    trailing: FilledButton.tonalIcon(
                      onPressed: () => Navigator.of(context).pop(false),
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Volver'),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Card(
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Distribución del pago',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 10),
                      ValueListenableBuilder(
                        valueListenable: _mode,
                        builder: (context, mode, _) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              PaymentTypeSelector(
                                value: mode,
                                onChanged: (v) => _mode.value = v,
                              ),
                              const SizedBox(height: 10),
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.info_outline,
                                        size: 18,
                                        color: scheme.onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          'Capital: ${formatMoney(widget.maxPrincipalAmount)} · Interés: ${formatMoney(widget.maxInterestAmount)} · Total: ${formatMoney(_maxTotal)}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: scheme.onSurfaceVariant,
                                                fontWeight: FontWeight.w700,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (mode == 'mixed_manual') ...[
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _principalController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Capital',
                                    hintText: '0.00',
                                    prefixText: 'C\$ ',
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextField(
                                  controller: _interestController,
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                        decimal: true,
                                      ),
                                  decoration: const InputDecoration(
                                    labelText: 'Interés',
                                    hintText: '0.00',
                                    prefixText: 'C\$ ',
                                  ),
                                ),
                              ],
                            ],
                          );
                        },
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
                        controller: _totalController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'Monto total',
                          hintText: '0.00',
                          prefixText: 'C\$ ',
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.calendar_today_outlined),
                        title: const Text('Fecha'),
                        subtitle: Text(formatDate(_date)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _pickDate(context),
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
  }
}
