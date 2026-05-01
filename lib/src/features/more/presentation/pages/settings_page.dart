import 'package:app/src/features/more/presentation/controllers/catalog_settings_controller.dart';
import 'package:app/src/features/more/presentation/widgets/settings_option_tile.dart';
import 'package:app/src/features/more/presentation/widgets/settings_section_title.dart';
import 'package:app/src/features/catalog/presentation/pages/category_manager_page.dart';
import 'package:app/src/features/catalog/presentation/pages/subcategory_manager_page.dart';
import 'package:app/src/features/catalog/presentation/pages/unit_manager_page.dart';
import 'package:app/src/features/products/domain/entities/product_catalog_io_result.dart';
import 'package:app/src/shared/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  static const routeName = '/settings';

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final CatalogSettingsController _catalogController;

  @override
  void initState() {
    super.initState();
    _catalogController = CatalogSettingsController();
  }

  @override
  void dispose() {
    _catalogController.dispose();
    super.dispose();
  }

  Future<void> _exportProducts() async {
    try {
      final result = await _catalogController.exportProducts();
      if (!mounted) return;
      await _showExportResult(result);
    } catch (error) {
      if (!mounted) return;
      debugPrint('Error exportando catálogo: $error');
      _showError(_formatError('No se pudo exportar el catálogo.', error));
    }
  }

  Future<void> _importProducts() async {
    try {
      final result = await _catalogController.importProducts();
      if (!mounted || result == null) return;
      await _showImportResult(result);
    } catch (error) {
      if (!mounted) return;
      _showError(_formatError('No se pudo importar el catálogo.', error));
    }
  }

  Future<void> _resetCatalog() async {
    final confirmed = await showConfirmationBottomSheet(
      context: context,
      icon: Icons.warning_amber_outlined,
      title: 'Reinicializar catálogo desde JSON maestro',
      headline:
          'Se borrarán los productos actuales y se cargará el catálogo maestro.',
      supportingText:
          'No se borrarán deudas, pagos, clientes, proformas ni otros módulos. Se eliminará el historial de precios del catálogo.',
      confirmLabel: 'Reinicializar',
      confirmIcon: Icons.restart_alt_outlined,
    );

    if (confirmed != true) return;

    try {
      final result = await _catalogController.resetCatalog();
      if (!mounted) return;
      await _showImportResult(result);
    } catch (error) {
      if (!mounted) return;
      _showError(_formatError('No se pudo reinicializar el catálogo.', error));
    }
  }

  Future<void> _showExportResult(ProductCatalogExportResult result) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Catálogo exportado correctamente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${result.productsCount} productos exportados.'),
              const SizedBox(height: 8),
              Text(
                result.storageMessage,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              Text(
                'Ruta del archivo',
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              SelectableText(result.filePath),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cerrar'),
            ),
            FilledButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: result.filePath));
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ruta copiada al portapapeles')),
                );
              },
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar ruta'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showImportResult(ProductCatalogImportResult result) {
    final reset = result.resetBeforeImport;
    final title = reset
        ? 'Catálogo reinicializado'
        : result.hasErrors
        ? 'Catálogo importado con advertencias'
        : 'Catálogo importado correctamente';
    final errors = result.errors.take(6).toList();
    final remainingErrors = result.errors.length - errors.length;

    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Productos leídos: ${result.totalRead}'),
                Text('Productos insertados: ${result.created}'),
                Text('Productos actualizados: ${result.updated}'),
                Text('Productos omitidos: ${result.skipped}'),
                Text('Categorias creadas: ${result.categoriesCreated}'),
                Text('Subcategorias creadas: ${result.subcategoriesCreated}'),
                Text('Unidades creadas: ${result.unitsCreated}'),
                Text('Errores encontrados: ${result.errors.length}'),
                if (errors.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    'Detalle',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final error in errors)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text('• $error'),
                    ),
                  if (remainingErrors > 0)
                    Text('Y $remainingErrors errores adicionales.'),
                ],
              ],
            ),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  void _showPending(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature estará disponible pronto')),
    );
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  String _formatError(String prefix, Object error) {
    final message = error.toString().trim();
    if (message.isEmpty) return prefix;
    return '$prefix $message';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _catalogController,
      builder: (context, _) {
        final working = _catalogController.working;

        return Scaffold(
          appBar: AppBar(title: const Text('Configuración')),
          body: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const SettingsSectionTitle('Negocio'),
                  Card(
                    child: Column(
                      children: [
                        SettingsOptionTile(
                          icon: Icons.storefront_outlined,
                          title: 'Datos del negocio',
                          subtitle: 'Nombre, subtítulo, logo y datos generales',
                          onTap: working
                              ? null
                              : () => _showPending('Datos del negocio'),
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.request_quote_outlined,
                          title: 'Impuestos',
                          subtitle: 'IVA, moneda y preferencias fiscales',
                          onTap: working
                              ? null
                              : () => _showPending('Impuestos'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const SettingsSectionTitle('Catálogo'),
                  Card(
                    child: Column(
                      children: [
                        SettingsOptionTile(
                          icon: Icons.category_outlined,
                          title: 'Administrar categorias',
                          subtitle: 'Crear, editar y activar categorias',
                          onTap: working
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushNamed(CategoryManagerPage.routeName),
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.layers_outlined,
                          title: 'Administrar subcategorias',
                          subtitle: 'Vincular subcategorias con categorias',
                          onTap: working
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushNamed(SubcategoryManagerPage.routeName),
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.straighten_outlined,
                          title: 'Administrar unidades de medida',
                          subtitle: 'Unidad, docena, metro, libra y mas',
                          onTap: working
                              ? null
                              : () => Navigator.of(
                                  context,
                                ).pushNamed(UnitManagerPage.routeName),
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.download_outlined,
                          title: 'Exportar productos a JSON',
                          subtitle:
                              'Genera un archivo con el catálogo actual para editarlo con IA',
                          onTap: working ? null : _exportProducts,
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.upload_file_outlined,
                          title: 'Importar productos desde JSON',
                          subtitle:
                              'Actualiza productos existentes y agrega productos nuevos',
                          onTap: working ? null : _importProducts,
                        ),
                        const Divider(height: 1),
                        SettingsOptionTile(
                          icon: Icons.restart_alt_outlined,
                          title: 'Reinicializar catálogo desde JSON maestro',
                          subtitle:
                              'Borra productos actuales y carga el JSON maestro incluido en la app',
                          danger: true,
                          onTap: working ? null : _resetCatalog,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              if (working)
                Container(
                  color: Theme.of(
                    context,
                  ).colorScheme.surface.withValues(alpha: 0.55),
                  child: const Center(child: CircularProgressIndicator()),
                ),
            ],
          ),
        );
      },
    );
  }
}
