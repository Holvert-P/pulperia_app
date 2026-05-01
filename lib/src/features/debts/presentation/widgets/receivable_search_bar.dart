import 'package:app/src/shared/widgets/custom_search_bar.dart';
import 'package:flutter/material.dart';

class ReceivableSearchBar extends StatelessWidget {
  const ReceivableSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return CustomSearchBar(
      controller: controller,
      onChanged: onChanged,
      hintText: 'Buscar cliente, referencia…',
    );
  }
}
