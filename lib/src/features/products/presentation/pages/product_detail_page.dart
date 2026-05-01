import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:app/src/features/products/presentation/controllers/product_detail_controller.dart';
import 'package:app/src/features/products/presentation/pages/product_form_page.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:app/src/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductDetailArgs {
  const ProductDetailArgs({required this.productId});

  final String productId;
}

class ProductDetailPage extends StatefulWidget {
  const ProductDetailPage({super.key, required this.args});

  static const routeName = '/detail';

  final ProductDetailArgs args;

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  late final ProductDetailController _controller;

  @override
  void initState() {
    super.initState();
    final repository = ProductRepositoryImpl();
    _controller = ProductDetailController(
      productId: widget.args.productId,
      getProductById: GetProductById(repository),
      getPriceHistory: GetProductPriceHistory(repository),
      deleteProduct: DeleteProduct(repository),
    )..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openEdit() async {
    await Navigator.of(context).pushNamed(
      ProductFormPage.routeName,
      arguments: ProductFormArgs(productId: widget.args.productId),
    );
    await _controller.load();
  }

  Future<void> _confirmDelete() async {
    final product = _controller.product;
    if (product == null) return;

    final shouldDelete = await showConfirmationBottomSheet(
      context: context,
      icon: Icons.delete_outline,
      title: 'Eliminar producto',
      headline: product.name,
      supportingText: 'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar',
      confirmIcon: Icons.delete_outline,
    );

    if (shouldDelete != true) return;

    await _controller.delete();

    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  void _openActions() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.edit_outlined),
                  title: const Text('Editar producto'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _openEdit();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.delete_outline),
                  title: const Text('Eliminar producto'),
                  textColor: Theme.of(context).colorScheme.error,
                  iconColor: Theme.of(context).colorScheme.error,
                  onTap: () {
                    Navigator.of(context).pop();
                    _confirmDelete();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ProductDetailController>(
        builder: (context, c, _) {
          final product = c.product;
          final colorScheme = Theme.of(context).colorScheme;

          return Scaffold(
            appBar: AppBar(
              title: const Text('Detalle de producto'),
              actions: [
                IconButton(
                  tooltip: 'Editar',
                  onPressed: c.loading || product == null ? null : _openEdit,
                  icon: const Icon(Icons.edit_outlined),
                ),
                IconButton(
                  tooltip: 'Más opciones',
                  onPressed: c.loading || product == null ? null : _openActions,
                  icon: const Icon(Icons.more_vert),
                ),
              ],
            ),
            body: c.loading
                ? const Center(child: CircularProgressIndicator())
                : product == null
                ? const Center(child: Text('Producto no encontrado'))
                : RefreshIndicator(
                    onRefresh: _controller.load,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                      children: [
                        _ProductHeaderCard(product: product),
                        const SizedBox(height: 12),
                        _PriceSectionCard(product: product),
                        const SizedBox(height: 12),
                        _ProfitCard(
                          profit: product.marginAmount,
                          percent: product.marginPercent,
                        ),
                        const SizedBox(height: 12),
                        _InventoryCard(product: product),
                        const SizedBox(height: 12),
                        _AdminDataCard(product: product),
                        const SizedBox(height: 20),
                        Text(
                          'Historial de precios',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 8),
                        if (c.history.isEmpty)
                          _EmptyHistoryCard(colorScheme: colorScheme)
                        else
                          _PriceHistoryCard(history: c.history),
                      ],
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _ProductHeaderCard extends StatelessWidget {
  const _ProductHeaderCard({required this.product});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            product.name,
            style: textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.qr_code_2_outlined,
            label: 'SKU',
            value: product.sku,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.category_outlined,
            label: 'Categoría',
            value: product.category,
          ),
          if ((product.subcategory ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.account_tree_outlined,
              label: 'Subcategoría',
              value: product.subcategory!,
            ),
          ],
          if ((product.brand ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.branding_watermark_outlined,
              label: 'Marca',
              value: product.brand!,
            ),
          ],
          if ((product.barcode ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            _InfoRow(
              icon: Icons.qr_code_outlined,
              label: 'Código de barras',
              value: product.barcode!,
            ),
          ],
        ],
      ),
    );
  }
}

class _PriceSectionCard extends StatelessWidget {
  const _PriceSectionCard({required this.product});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Precios',
      icon: Icons.sell_outlined,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.payments_outlined,
            label: 'Costo con IVA',
            value: formatMoney(product.costPrice),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.receipt_long_outlined,
            label: 'Costo sin IVA',
            value: formatMoney(product.costPriceWithoutVat),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.local_offer_outlined,
            label: 'Precio de venta',
            value: formatMoney(product.salePrice),
            emphasized: true,
          ),
        ],
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({required this.product});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    final stock = product.stock as double;
    final minStock = product.minStock as double;
    final allowDecimal = product.allowDecimalQuantity as bool;

    final stockText = stock.toStringAsFixed(allowDecimal ? 2 : 0);
    final minStockText = minStock.toStringAsFixed(allowDecimal ? 2 : 0);

    final status = _stockStatus(stock, minStock);
    final colorScheme = Theme.of(context).colorScheme;

    final Color containerColor;
    final Color labelColor;

    switch (status) {
      case _StockStatus.out:
        containerColor = colorScheme.errorContainer;
        labelColor = colorScheme.onErrorContainer;
        break;
      case _StockStatus.low:
        containerColor = colorScheme.tertiaryContainer;
        labelColor = colorScheme.onTertiaryContainer;
        break;
      case _StockStatus.available:
        containerColor = colorScheme.primaryContainer;
        labelColor = colorScheme.onPrimaryContainer;
        break;
    }

    return _SectionCard(
      title: 'Inventario',
      icon: Icons.inventory_2_outlined,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.inventory_2_outlined,
            label: 'Stock actual',
            value: stockText,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.production_quantity_limits_outlined,
            label: 'Stock mínimo',
            value: minStockText,
          ),
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              avatar: Icon(
                status == _StockStatus.out
                    ? Icons.error_outline
                    : status == _StockStatus.low
                    ? Icons.warning_amber_outlined
                    : Icons.check_circle_outline,
                size: 18,
                color: labelColor,
              ),
              label: Text(_stockStatusLabel(status)),
              backgroundColor: containerColor,
              labelStyle: TextStyle(
                color: labelColor,
                fontWeight: FontWeight.w800,
              ),
              side: BorderSide.none,
            ),
          ),
        ],
      ),
    );
  }

  _StockStatus _stockStatus(double stock, double minStock) {
    if (stock <= 0) return _StockStatus.out;
    if (minStock > 0 && stock <= minStock) return _StockStatus.low;
    return _StockStatus.available;
  }

  String _stockStatusLabel(_StockStatus status) {
    switch (status) {
      case _StockStatus.out:
        return 'Sin stock';
      case _StockStatus.low:
        return 'Stock bajo';
      case _StockStatus.available:
        return 'Disponible';
    }
  }
}

