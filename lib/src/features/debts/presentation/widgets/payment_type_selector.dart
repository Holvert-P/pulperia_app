import 'package:flutter/material.dart';

class PaymentTypeSelector extends StatelessWidget {
  const PaymentTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<String>(
      segments: const [
        ButtonSegment(
          value: 'auto',
          label: Text('Auto'),
          icon: Icon(Icons.auto_awesome_outlined),
        ),
        ButtonSegment(
          value: 'mixed_manual',
          label: Text('Mixto'),
          icon: Icon(Icons.tune_outlined),
        ),
        ButtonSegment(
          value: 'principal_only',
          label: Text('Capital'),
          icon: Icon(Icons.savings_outlined),
        ),
        ButtonSegment(
          value: 'interest_only',
          label: Text('Interés'),
          icon: Icon(Icons.percent_outlined),
        ),
      ],
      selected: {value},
      onSelectionChanged: (v) => onChanged(v.first),
    );
  }
}
