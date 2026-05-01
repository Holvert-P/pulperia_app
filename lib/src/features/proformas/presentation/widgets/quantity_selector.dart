import 'package:flutter/material.dart';

class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    required this.onChanged,
  });

  final int quantity;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
          fontWeight: FontWeight.w800,
        );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: colorScheme.surfaceContainerHighest,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () => onChanged(quantity - 1),
            icon: const Icon(Icons.remove),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Text('$quantity', style: textStyle),
          ),
          IconButton(
            onPressed: () => onChanged(quantity + 1),
            icon: const Icon(Icons.add),
            iconSize: 18,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 30, height: 30),
          ),
        ],
      ),
    );
  }
}
