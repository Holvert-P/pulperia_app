import 'package:app/src/features/proformas/data/repositories/proforma_repository_impl.dart';
import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:app/src/features/proformas/presentation/controllers/proforma_list_controller.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_detail_page.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_form_page.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProformaListPage extends StatelessWidget {
  const ProformaListPage({super.key, this.showBottomNavigation = true});

  static const routeName = '/proformas';
  final bool showBottomNavigation;

  @override
  Widget build(BuildContext context) {
    final repository = ProformaRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) =>
          ProformaListController(getProformas: GetProformas(repository))
            ..load(),
      child: const _ProformaListView(),
    );
  }
}

class _ProformaListView extends StatelessWidget {
  const _ProformaListView();

  Future<void> _openCreate(BuildContext context) async {
    final updated = await Navigator.of(context).pushNamed<bool>(
      ProformaFormPage.routeName,
      arguments: const ProformaFormArgs(),
    );
    if (updated == true && context.mounted) {
      await context.read<ProformaListController>().load();
    }
  }

  Future<void> _openDetail(BuildContext context, Proforma proforma) async {
    final updated = await Navigator.of(context).pushNamed<bool>(
      ProformaDetailPage.routeName,
      arguments: ProformaDetailArgs(proformaId: proforma.id),
    );
    if (updated == true && context.mounted) {
      await context.read<ProformaListController>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProformaListController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Proformas')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'proformas_fab',
        onPressed: () => _openCreate(context),
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Builder(
            builder: (context) {
              if (c.loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (c.error != null) {
                return _ErrorState(message: c.error!, onRetry: () => c.load());
              }
              if (c.items.isEmpty) {
                return _EmptyState(onAdd: () => _openCreate(context));
              }

              return ListView.separated(
                itemCount: c.items.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final p = c.items[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        p.customerName,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(
                        formatDateTime(p.createdAt),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: Text(
                        formatMoney(p.total),
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: colorScheme.primary,
                        ),
                      ),
                      onTap: () => _openDetail(context, p),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.receipt_long_outlined,
                  size: 56,
                  color: colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  'Aún no hay proformas',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Crea una cotización con productos y cantidades.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add),
                  label: const Text('Crear proforma'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.error_outline, size: 56, color: colorScheme.error),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
