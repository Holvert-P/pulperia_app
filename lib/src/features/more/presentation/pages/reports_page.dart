import 'package:flutter/material.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  static const routeName = '/reports';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reportes')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _ReportOption(
            icon: Icons.point_of_sale_outlined,
            title: 'Ventas',
            subtitle: 'Ventas del día, semana y mes',
          ),
          _ReportOption(
            icon: Icons.inventory_2_outlined,
            title: 'Productos',
            subtitle: 'Productos más vendidos, sin stock y stock bajo',
          ),
          _ReportOption(
            icon: Icons.credit_score_outlined,
            title: 'Cuentas por cobrar',
            subtitle: 'Cartera total, vencidas e intereses pendientes',
          ),
          _ReportOption(
            icon: Icons.trending_up_outlined,
            title: 'Ganancias',
            subtitle: 'Utilidad estimada por productos y ventas',
          ),
        ],
      ),
    );
  }
}

class _ReportOption extends StatelessWidget {
  const _ReportOption({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$title estará disponible pronto')),
          );
        },
      ),
    );
  }
}
