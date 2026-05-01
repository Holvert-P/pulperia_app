import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/services/product_financials.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';

class ProductFormArgs {
  const ProductFormArgs({this.productId});

  final String? productId;
}

class ProductFormPage extends StatefulWidget {
  const ProductFormPage({super.key, this.args});

  static const routeName = '/form';

  final ProductFormArgs? args;

  @override
  State<ProductFormPage> createState() => _ProductFormPageState();
}

class _ProductFormPageState extends State<ProductFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _skuController = TextEditingController();
  final _nameController = TextEditingController();
  final _brandController = TextEditingController();
  final _categoryController = TextEditingController();
  final _subcategoryController = TextEditingController();
  final _unitController = TextEditingController(text: 'unidad');
  final _barcodeController = TextEditingController();
  final _costController = TextEditingController();
  final _saleController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');

  late final ProductRepositoryImpl _repository;
  late final GetProductById _getProductById;
  late final CreateProduct _createProduct;
  late final UpdateProduct _updateProduct;
  late final RecalculateProductFinancials _recalculateFinancials;

  bool _loading = false;
  bool _isActive = true;
  bool _allowDecimalQuantity = false;
  String? _productId;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    _repository = ProductRepositoryImpl();
    _getProductById = GetProductById(_repository);
    _createProduct = CreateProduct(_repository);
    _updateProduct = UpdateProduct(_repository);
    _recalculateFinancials = const RecalculateProductFinancials();

    _skuController.addListener(_onFieldsChanged);
    _nameController.addListener(_onFieldsChanged);
    _brandController.addListener(_onFieldsChanged);
    _categoryController.addListener(_onFieldsChanged);
    _subcategoryController.addListener(_onFieldsChanged);
    _unitController.addListener(_onFieldsChanged);
    _barcodeController.addListener(_onFieldsChanged);
    _costController.addListener(_onFieldsChanged);
    _saleController.addListener(_onFieldsChanged);
    _stockController.addListener(_onFieldsChanged);
    _minStockController.addListener(_onFieldsChanged);

    _productId = widget.args?.productId;
    if (_productId != null) {
      _loadExisting(_productId!);
    }
  }

  @override
  void dispose() {
    _skuController.removeListener(_onFieldsChanged);
    _nameController.removeListener(_onFieldsChanged);
    _brandController.removeListener(_onFieldsChanged);
    _categoryController.removeListener(_onFieldsChanged);
    _subcategoryController.removeListener(_onFieldsChanged);
    _unitController.removeListener(_onFieldsChanged);
    _barcodeController.removeListener(_onFieldsChanged);
    _costController.removeListener(_onFieldsChanged);
    _saleController.removeListener(_onFieldsChanged);
    _stockController.removeListener(_onFieldsChanged);
    _minStockController.removeListener(_onFieldsChanged);
    _skuController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _categoryController.dispose();
    _subcategoryController.dispose();
    _unitController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _saleController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    setState(() {});
  }

  double? _parseMoney(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }

  double? get _costValue => _parseMoney(_costController.text);
  double? get _saleValue => _parseMoney(_saleController.text);

  double? get _stockValue => _parseMoney(_stockController.text);
  double? get _minStockValue => _parseMoney(_minStockController.text);

  ProductFinancialSnapshot get _financials => _recalculateFinancials(
    costPrice: _costValue ?? 0,
    salePrice: _saleValue ?? 0,
    taxType: 'iva_incluido',
    vatRateApplied: 0.15,
  );

  bool get _isLoss => _financials.marginAmount < 0;

  Future<void> _loadExisting(String id) async {
    setState(() => _loading = true);
    final product = await _getProductById(id);
    if (!mounted) return;
    if (product == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() {
      _createdAt = product.createdAt;
      _skuController.text = product.sku;
      _nameController.text = product.name;
      _brandController.text = product.brand ?? '';
      _categoryController.text = product.category;
      _subcategoryController.text = product.subcategory ?? '';
      _unitController.text = product.unitOfMeasure;
      _barcodeController.text = product.barcode ?? '';
      _costController.text = product.costPrice.toStringAsFixed(2);
      _saleController.text = product.salePrice.toStringAsFixed(2);
      _stockController.text = product.stock.toStringAsFixed(
        product.allowDecimalQuantity ? 2 : 0,
      );
      _minStockController.text = product.minStock.toStringAsFixed(
        product.allowDecimalQuantity ? 2 : 0,
      );
      _isActive = product.isActive;
      _allowDecimalQuantity = product.allowDecimalQuantity;
      _loading = false;
    });
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) return;

    final cost = _costValue!;
    final sale = _saleValue!;
    final stock = _stockValue ?? 0;
    final minStock = _minStockValue ?? 0;

    if (sale < cost) {
      await showModalBottomSheet<void>(
        context: context,
        showDragHandle: true,
        builder: (context) {
          final scheme = Theme.of(context).colorScheme;
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber_outlined, color: scheme.error),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Pérdida detectada',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text('El precio de venta no puede ser menor al costo.'),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Entendido'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
      return;
    }

    setState(() => _loading = true);
    final now = DateTime.now();
    final name = _nameController.text.trim();
    final category = ProductTextNormalizer.normalizeCategory(
      _categoryController.text.trim(),
    );
    final subcategoryRaw = _subcategoryController.text.trim();
    final financials = _financials;
    final product = Product(
      id: _productId ?? now.microsecondsSinceEpoch.toString(),
      sku: _skuController.text.trim(),
      name: name,
      normalizedName: ProductTextNormalizer.normalizeName(name),
      brand: _brandController.text.trim().isEmpty
          ? null
          : _brandController.text.trim(),
      category: category,
      subcategory: subcategoryRaw.isEmpty
          ? null
          : ProductTextNormalizer.normalizeCategory(subcategoryRaw),
      unitOfMeasure: _unitController.text.trim().isEmpty
          ? 'unidad'
          : _unitController.text.trim(),
      barcode: _barcodeController.text.trim().isEmpty
          ? null
          : _barcodeController.text.trim(),
      costPrice: cost,
      costPriceWithoutVat: financials.costPriceWithoutVat,
      salePrice: sale,
      marginAmount: financials.marginAmount,
      marginPercent: financials.marginPercent,
      currency: 'NIO',
      taxType: 'iva_incluido',
      vatRateApplied: 0.15,
      vatAmountOnCost: financials.vatAmountOnCost,
      stock: stock,
      minStock: minStock,
      isActive: _isActive,
      allowDecimalQuantity: _allowDecimalQuantity,
      createdAt: _createdAt ?? now,
      updatedAt: now,
    );

    if (_productId == null) {
      await _createProduct(product);
    } else {
      await _updateProduct(product);
    }

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _productId != null;
    final canSave = !_loading;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar producto' : 'Agregar producto'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _MetricsCard(
                      profit: _financials.marginAmount,
                      profitPercent: _financials.marginPercent,
                      isLoss: _isLoss,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _skuController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'SKU',
                        prefixIcon: Icon(Icons.qr_code_2_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autofocus: !isEdit,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.inventory_2_outlined),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'El nombre es requerido';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _brandController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Marca',
                        prefixIcon: Icon(Icons.branding_watermark_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _categoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'La categoria es requerida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _subcategoryController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Subcategoria',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _unitController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Unidad de medida',
                        prefixIcon: Icon(Icons.straighten_outlined),
                      ),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return 'La unidad es requerida';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _barcodeController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Codigo de barras',
                        prefixIcon: Icon(Icons.qr_code_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _costController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Precio de costo',
                        prefixIcon: Icon(Icons.payments_outlined),
                      ),
                      validator: (value) {
                        final v = _parseMoney(value ?? '');
                        if (v == null) return 'Ingresa un número';
                        if (v < 0) return 'No puede ser negativo';
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _saleController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Precio de venta',
                        prefixIcon: Icon(Icons.sell_outlined),
                      ),
                      validator: (value) {
                        final v = _parseMoney(value ?? '');
                        if (v == null) return 'Ingresa un número';
                        if (v < 0) return 'No puede ser negativo';
                        return null;
                      },
                      onFieldSubmitted: (_) => canSave ? _save() : null,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _stockController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Stock',
                              prefixIcon: Icon(Icons.inventory_2_outlined),
                            ),
                            validator: (value) {
                              final v = _parseMoney(value ?? '');
                              if (v == null) return 'Numero invalido';
                              if (v < 0) return 'No puede ser negativo';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _minStockController,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            textInputAction: TextInputAction.next,
                            decoration: const InputDecoration(
                              labelText: 'Minimo',
                              prefixIcon: Icon(Icons.warning_amber_outlined),
                            ),
                            validator: (value) {
                              final v = _parseMoney(value ?? '');
                              if (v == null) return 'Numero invalido';
                              if (v < 0) return 'No puede ser negativo';
                              return null;
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      value: _allowDecimalQuantity,
                      onChanged: _loading
                          ? null
                          : (value) =>
                                setState(() => _allowDecimalQuantity = value),
                      title: const Text('Permitir cantidad decimal'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: _loading
                          ? null
                          : (value) => setState(() => _isActive = value),
                      title: const Text('Producto activo'),
                      contentPadding: EdgeInsets.zero,
                    ),
                    if (_createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Creado: ${formatDateTime(_createdAt!)}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    const SizedBox(height: 8),
                    if (_isLoss)
                      Card(
                        color: colorScheme.errorContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Icon(
                                Icons.warning_amber_outlined,
                                color: colorScheme.onErrorContainer,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Pérdida: el precio de venta es menor al costo.',
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(
                                        color: colorScheme.onErrorContainer,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                              TextButton(
                                onPressed: () {
                                  final cost = _costValue;
                                  if (cost == null) return;
                                  _saleController.text = cost.toStringAsFixed(
                                    2,
                                  );
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: colorScheme.onErrorContainer,
                                ),
                                child: const Text('Igualar'),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canSave && !_isLoss ? _save : null,
            icon: const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'Guardar cambios' : 'Guardar'),
          ),
        ),
      ),
    );
  }
}

class _MetricsCard extends StatelessWidget {
  const _MetricsCard({
    required this.profit,
    required this.profitPercent,
    required this.isLoss,
  });

  final double profit;
  final double profitPercent;
  final bool isLoss;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bg = isLoss
        ? colorScheme.errorContainer
        : colorScheme.primaryContainer;
    final fg = isLoss
        ? colorScheme.onErrorContainer
        : colorScheme.onPrimaryContainer;

    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(isLoss ? Icons.trending_down : Icons.trending_up, color: fg),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ganancia',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatMoney(profit),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: fg,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Porcentaje',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  formatPercent(profitPercent),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w900,
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
