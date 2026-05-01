import 'package:app/src/features/catalog/presentation/controllers/category_manager_controller.dart';
import 'package:app/src/features/catalog/presentation/pages/category_form_page.dart';
import 'package:app/src/features/catalog/presentation/widgets/category_tile.dart';
import 'package:flutter/material.dart';

class CategoryManagerPage extends StatefulWidget {
  const CategoryManagerPage({super.key});

  static const routeName = '/categories';

  @override
  State<CategoryManagerPage> createState() => _CategoryManagerPageState();
}

class _CategoryManagerPageState extends State<CategoryManagerPage> {
  late final CategoryManagerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CategoryManagerController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([CategoryFormArgs? args]) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(CategoryFormPage.routeName, arguments: args);
    if (changed == true) {
      await _controller.load();
    }
  }

  Future<void> _toggle(int index) async {
    final category = _controller.items[index];
    if (category.productCount > 0 && category.isActive) {
      final confirmed = await _confirmDisable(
        'Desactivar categoria',
        'Tiene ${category.productCount} productos vinculados. No se borraran, solo se ocultara como opcion activa.',
      );
      if (confirmed != true) return;
    }
    await _controller.toggle(category);
  }

  Future<bool?> _confirmDisable(String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
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
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Categorias')),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: const Text('Nueva'),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  onChanged: _controller.search,
                  decoration: const InputDecoration(
                    hintText: 'Buscar categorias',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: _controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.items.isEmpty
                    ? const Center(child: Text('No hay categorias'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: _controller.items.length,
                        itemBuilder: (context, index) {
                          final category = _controller.items[index];
                          return CategoryTile(
                            category: category,
                            onTap: () =>
                                _openForm(CategoryFormArgs(category: category)),
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
