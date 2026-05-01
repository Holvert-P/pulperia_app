import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:app/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/material.dart';

class CategoryFormArgs {
  const CategoryFormArgs({this.category});

  final CatalogCategory? category;
}

class CategoryFormPage extends StatefulWidget {
  const CategoryFormPage({super.key, this.args});

  static const routeName = '/categories/form';

  final CategoryFormArgs? args;

  @override
  State<CategoryFormPage> createState() => _CategoryFormPageState();
}

class _CategoryFormPageState extends State<CategoryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  late final SaveCatalogCategory _saveCategory;
  bool _isActive = true;
  bool _saving = false;

  CatalogCategory? get _category => widget.args?.category;

  @override
  void initState() {
    super.initState();
    _saveCategory = SaveCatalogCategory(CatalogRepositoryImpl());
    final category = _category;
    if (category != null) {
      _nameController.text = category.name;
      _descriptionController.text = category.description ?? '';
      _orderController.text = category.sortOrder.toString();
      _isActive = category.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = _category;
      await _saveCategory(
        CatalogCategory(
          id: existing?.id ?? '',
          name: _nameController.text.trim(),
          normalizedName: existing?.normalizedName ?? '',
          description: _blankToNull(_descriptionController.text),
          iconName: existing?.iconName,
          colorHex: existing?.colorHex,
          sortOrder: int.tryParse(_orderController.text.trim()) ?? 0,
          isActive: _isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
          subcategoryCount: existing?.subcategoryCount ?? 0,
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
      _showError('No se pudo guardar la categoria. $error');
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
    final isEdit = _category != null;
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Editar categoria' : 'Nueva categoria'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: !isEdit,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.category_outlined),
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
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
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(isEdit ? 'Guardar cambios' : 'Crear categoria'),
          ),
        ),
      ),
    );
  }
}
