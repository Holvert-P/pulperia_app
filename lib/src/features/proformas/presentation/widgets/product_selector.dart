import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:app/src/features/proformas/presentation/controllers/product_selector_controller.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:app/src/shared/widgets/custom_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductSelector extends StatefulWidget {
  const ProductSelector({super.key, required this.onSelected});

  final void Function(Product product, int quantity) onSelected;

  static Future<void> show(
    BuildContext context, {
    required void Function(Product product, int quantity) onSelected,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => ProductSelector(onSelected: onSelected),
    );
  }

  @override
  State<ProductSelector> createState() => _ProductSelectorState();
}

class _ProductSelectorState extends State<ProductSelector> {
  final _searchController = TextEditingController();

  late final ProductSelectorController _controller;

  @override
  void initState() {
    super.initState();
    final repository = ProductRepositoryImpl();
    _controller = ProductSelectorController(
      getProducts: GetProducts(repository),
      searchProducts: SearchProducts(repository),
    )..loadAll();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _controller.search(_searchController.text);
  }

  Future<int?> _askQuantity(BuildContext context, Product product) async {
    var qty = 1;
    return showModalBottomSheet<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_cart_outlined),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Cantidad',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w900),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      product.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Precio: ${formatMoney(product.salePrice)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Text('Cantidad:'),
                        const Spacer(),
                        IconButton(
                          onPressed: () => setState(() {
                            qty = (qty - 1) < 1 ? 1 : (qty - 1);
                          }),
                          icon: const Icon(Icons.remove),
                          visualDensity: VisualDensity.compact,
                        ),
                        SizedBox(
                          width: 40,
                          child: Text(
                            '$qty',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        IconButton(
                          onPressed: () => setState(() => qty = qty + 1),
                          icon: const Icon(Icons.add),
                          visualDensity: VisualDensity.compact,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
                            onPressed: () => Navigator.of(context).pop(qty),
                            icon: const Icon(Icons.add),
                            label: const Text('Agregar'),
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

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ProductSelectorController>(
        builder: (context, c, _) {
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                bottom: 16 + media.viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CustomSearchBar(
                    controller: _searchController,
                    hintText: 'Buscar producto',
                    onChanged: c.search,
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: c.loading
                        ? const Center(child: CircularProgressIndicator())
                        : c.products.isEmpty
                            ? const _EmptyProducts()
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: c.products.length,
                                separatorBuilder: (context, index) =>
                                    const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final p = c.products[index];
                                  return Card(
                                    child: ListTile(
                                      title: Text(p.name),
                                      subtitle: Text(
                                        'Precio: ${formatMoney(p.salePrice)}',
                                      ),
                                      trailing: const Icon(Icons.add),
                                      onTap: () async {
                                        final qty = await _askQuantity(context, p);
                                        if (!context.mounted) return;
                                        if (qty == null) return;
                                        widget.onSelected(p, qty);
                                        Navigator.of(context).pop();
                                      },
                                    ),
                                  );
                                },
                              ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EmptyProducts extends StatelessWidget {
  const _EmptyProducts();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_off, size: 56, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 10),
          Text(
            'Sin resultados',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Intenta con otro nombre.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
