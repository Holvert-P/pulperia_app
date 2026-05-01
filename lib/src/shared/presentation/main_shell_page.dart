import 'package:app/src/features/debts/presentation/pages/debt_list_page.dart';
import 'package:app/src/features/more/presentation/pages/more_page.dart';
import 'package:app/src/features/products/presentation/pages/product_list_page.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_list_page.dart';
import 'package:app/src/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class MainShellPage extends StatefulWidget {
  const MainShellPage({super.key});

  static const routeName = '/';

  @override
  State<MainShellPage> createState() => _MainShellPageState();
}

class _MainShellPageState extends State<MainShellPage> {
  int _selectedIndex = 0;
  bool _exitSheetOpen = false;

  final _pages = const [
    ProductListPage(showBottomNavigation: false),
    DebtListPage(showBottomNavigation: false),
    ProformaListPage(showBottomNavigation: false),
    MorePage(),
  ];

  void _onDestinationSelected(int index) {
    if (_selectedIndex == index) return;

    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _handleBackPressed() async {
    if (_selectedIndex != 0) {
      setState(() {
        _selectedIndex = 0;
      });
      return;
    }

    if (_exitSheetOpen) return;
    _exitSheetOpen = true;

    try {
      final shouldExit = await showConfirmationBottomSheet(
        context: context,
        icon: Icons.logout_outlined,
        title: 'Salir de la app',
        headline: '¿Deseas cerrar la aplicación?',
        confirmLabel: 'Salir',
        confirmIcon: Icons.logout_outlined,
      );

      if (shouldExit == true) {
        await SystemNavigator.pop();
      }
    } finally {
      _exitSheetOpen = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBackPressed();
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: _pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onDestinationSelected,
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
            NavigationDestination(
              icon: Icon(Icons.more_horiz_outlined),
              selectedIcon: Icon(Icons.more_horiz),
              label: 'Más',
            ),
          ],
        ),
      ),
    );
  }
}
