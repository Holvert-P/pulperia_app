import 'package:app/src/features/catalog/domain/entities/subcategory.dart';
import 'package:flutter/material.dart';

class SubcategoryTile extends StatelessWidget {
  const SubcategoryTile({
    super.key,
    required this.subcategory,
    required this.onTap,
    required this.onToggle,
  });

  final CatalogSubcategory subcategory;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: subcategory.isActive
              ? scheme.secondaryContainer
              : scheme.surfaceContainerHighest,
          foregroundColor: subcategory.isActive
              ? scheme.onSecondaryContainer
              : scheme.onSurfaceVariant,
          child: const Icon(Icons.layers_outlined),
        ),
        title: Text(
          subcategory.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${subcategory.categoryName ?? 'Categoria'} · ${subcategory.normalizedName} · ${subcategory.productCount} productos',
        ),
        trailing: Switch(
          value: subcategory.isActive,
          onChanged: (_) => onToggle(),
        ),
      ),
    );
  }
}
