import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:app/src/features/products/presentation/controllers/product_list_controller.dart';
import 'package:app/src/features/products/presentation/pages/product_detail_page.dart';
import 'package:app/src/features/products/presentation/pages/product_form_page.dart';
import 'package:app/src/features/products/presentation/widgets/product_card.dart';
import 'package:app/src/features/products/presentation/widgets/product_empty_state.dart';
import 'package:app/src/features/products/presentation/widgets/product_filtered_empty_state.dart';
import 'package:app/src/features/products/presentation/widgets/product_list_header.dart';
import 'package:app/src/features/products/presentation/widgets/product_quick_filters.dart';
import 'package:app/src/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProductListPage extends StatefulWidget {
  const ProductListPage({super.key, this.showBottomNavigation = true});

  static const routeName = '/products';

  final bool showBottomNavigation;

  @override
  State<ProductListPage> createState() => _ProductListPageState();
}

class _ProductListPageState extends State<ProductListPage> {
  final _searchController = TextEditingController();

  late final ProductListController _controller;

  ProductQuickFilter _selectedFilter = ProductQuickFilter.all;

  @override
  void initState() {
    super.initState();

    final repository = ProductRepositoryImpl();

    _controller = ProductListController(
      getAllProducts: GetAllProducts(repository),
      searchProducts: SearchProducts(repository),
      deleteProduct: DeleteProduct(repository),
    )..loadAll();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openCreate() async {
    await Navigator.of(context).pushNamed(ProductFormPage.routeName);
    await _controller.refresh();
  }

  Future<void> _openDetail(Product product) async {
    await Navigator.of(context).pushNamed(
      ProductDetailPage.routeName,
      arguments: ProductDetailArgs(productId: product.id),
    );

    await _controller.refresh();
  }

  Future<void> _confirmDelete(Product product) async {
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

    await _controller.deleteById(product.id);

    if (!mounted) return;
    await _controller.refresh();
  }

  void _changeFilter(ProductQuickFilter filter) {
    setState(() {
      _selectedFilter = filter;
    });
  }

  List<Product> _applyQuickFilter(List<Product> products) {
    switch (_selectedFilter) {
      case ProductQuickFilter.all:
        return products;

      case ProductQuickFilter.available:
        return products.where((p) => p.stock > 0).toList();

      case ProductQuickFilter.lowStock:
        return products.where((p) {
          return p.stock > 0 && p.minStock > 0 && p.stock <= p.minStock;
        }).toList();

      case ProductQuickFilter.outOfStock:
        return products.where((p) => p.stock <= 0).toList();

      case ProductQuickFilter.inactive:
        return products.where((p) => !p.isActive).toList();
    }
  }

  int _countByFilter(List<Product> products, ProductQuickFilter filter) {
    switch (filter) {
      case ProductQuickFilter.all:
        return products.length;

      case ProductQuickFilter.available:
        return products.where((p) => p.stock > 0).length;

      case ProductQuickFilter.lowStock:
        return products.where((p) {
          return p.stock > 0 && p.minStock > 0 && p.stock <= p.minStock;
        }).length;

      case ProductQuickFilter.outOfStock:
        return products.where((p) => p.stock <= 0).length;

      case ProductQuickFilter.inactive:
        return products.where((p) => !p.isActive).length;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _controller,
      child: Consumer<ProductListController>(
        builder: (context, c, _) {
          final visibleProducts = _applyQuickFilter(c.products);

          return Scaffold(
            appBar: AppBar(
              toolbarHeight: 76,
              leadingWidth: 72,
              leading: Padding(
                padding: const EdgeInsets.all(12),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Productos'),
                  const SizedBox(height: 2),
                  Text(
                    c.loading
                        ? 'Cargando catálogo...'
                        : '${c.products.length} productos registrados',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            floatingActionButton: FloatingActionButton.extended(
              heroTag: 'products_fab',
              onPressed: _openCreate,
              icon: const Icon(Icons.add),
              label: const Text('Agregar'),
            ),
            body: SafeArea(
              child: RefreshIndicator(
                onRefresh: _controller.refresh,
                child: CustomScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CustomSearchBar(
                              controller: _searchController,
                              hintText: 'Buscar producto',
                              onChanged: c.loadSearch,
                            ),
                            const SizedBox(height: 12),
                            ProductQuickFilters(
                              selected: _selectedFilter,
                              products: c.products,
                              onSelected: _changeFilter,
                              countByFilter: _countByFilter,
                            ),
                            const SizedBox(height: 12),
                            ProductListHeader(
                              total: visibleProducts.length,
                              filter: _selectedFilter,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (c.loading)
                      const SliverFillRemaining(
                        hasScrollBody: false,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (c.products.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ProductEmptyState(
                          onAdd: _openCreate,
                          isSearching: _searchController.text.trim().isNotEmpty,
                        ),
                      )
                    else if (visibleProducts.isEmpty)
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ProductFilteredEmptyState(
                          onClear: () {
                            _changeFilter(ProductQuickFilter.all);
                          },
                        ),
                      )
                    else
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 128),
                        sliver: SliverList.separated(
                          itemCount: visibleProducts.length,
                          separatorBuilder: (context, index) {
                            return const SizedBox(height: 12);
                          },
                          itemBuilder: (context, index) {
                            final product = visibleProducts[index];

                            return ProductCard(
                              product: product,
                              onTap: () => _openDetail(product),
                              onDelete: () => _confirmDelete(product),
                            );
                          },
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
