import 'package:flutter/material.dart';

class ProductBottomNavigation extends StatelessWidget {
  const ProductBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.inventory_2_outlined),
          selectedIcon: Icon(Icons.inventory_2),
          label: 'Productos',
        ),
        NavigationDestination(
          icon: Icon(Icons.credit_score_outlined),
          selectedIcon: Icon(Icons.credit_score),
          label: 'Deudas',
        ),
        NavigationDestination(
          icon: Icon(Icons.receipt_long_outlined),
          selectedIcon: Icon(Icons.receipt_long),
          label: 'Proformas',
        ),
      ],
    );
  }
}
