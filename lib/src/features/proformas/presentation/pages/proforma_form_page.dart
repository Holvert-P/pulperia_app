import 'package:app/src/features/proformas/data/repositories/proforma_repository_impl.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:app/src/features/proformas/presentation/controllers/proforma_form_controller.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_detail_page.dart';
import 'package:app/src/features/proformas/presentation/widgets/product_selector.dart';
import 'package:app/src/features/proformas/presentation/widgets/proforma_item_card.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProformaFormArgs {
  const ProformaFormArgs({this.proformaId});

  final String? proformaId;
}

class ProformaFormPage extends StatefulWidget {
  const ProformaFormPage({super.key, required this.args});

  static const routeName = '/proformas/form';

  final ProformaFormArgs args;

  @override
  State<ProformaFormPage> createState() => _ProformaFormPageState();
}

class _ProformaFormPageState extends State<ProformaFormPage> {
  late final TextEditingController _customerController;
  late final TextEditingController _discountController;
  late final FocusNode _customerFocusNode;
  late final FocusNode _discountFocusNode;
  late final ProformaFormController _controller;

  double _parseAmount(String input) {
    final normalized = input.trim().replaceAll(',', '.');
    return double.tryParse(normalized) ?? 0.0;
  }

  @override
  void initState() {
    super.initState();
    _customerController = TextEditingController();
    _discountController = TextEditingController();
    _customerFocusNode = FocusNode();
    _discountFocusNode = FocusNode();

    final repository = ProformaRepositoryImpl();
    _controller = ProformaFormController(
      createProforma: CreateProforma(repository),
      updateProforma: UpdateProforma(repository),
      getProformaById: GetProformaById(repository),
      proformaId: widget.args.proformaId,
    );

    _customerController.addListener(() {
      _controller.setCustomerName(_customerController.text);
    });
    _discountController.addListener(() {
      _controller.setDiscount(_parseAmount(_discountController.text));
    });

    void onFocusChanged() {
      if (!mounted) return;
      setState(() {});
    }

    _customerFocusNode.addListener(onFocusChanged);
    _discountFocusNode.addListener(onFocusChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.loadIfEditing();
      if (!mounted) return;
      _customerController.text = _controller.customerName;
      _discountController.text = _controller.discount.toStringAsFixed(2);
    });
  }

  @override
  void dispose() {
    _customerController.dispose();
    _discountController.dispose();
    _customerFocusNode.dispose();
    _discountFocusNode.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _addProduct(BuildContext context) async {
    await ProductSelector.show(
      context,
      onSelected: (p, qty) => _controller.addProductWithQuantity(p, qty),
    );
  }

  Future<void> _save(BuildContext context) async {
    final ok = await _controller.save();
    final message = _controller.error;
    if (!context.mounted) return;
    if (!ok) {
      if (message != null) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(message)));
      }
      return;
    }
    final id = _controller.lastSavedId;
    if (_controller.isEdit || id == null) {
      Navigator.of(context).pop(true);
      return;
    }
    await Navigator.of(context).pushReplacementNamed<bool, bool>(
      ProformaDetailPage.routeName,
      arguments: ProformaDetailArgs(proformaId: id),
      result: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ProformaFormController>(
        builder: (context, c, _) {
          final canEdit = !(c.loading || c.saving);
          final keyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;
          final showDiscount = !keyboardOpen || _discountFocusNode.hasFocus;
          return Scaffold(
            appBar: AppBar(
              title: Text(c.isEdit ? 'Editar proforma' : 'Nueva proforma'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: c.loading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          TextField(
                            controller: _customerController,
                            focusNode: _customerFocusNode,
                            textCapitalization: TextCapitalization.words,
                            decoration: const InputDecoration(
                              labelText: 'Cliente',
                              hintText: 'Nombre del cliente',
                            ),
                          ),
                          const SizedBox(height: 12),
                          Expanded(
                            child: c.items.isEmpty
                                ? _EmptyItems(onAdd: () => _addProduct(context))
                                : ListView.separated(
                                    itemCount: c.items.length,
                                    separatorBuilder: (context, index) =>
                                        const SizedBox(height: 6),
                                    itemBuilder: (context, index) {
                                      final item = c.items[index];
                                      return ProformaItemCard(
                                        item: item,
                                        onRemove: () => c.removeItemAt(index),
                                        onQuantityChanged: (q) =>
                                            c.setQuantity(index, q),
                                        onPriceChanged: (p) =>
                                            c.setPrice(index, p),
                                      );
                                    },
                                  ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: showDiscount
                                ? Padding(
                                    padding: const EdgeInsets.only(top: 12),
                                    child: TextField(
                                      key: const ValueKey('discount-input'),
                                      controller: _discountController,
                                      focusNode: _discountFocusNode,
                                      keyboardType:
                                          const TextInputType.numberWithOptions(
                                            decimal: true,
                                          ),
                                      decoration: const InputDecoration(
                                        labelText: 'Descuento',
                                        hintText: '0.00',
                                        prefixText: 'C\$ ',
                                        isDense: true,
                                      ),
                                    ),
                                  )
                                : const SizedBox.shrink(
                                    key: ValueKey('discount-hidden'),
                                  ),
                          ),
                        ],
                      ),
              ),
            ),
            bottomNavigationBar: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Subtotal',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const Spacer(),
                                Text(
                                  formatMoney(c.subtotal),
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                            if (c.discount > 0) ...[
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Text(
                                    'Descuento',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '- ${formatMoney(c.discount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const Spacer(),
                                Text(
                                  formatMoney(c.total),
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: canEdit
                                ? () => _addProduct(context)
                                : null,
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: c.saving ? null : () => _save(context),
                            icon: c.saving
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: const Text('Guardar'),
                          ),
                        ),
                      ],
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

class _EmptyItems extends StatelessWidget {
  const _EmptyItems({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.playlist_add, size: 44, color: colorScheme.primary),
                const SizedBox(height: 10),
                Text(
                  'Agrega productos',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'La proforma no puede guardarse vacía.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
