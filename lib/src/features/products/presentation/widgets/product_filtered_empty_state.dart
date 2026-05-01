import 'package:flutter/material.dart';

class ProductFilteredEmptyState extends StatelessWidget {
  const ProductFilteredEmptyState({super.key, required this.onClear});

  final VoidCallback onClear;

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
                Icons.filter_alt_off_outlined,
                size: 56,
                color: colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                'No hay productos en este filtro',
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Cambia el filtro para ver otros productos del catálogo.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onClear,
                icon: const Icon(Icons.clear_all_outlined),
                label: const Text('Ver todos'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
