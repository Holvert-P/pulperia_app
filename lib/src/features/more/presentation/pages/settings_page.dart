import 'package:flutter/material.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Configuración')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SettingsSectionTitle('Negocio'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Datos del negocio'),
                  subtitle: const Text(
                    'Nombre, subtítulo, logo y datos generales',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPending(context, 'Datos del negocio');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.request_quote_outlined),
                  title: const Text('Impuestos'),
                  subtitle: const Text('IVA, moneda y preferencias fiscales'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPending(context, 'Impuestos');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _SettingsSectionTitle('Catálogo'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('Importar catálogo'),
                  subtitle: const Text('Cargar productos desde JSON'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPending(context, 'Importar catálogo');
                  },
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.restart_alt_outlined),
                  title: const Text('Reinicializar catálogo'),
                  subtitle: const Text(
                    'Borrar productos actuales y cargar JSON maestro',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    _showPending(context, 'Reinicializar catálogo');
                  },
                ),
              ],
            ),
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

class _SettingsSectionTitle extends StatelessWidget {
  const _SettingsSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w900,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