enum _StockStatus { available, low, out }

class _AdminDataCard extends StatelessWidget {
  const _AdminDataCard({required this.product});

  final dynamic product;

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'Datos administrativos',
      icon: Icons.info_outline,
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.straighten_outlined,
            label: 'Unidad',
            value: product.unitOfMeasure,
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.request_quote_outlined,
            label: 'Impuesto',
            value: _taxLabel(product.taxType),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.toggle_on_outlined,
            label: 'Estado',
            value: product.isActive ? 'Activo' : 'Inactivo',
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Creado',
            value: formatDateTime(product.createdAt),
          ),
          const SizedBox(height: 10),
          _InfoRow(
            icon: Icons.update_outlined,
            label: 'Actualizado',
            value: formatDateTime(product.updatedAt),
          ),
        ],
      ),
    );
  }

  String _taxLabel(String taxType) {
    switch (taxType) {
      case 'iva_incluido':
        return 'IVA incluido';
      case 'sin_iva':
        return 'Sin IVA';
      default:
        return taxType;
    }
  }
}

class _PriceHistoryCard extends StatelessWidget {
  const _PriceHistoryCard({required this.history});

  final List<dynamic> history;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: history.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final h = history[index];
          final isCurrent = index == 0;

          return ListTile(
            leading: Icon(
              isCurrent ? Icons.price_check_outlined : Icons.history,
            ),
            title: Text(
              isCurrent ? 'Precio actual' : 'Cambio de precio',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Costo: ${formatMoney(h.costPrice)}  •  Venta: ${formatMoney(h.salePrice ?? 0)}\n${formatDateTime(h.recordedAt)}',
              ),
            ),
            isThreeLine: true,
          );
        },
      ),
    );
  }
}

class _EmptyHistoryCard extends StatelessWidget {
  const _EmptyHistoryCard({required this.colorScheme});

  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Icon(Icons.history_toggle_off, color: colorScheme.onSurfaceVariant),
            const SizedBox(width: 12),
            Text(
              'Sin historial de precios',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.child, this.title, this.icon});

  final Widget child;
  final String? title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Row(
                children: [
                  if (icon != null) ...[
                    Icon(icon, color: colorScheme.primary),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    title!,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
            ],
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: (emphasized ? textTheme.titleLarge : textTheme.titleMedium)
                ?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
      ],
    );
  }
}

class _ProfitCard extends StatelessWidget {
  const _ProfitCard({required this.profit, required this.percent});

  final double profit;
  final double percent;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isLoss = profit < 0;
    final bg = isLoss
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final fg = isLoss
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              isLoss ? Icons.trending_down : Icons.trending_up,
              color: fg,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ProfitMetric(
                label: 'Ganancia unitaria',
                value: formatMoney(profit),
                color: fg,
                alignEnd: false,
              ),
            ),
            const SizedBox(width: 12),
            _ProfitMetric(
              label: 'Margen',
              value: formatPercent(percent),
              color: fg,
              alignEnd: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfitMetric extends StatelessWidget {
  const _ProfitMetric({
    required this.label,
    required this.value,
    required this.color,
    required this.alignEnd,
  });

  final String label;
  final String value;
  final Color color;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: color,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
