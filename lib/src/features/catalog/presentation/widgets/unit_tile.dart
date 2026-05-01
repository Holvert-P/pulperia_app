import 'package:app/src/features/catalog/domain/entities/unit_of_measure.dart';
import 'package:flutter/material.dart';

class UnitTile extends StatelessWidget {
  const UnitTile({
    super.key,
    required this.unit,
    required this.onTap,
    required this.onToggle,
  });

  final UnitOfMeasure unit;
  final VoidCallback onTap;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: unit.isActive
              ? scheme.tertiaryContainer
              : scheme.surfaceContainerHighest,
          foregroundColor: unit.isActive
              ? scheme.onTertiaryContainer
              : scheme.onSurfaceVariant,
          child: const Icon(Icons.straighten_outlined),
        ),
        title: Text(
          unit.name,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(
          '${unit.normalizedName}${unit.allowsDecimal ? ' · decimal' : ''} · ${unit.productCount} productos',
        ),
        trailing: Switch(value: unit.isActive, onChanged: (_) => onToggle()),
      ),
    );
  }
}
