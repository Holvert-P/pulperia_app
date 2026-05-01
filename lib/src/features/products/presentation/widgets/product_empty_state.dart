import 'package:flutter/material.dart';

class ProductEmptyState extends StatelessWidget {
  const ProductEmptyState({
    super.key,
    required this.onAdd,
    required this.isSearching,
  });

  final VoidCallback onAdd;
  final bool isSearching;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 360),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSearching
                    ? Icons.search_off_outlined
                    : Icons.inventory_2_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                isSearching
                    ? 'No se encontraron productos'
                    : 'Aún no hay productos',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                isSearching
                    ? 'Prueba con otro nombre, SKU, marca o código de barras.'
                    : 'Agrega tus productos para empezar a controlar precios, stock y ganancias.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              if (!isSearching) ...[
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar producto'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
