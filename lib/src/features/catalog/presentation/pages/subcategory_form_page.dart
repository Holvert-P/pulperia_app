import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:app/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/material.dart';

class SubcategoryFormArgs {
  const SubcategoryFormArgs({this.subcategory, this.categories = const []});

  final CatalogSubcategory? subcategory;
  final List<CatalogCategory> categories;
}

class SubcategoryFormPage extends StatefulWidget {
  const SubcategoryFormPage({super.key, this.args});

  static const routeName = '/subcategories/form';

  final SubcategoryFormArgs? args;

  @override
  State<SubcategoryFormPage> createState() => _SubcategoryFormPageState();
}

class _SubcategoryFormPageState extends State<SubcategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  late final SaveCatalogSubcategory _saveSubcategory;
  late final GetCatalogCategories _getCategories;
  List<CatalogCategory> _categories = const [];
  String? _categoryId;
  bool _isActive = true;
  bool _saving = false;
  bool _loading = true;

  CatalogSubcategory? get _subcategory => widget.args?.subcategory;

  @override
  void initState() {
    super.initState();
    final repository = CatalogRepositoryImpl();
    _saveSubcategory = SaveCatalogSubcategory(repository);
    _getCategories = GetCatalogCategories(repository);
    _load();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final subcategory = _subcategory;
    final categories = widget.args?.categories.isNotEmpty == true
        ? widget.args!.categories
        : await _getCategories(includeInactive: true);
    if (!mounted) return;
    setState(() {
      _categories = categories;
      _categoryId =
          subcategory?.categoryId ??
          (categories.isEmpty ? null : categories.first.id);
      if (subcategory != null) {
        _nameController.text = subcategory.name;
        _descriptionController.text = subcategory.description ?? '';
        _orderController.text = subcategory.sortOrder.toString();
        _isActive = subcategory.isActive;
      }
      _loading = false;
    });
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categoryId = _categoryId;
    if (categoryId == null || categoryId.isEmpty) {
      _showError('Selecciona una categoria.');
      return;
    }
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = _subcategory;
      await _saveSubcategory(
        CatalogSubcategory(
          id: existing?.id ?? '',
          categoryId: categoryId,
          name: _nameController.text.trim(),
          normalizedName: existing?.normalizedName ?? '',
          description: _blankToNull(_descriptionController.text),
          sortOrder: int.tryParse(_orderController.text.trim()) ?? 0,
          isActive: _isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          categoryName: existing?.categoryName,
          categoryNormalizedName: existing?.categoryNormalizedName,
          productCount: existing?.productCount ?? 0,
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CatalogValidationException catch (error) {
      if (!mounted) return;
      _showError(error.message);
    } catch (error) {
      if (!mounted) return;
      _showError('No se pudo guardar la subcategoria. $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _blankToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
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
    final isEdit = _subcategory != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar subcategoria' : 'Nueva subcategoria'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      items: [
                        for (final category in _categories)
                          DropdownMenuItem(
                            value: category.id,
                            child: Text(category.name),
                          ),
                      ],
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _categoryId = value),
                      decoration: const InputDecoration(
                        labelText: 'Categoria padre',
                        prefixIcon: Icon(Icons.category_outlined),
                      ),
                      validator: (value) =>
                          value == null ? 'Categoria requerida' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      autofocus: !isEdit,
                      decoration: const InputDecoration(
                        labelText: 'Nombre',
                        prefixIcon: Icon(Icons.layers_outlined),
                      ),
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Nombre requerido'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripcion opcional',
                        prefixIcon: Icon(Icons.notes_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _orderController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Orden',
                        prefixIcon: Icon(Icons.sort_outlined),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: _isActive,
                      onChanged: _saving
                          ? null
                          : (value) => setState(() => _isActive = value),
                      title: const Text('Activo'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: FilledButton.icon(
            onPressed: _saving || _loading ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'Guardar cambios' : 'Crear subcategoria'),
          ),
        ),
      ),
    );
  }
}
