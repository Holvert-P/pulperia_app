import 'package:flutter/material.dart';

class CustomSearchBar extends StatelessWidget {
  const CustomSearchBar({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Buscar',
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SearchBar(
      controller: controller,
      hintText: hintText,
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(
        colorScheme.surfaceContainerHighest,
      ),
      padding: const WidgetStatePropertyAll(
        EdgeInsets.symmetric(horizontal: 16),
      ),
      shape: WidgetStatePropertyAll(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      leading: const Icon(Icons.search),
      trailing: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, child) {
            if (value.text.trim().isEmpty) return const SizedBox.shrink();
            return IconButton(
              tooltip: 'Limpiar',
              icon: const Icon(Icons.close),
              onPressed: () {
                controller.clear();
                onChanged('');
                FocusScope.of(context).unfocus();
              },
            );
          },
        ),
      ],
      onChanged: onChanged,
    );
  }
}
