import 'package:app/src/features/catalog/data/repositories/catalog_repository_impl.dart';
import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:app/src/features/catalog/domain/repositories/catalog_repository.dart';
import 'package:app/src/features/catalog/domain/usecases/catalog_usecases.dart';
import 'package:flutter/material.dart';

class UnitFormArgs {
  const UnitFormArgs({this.unit});

  final UnitOfMeasure? unit;
}

class UnitFormPage extends StatefulWidget {
  const UnitFormPage({super.key, this.args});

  static const routeName = '/units/form';

  final UnitFormArgs? args;

  @override
  State<UnitFormPage> createState() => _UnitFormPageState();
}

class _UnitFormPageState extends State<UnitFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _symbolController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _orderController = TextEditingController(text: '0');
  late final SaveUnitOfMeasure _saveUnit;
  bool _allowsDecimal = false;
  bool _isActive = true;
  bool _saving = false;

  UnitOfMeasure? get _unit => widget.args?.unit;

  @override
  void initState() {
    super.initState();
    _saveUnit = SaveUnitOfMeasure(CatalogRepositoryImpl());
    final unit = _unit;
    if (unit != null) {
      _nameController.text = unit.name;
      _symbolController.text = unit.symbol ?? '';
      _descriptionController.text = unit.description ?? '';
      _orderController.text = unit.sortOrder.toString();
      _allowsDecimal = unit.allowsDecimal;
      _isActive = unit.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _symbolController.dispose();
    _descriptionController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final existing = _unit;
      await _saveUnit(
        UnitOfMeasure(
          id: existing?.id ?? '',
          name: _nameController.text.trim(),
          normalizedName: existing?.normalizedName ?? '',
          symbol: _blankToNull(_symbolController.text),
          allowsDecimal: _allowsDecimal,
          description: _blankToNull(_descriptionController.text),
          sortOrder: int.tryParse(_orderController.text.trim()) ?? 0,
          isActive: _isActive,
          createdAt: existing?.createdAt ?? now,
          updatedAt: now,
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
      _showError('No se pudo guardar la unidad. $error');
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
    final isEdit = _unit != null;
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Editar unidad' : 'Nueva unidad')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: !isEdit,
                decoration: const InputDecoration(
                  labelText: 'Nombre',
                  prefixIcon: Icon(Icons.straighten_outlined),
                ),
                validator: (value) =>
                    (value?.trim().isEmpty ?? true) ? 'Nombre requerido' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _symbolController,
                decoration: const InputDecoration(
                  labelText: 'Simbolo opcional',
                  prefixIcon: Icon(Icons.short_text_outlined),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descripcion',
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
                value: _allowsDecimal,
                onChanged: _saving
                    ? null
                    : (value) => setState(() => _allowsDecimal = value),
                title: const Text('Permite cantidad decimal'),
                subtitle: const Text(
                  'Util para metro, libra, litro o fraccion.',
                ),
                contentPadding: EdgeInsets.zero,
              ),
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
            label: Text(isEdit ? 'Guardar cambios' : 'Crear unidad'),
          ),
        ),
      ),
    );
  }
}
