import 'package:flutter/material.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({super.key});

  static const routeName = '/backup';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Respaldo')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.backup_outlined,
                    size: 42,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Protege la información de tu negocio',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crea respaldos de productos, deudas, pagos, proformas y configuraciones.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () {
              _showPending(context, 'Crear respaldo');
            },
            icon: const Icon(Icons.file_upload_outlined),
            label: const Text('Crear respaldo'),
          ),
          const SizedBox(height: 8),
          FilledButton.tonalIcon(
            onPressed: () {
              _showPending(context, 'Restaurar respaldo');
            },
            icon: const Icon(Icons.restore_outlined),
            label: const Text('Restaurar respaldo'),
          ),
        ],
      ),
    );
  }

  static void _showPending(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponible pronto')),
    );
  }
}
