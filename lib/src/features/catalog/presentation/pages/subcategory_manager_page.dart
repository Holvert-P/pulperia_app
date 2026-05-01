import 'package:app/src/features/catalog/presentation/controllers/subcategory_manager_controller.dart';
import 'package:app/src/features/catalog/presentation/pages/subcategory_form_page.dart';
import 'package:app/src/features/catalog/presentation/widgets/subcategory_tile.dart';
import 'package:flutter/material.dart';

class SubcategoryManagerPage extends StatefulWidget {
  const SubcategoryManagerPage({super.key});

  static const routeName = '/subcategories';

  @override
  State<SubcategoryManagerPage> createState() => _SubcategoryManagerPageState();
}

class _SubcategoryManagerPageState extends State<SubcategoryManagerPage> {
  late final SubcategoryManagerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = SubcategoryManagerController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([SubcategoryFormArgs? args]) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(SubcategoryFormPage.routeName, arguments: args);
    if (changed == true) {
      await _controller.load();
    }
  }

  Future<void> _toggle(int index) async {
    final subcategory = _controller.items[index];
    if (subcategory.productCount > 0 && subcategory.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desactivar subcategoria'),
          content: Text(
            'Tiene ${subcategory.productCount} productos vinculados. No se borraran, solo se ocultara como opcion activa.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Desactivar'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }
    await _controller.toggle(subcategory);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Subcategorias')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(
              SubcategoryFormArgs(categories: _controller.categories),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: TextField(
                  onChanged: _controller.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar subcategorias',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: DropdownButtonFormField<String?>(
                  initialValue: _controller.categoryId,
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('Todas las categorias'),
                    ),
                    for (final category in _controller.categories)
                      DropdownMenuItem<String?>(
                        value: category.id,
                        child: Text(category.name),
                      ),
                  ],
                  onChanged: _controller.filterByCategory,
                  decoration: const InputDecoration(
                    labelText: 'Filtrar por categoria',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                ),
              ),
              Expanded(
                child: _controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.items.isEmpty
                    ? const Center(child: Text('No hay subcategorias'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: _controller.items.length,
                        itemBuilder: (context, index) {
                          final subcategory = _controller.items[index];
                          return SubcategoryTile(
                            subcategory: subcategory,
                            onTap: () => _openForm(
                              SubcategoryFormArgs(
                                subcategory: subcategory,
                                categories: _controller.categories,
                              ),
                            ),
                            onToggle: () => _toggle(index),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
