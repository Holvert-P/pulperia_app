import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:app/src/features/products/data/repositories/product_repository_impl.dart';
import 'package:app/src/features/products/domain/entities/product.dart';
import 'package:app/src/features/products/domain/services/product_financials.dart';
import 'package:app/src/features/products/domain/services/product_sku_generator.dart';
import 'package:app/src/features/products/domain/services/product_text_normalizer.dart';
import 'package:app/src/features/products/domain/usecases/product_usecases.dart';
import 'package:app/src/features/products/presentation/widgets/product_form_field.dart';
import 'package:app/src/features/products/presentation/widgets/product_form_section_card.dart';
import 'package:app/src/features/products/presentation/widgets/product_profit_summary_card.dart';
import 'package:app/src/features/products/presentation/widgets/product_selector_field.dart';
import 'package:app/src/features/products/presentation/widgets/product_status_switch_tile.dart';
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
  final _barcodeController = TextEditingController();
  final _costController = TextEditingController();
  final _costWithoutVatController = TextEditingController(text: '0.00');
  final _saleController = TextEditingController();
  final _stockController = TextEditingController(text: '0');
  final _minStockController = TextEditingController(text: '0');

  late final GetProductById _getProductById;
  late final CreateProduct _createProduct;
  late final UpdateProduct _updateProduct;
  late final RecalculateProductFinancials _recalculateFinancials;
  late final GetCatalogCategories _getCategories;
  late final GetCatalogSubcategories _getSubcategories;
  late final GetUnitsOfMeasure _getUnits;
  late final CountProductsForCatalogCategory _countProductsForCategory;
  late final ProductSkuGenerator _skuGenerator;

  List<CatalogCategory> _categories = const [];
  List<CatalogSubcategory> _subcategories = const [];
  List<UnitOfMeasure> _units = const [];
  CatalogCategory? _selectedCategory;
  CatalogSubcategory? _selectedSubcategory;
  UnitOfMeasure? _selectedUnit;

  bool _loading = true;
  bool _saving = false;
  bool _hydrating = false;
  bool _isActive = true;
  bool _allowDecimalQuantity = false;
  String? _productId;
  DateTime? _createdAt;

  @override
  void initState() {
    super.initState();
    final productRepository = ProductRepositoryImpl();
    final catalogRepository = CatalogRepositoryImpl();
    _getProductById = GetProductById(productRepository);
    _createProduct = CreateProduct(productRepository);
    _updateProduct = UpdateProduct(productRepository);
    _recalculateFinancials = const RecalculateProductFinancials();
    _getCategories = GetCatalogCategories(catalogRepository);
    _getSubcategories = GetCatalogSubcategories(catalogRepository);
    _getUnits = GetUnitsOfMeasure(catalogRepository);
    _countProductsForCategory = CountProductsForCatalogCategory(
      catalogRepository,
    );
    _skuGenerator = const ProductSkuGenerator();
    _productId = widget.args?.productId;

    for (final controller in [
      _skuController,
      _nameController,
      _brandController,
      _barcodeController,
      _costController,
      _saleController,
      _stockController,
      _minStockController,
    ]) {
      controller.addListener(_onFieldsChanged);
    }

    _load();
  }

  @override
  void dispose() {
    for (final controller in [
      _skuController,
      _nameController,
      _brandController,
      _barcodeController,
      _costController,
      _saleController,
      _stockController,
      _minStockController,
    ]) {
      controller.removeListener(_onFieldsChanged);
    }
    _skuController.dispose();
    _nameController.dispose();
    _brandController.dispose();
    _barcodeController.dispose();
    _costController.dispose();
    _costWithoutVatController.dispose();
    _saleController.dispose();
    _stockController.dispose();
    _minStockController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final product = _productId == null
        ? null
        : await _getProductById(_productId!);
    final categories = await _getCategories(includeInactive: true);
    final subcategories = await _getSubcategories(includeInactive: true);
    final units = await _getUnits(includeInactive: true);

    if (!mounted) return;
    _categories = categories;
    _subcategories = subcategories;
    _units = units;
    _hydrating = true;
    if (product != null) {
      _loadProduct(product);
    } else {
      _selectedCategory = _firstActiveCategory(categories);
      _selectedSubcategory = _firstSubcategoryFor(_selectedCategory);
      _selectedUnit = _firstActiveUnit(units);
    }
    _hydrating = false;
    _syncCostWithoutVat();
    setState(() => _loading = false);
    final initialCategory = _selectedCategory;
    if (product == null && initialCategory != null) {
      await _selectCategory(initialCategory);
    }
  }

  void _loadProduct(Product product) {
    _createdAt = product.createdAt;
    _skuController.text = product.sku;
    _nameController.text = product.name;
    _brandController.text = product.brand ?? '';
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
    _selectedCategory = _categories.cast<CatalogCategory?>().firstWhere(
      (category) => category?.normalizedName == product.category,
      orElse: () => null,
    );
    _selectedSubcategory = _subcategories
        .cast<CatalogSubcategory?>()
        .firstWhere(
          (subcategory) =>
              subcategory?.categoryId == _selectedCategory?.id &&
              subcategory?.normalizedName == product.subcategory,
          orElse: () => null,
        );
    _selectedUnit = _units.cast<UnitOfMeasure?>().firstWhere(
      (unit) => unit?.normalizedName == product.unitOfMeasure,
      orElse: () => null,
    );
  }

  void _onFieldsChanged() {
    if (_hydrating) return;
    _syncCostWithoutVat();
    setState(() {});
  }

  void _syncCostWithoutVat() {
    final value = _financials.costPriceWithoutVat.toStringAsFixed(2);
    if (_costWithoutVatController.text != value) {
      _costWithoutVatController.text = value;
    }
  }

  double? _parseMoney(String raw) {
    final normalized = raw.trim().replaceAll(',', '.');
    if (normalized.isEmpty) return null;
    return double.tryParse(normalized);
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

  List<CatalogCategory> get _selectableCategories => _categories
      .where((item) => item.isActive || item.id == _selectedCategory?.id)
      .toList();

  List<CatalogSubcategory> get _selectableSubcategories => _subcategories
      .where(
        (item) =>
            item.categoryId == _selectedCategory?.id &&
            (item.isActive || item.id == _selectedSubcategory?.id),
      )
      .toList();

  List<UnitOfMeasure> get _selectableUnits => _units
      .where((item) => item.isActive || item.id == _selectedUnit?.id)
      .toList();

  CatalogCategory? _firstActiveCategory(List<CatalogCategory> categories) {
    for (final category in categories) {
      if (category.isActive) return category;
    }
    return categories.isEmpty ? null : categories.first;
  }

  CatalogSubcategory? _firstSubcategoryFor(CatalogCategory? category) {
    if (category == null) return null;
    final items = _subcategories
        .where((item) => item.categoryId == category.id && item.isActive)
        .toList();
    final general = items.cast<CatalogSubcategory?>().firstWhere(
      (item) => item?.normalizedName == 'general',
      orElse: () => null,
    );
    return general ?? (items.isEmpty ? null : items.first);
  }

  UnitOfMeasure? _firstActiveUnit(List<UnitOfMeasure> units) {
    for (final unit in units) {
      if (unit.isActive && unit.normalizedName == 'unidad') return unit;
    }
    for (final unit in units) {
      if (unit.isActive) return unit;
    }
    return units.isEmpty ? null : units.first;
  }

  Future<void> _selectCategory(CatalogCategory category) async {
    setState(() {
      _selectedCategory = category;
      _selectedSubcategory = _firstSubcategoryFor(category);
    });
    if (_skuController.text.trim().isEmpty) {
      final count = await _countProductsForCategory(category.normalizedName);
      if (!mounted || _skuController.text.trim().isNotEmpty) return;
      _skuController.text = _skuGenerator(
        categoryNormalizedName: category.normalizedName,
        sequence: count + 1,
      );
    }
  }

  void _selectUnit(UnitOfMeasure unit) {
    setState(() {
      _selectedUnit = unit;
      if (unit.allowsDecimal) {
        _allowDecimalQuantity = true;
      }
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectedCategory == null) {
      _showError('Selecciona una categoria.');
      return;
    }
    if (_selectedUnit == null) {
      _showError('Selecciona una unidad de medida.');
      return;
    }

    final cost = _costValue!;
    final sale = _saleValue!;
    if (sale < cost) {
      final confirmed = await _confirmLoss();
      if (confirmed != true) return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final name = _nameController.text.trim();
      final financials = _financials;
      final product = Product(
        id: _productId ?? now.microsecondsSinceEpoch.toString(),
        sku: _skuController.text.trim(),
        name: name,
        normalizedName: ProductTextNormalizer.normalizeName(name),
        brand: _blankToNull(_brandController.text),
        category: _selectedCategory!.normalizedName,
        subcategory: _selectedSubcategory?.normalizedName ?? 'general',
        unitOfMeasure: _selectedUnit!.normalizedName,
        barcode: _blankToNull(_barcodeController.text),
        costPrice: cost,
        costPriceWithoutVat: financials.costPriceWithoutVat,
        salePrice: sale,
        marginAmount: financials.marginAmount,
        marginPercent: financials.marginPercent,
        currency: 'NIO',
        taxType: 'iva_incluido',
        vatRateApplied: 0.15,
        vatAmountOnCost: financials.vatAmountOnCost,
        stock: _stockValue ?? 0,
        minStock: _minStockValue ?? 0,
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
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      _showError('No se pudo guardar el producto. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool?> _confirmLoss() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Margen negativo'),
        content: const Text(
          'El precio de venta es menor que el costo. Puedes guardarlo, pero revisa si es correcto.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Revisar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  String? _requiredText(String? value) {
    return (value?.trim().isEmpty ?? true) ? 'Campo requerido' : null;
  }

  String? _validNonNegativeNumber(String? value) {
    final parsed = _parseMoney(value ?? '');
    if (parsed == null) return 'Ingresa un numero';
    if (parsed < 0) return 'No puede ser negativo';
    return null;
  }

  void _showPendingScanner() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Escaner de codigo de barras pendiente')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = _productId != null;
    final canSave = !_loading && !_saving;

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
                    ProductProfitSummaryCard(
                      profit: _financials.marginAmount,
                      marginPercent: _financials.marginPercent,
                      isLoss: _isLoss,
                    ),
                    const SizedBox(height: 12),
                    ProductFormSectionCard(
                      title: 'Informacion basica',
                      children: [
                        ProductFormField(
                          controller: _nameController,
                          label: 'Nombre',
                          icon: Icons.inventory_2_outlined,
                          autofocus: !isEdit,
                          textInputAction: TextInputAction.next,
                          validator: _requiredText,
                        ),
                        const SizedBox(height: 12),
                        ProductFormField(
                          controller: _skuController,
                          label: 'SKU',
                          icon: Icons.qr_code_2_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                        const SizedBox(height: 12),
                        ProductFormField(
                          controller: _barcodeController,
                          label: 'Codigo de barras',
                          icon: Icons.qr_code_outlined,
                          textInputAction: TextInputAction.next,
                          suffixIcon: IconButton(
                            onPressed: _showPendingScanner,
                            icon: const Icon(Icons.qr_code_scanner_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        ProductFormField(
                          controller: _brandController,
                          label: 'Marca',
                          icon: Icons.branding_watermark_outlined,
                          textInputAction: TextInputAction.next,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProductFormSectionCard(
                      title: 'Clasificacion',
                      children: [
                        ProductSelectorField<CatalogCategory>(
                          label: 'Categoria',
                          icon: Icons.category_outlined,
                          valueLabel: _selectedCategory?.name,
                          options: _selectableCategories,
                          optionTitle: (item) => item.name,
                          optionSearchText: (item) => item.normalizedName,
                          onSelected: _selectCategory,
                        ),
                        const SizedBox(height: 12),
                        ProductSelectorField<CatalogSubcategory>(
                          label: 'Subcategoria',
                          icon: Icons.layers_outlined,
                          valueLabel: _selectedSubcategory?.name,
                          options: _selectableSubcategories,
                          optionTitle: (item) => item.name,
                          optionSearchText: (item) => item.normalizedName,
                          enabled: _selectedCategory != null,
                          emptyText: 'No hay subcategorias para esta categoria',
                          onSelected: (item) =>
                              setState(() => _selectedSubcategory = item),
                        ),
                        const SizedBox(height: 12),
                        ProductSelectorField<UnitOfMeasure>(
                          label: 'Unidad de medida',
                          icon: Icons.straighten_outlined,
                          valueLabel: _selectedUnit?.name,
                          options: _selectableUnits,
                          optionTitle: (item) => item.name,
                          optionSubtitle: (item) => item.allowsDecimal
                              ? 'Permite cantidad decimal'
                              : null,
                          optionSearchText: (item) => item.normalizedName,
                          onSelected: _selectUnit,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProductFormSectionCard(
                      title: 'Precios',
                      children: [
                        ProductFormField(
                          controller: _costController,
                          label: 'Costo con IVA',
                          icon: Icons.payments_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validNonNegativeNumber,
                        ),
                        const SizedBox(height: 12),
                        ProductFormField(
                          controller: _costWithoutVatController,
                          label: 'Costo sin IVA',
                          icon: Icons.receipt_long_outlined,
                          readOnly: true,
                        ),
                        const SizedBox(height: 12),
                        ProductFormField(
                          controller: _saleController,
                          label: 'Precio de venta',
                          icon: Icons.sell_outlined,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          textInputAction: TextInputAction.next,
                          validator: _validNonNegativeNumber,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProductFormSectionCard(
                      title: 'Inventario',
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: ProductFormField(
                                controller: _stockController,
                                label: 'Stock actual',
                                icon: Icons.inventory_2_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validNonNegativeNumber,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ProductFormField(
                                controller: _minStockController,
                                label: 'Stock minimo',
                                icon: Icons.warning_amber_outlined,
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                validator: _validNonNegativeNumber,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ProductStatusSwitchTile(
                          value: _allowDecimalQuantity,
                          onChanged: _saving
                              ? null
                              : (value) => setState(
                                  () => _allowDecimalQuantity = value,
                                ),
                          title: 'Permitir cantidad decimal',
                          subtitle:
                              'Util para productos vendidos por metro, libra, litro o fraccion.',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ProductFormSectionCard(
                      title: 'Estado',
                      children: [
                        ProductStatusSwitchTile(
                          value: _isActive,
                          onChanged: _saving
                              ? null
                              : (value) => setState(() => _isActive = value),
                          title: 'Producto activo',
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: canSave ? _save : null,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'Actualizar producto' : 'Guardar producto'),
          ),
        ),
      ),
    );
  }
}
