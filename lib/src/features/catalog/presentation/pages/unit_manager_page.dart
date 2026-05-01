import 'package:app/src/features/catalog/presentation/controllers/unit_manager_controller.dart';
import 'package:app/src/features/catalog/presentation/pages/unit_form_page.dart';
import 'package:app/src/features/catalog/presentation/widgets/unit_tile.dart';
import 'package:flutter/material.dart';

class UnitManagerPage extends StatefulWidget {
  const UnitManagerPage({super.key});

  static const routeName = '/units';

  @override
  State<UnitManagerPage> createState() => _UnitManagerPageState();
}

class _UnitManagerPageState extends State<UnitManagerPage> {
  late final UnitManagerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = UnitManagerController()..load();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _openForm([UnitFormArgs? args]) async {
    final changed = await Navigator.of(
      context,
    ).pushNamed(UnitFormPage.routeName, arguments: args);
    if (changed == true) {
      await _controller.load();
    }
  }

  Future<void> _toggle(int index) async {
    final unit = _controller.items[index];
    if (unit.productCount > 0 && unit.isActive) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Desactivar unidad'),
          content: Text(
            'Tiene ${unit.productCount} productos vinculados. No se borraran, solo se ocultara como opcion activa.',
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
    await _controller.toggle(unit);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(title: const Text('Unidades de medida')),
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
                    hintText: 'Buscar unidades',
                    prefixIcon: Icon(Icons.search),
                  ),
                ),
              ),
              Expanded(
                child: _controller.loading
                    ? const Center(child: CircularProgressIndicator())
                    : _controller.items.isEmpty
                    ? const Center(child: Text('No hay unidades'))
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 88),
                        itemCount: _controller.items.length,
                        itemBuilder: (context, index) {
                          final unit = _controller.items[index];
                          return UnitTile(
                            unit: unit,
                            onTap: () => _openForm(UnitFormArgs(unit: unit)),
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
