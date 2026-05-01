import 'package:app/src/features/catalog/domain/entities/category.dart';
import 'package:flutter/material.dart';

class CategoryTile extends StatelessWidget {
  const CategoryTile({
    super.key,
    required this.category,
    required this.onTap,
    required this.onToggle,
  });

  final CatalogCategory category;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: category.isActive
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest,
          foregroundColor: category.isActive
              ? scheme.onPrimaryContainer
              : scheme.onSurfaceVariant,
          child: const Icon(Icons.category_outlined),
        ),
        title: Text(
          category.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${category.normalizedName} · ${category.subcategoryCount} subcategorias · ${category.productCount} productos',
        ),
        trailing: Switch(
          value: category.isActive,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
