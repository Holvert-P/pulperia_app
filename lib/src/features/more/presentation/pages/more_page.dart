import 'package:app/src/features/more/presentation/pages/backup_page.dart';
import 'package:app/src/features/more/presentation/pages/reports_page.dart';
import 'package:app/src/features/more/presentation/pages/settings_page.dart';
import 'package:flutter/material.dart';

class MorePage extends StatelessWidget {
  const MorePage({super.key});

  static const routeName = '/more';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _MoreOptionCard(
            icon: Icons.analytics_outlined,
            title: 'Reportes',
            subtitle: 'Ventas, cartera, productos y ganancias',
            onTap: () {
              Navigator.of(context).pushNamed(ReportsPage.routeName);
            },
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.settings_outlined,
            title: 'Configuración',
            subtitle: 'Catálogo, impuestos, preferencias y datos del negocio',
            onTap: () {
              Navigator.of(context).pushNamed(SettingsPage.routeName);
            },
          ),
          const SizedBox(height: 12),
          _MoreOptionCard(
            icon: Icons.backup_outlined,
            title: 'Respaldo',
            subtitle: 'Crear copia de seguridad y restaurar datos',
            onTap: () {
              Navigator.of(context).pushNamed(BackupPage.routeName);
            },
          ),
        ],
      ),
    );
  }
}

class _MoreOptionCard extends StatelessWidget {
  const _MoreOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          child: Icon(icon),
        ),
        title: Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
