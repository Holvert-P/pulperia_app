import 'package:app/src/features/debts/presentation/pages/accounts_receivable_page.dart';
import 'package:flutter/material.dart';

class DebtListPage extends StatelessWidget {
  const DebtListPage({super.key, this.showBottomNavigation = true});

  static const routeName = '/debts';
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    return const AccountsReceivablePage();
  }
}
