import 'package:app/src/features/proformas/data/repositories/proforma_repository_impl.dart';
import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/features/proformas/domain/usecases/proforma_usecases.dart';
import 'package:app/src/features/proformas/presentation/controllers/proforma_detail_controller.dart';
import 'package:app/src/features/proformas/presentation/pages/proforma_form_page.dart';
import 'package:app/src/features/proformas/services/pdf_service.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

class ProformaDetailArgs {
  const ProformaDetailArgs({required this.proformaId});

  final String proformaId;
}

class ProformaDetailPage extends StatelessWidget {
  const ProformaDetailPage({super.key, required this.args});

  static const routeName = '/proformas/detail';

  final ProformaDetailArgs args;

  @override
  Widget build(BuildContext context) {
    final repository = ProformaRepositoryImpl();
    return ChangeNotifierProvider(
      create: (_) => ProformaDetailController(
        getProformaById: GetProformaById(repository),
        proformaId: args.proformaId,
      )..load(),
      child: const _ProformaDetailView(),
    );
  }
}

class _ProformaDetailView extends StatelessWidget {
  const _ProformaDetailView();

  Future<void> _openEdit(BuildContext context, String proformaId) async {
    final updated = await Navigator.of(context).pushNamed<bool>(
      ProformaFormPage.routeName,
      arguments: ProformaFormArgs(proformaId: proformaId),
    );
    if (updated == true && context.mounted) {
      await context.read<ProformaDetailController>().load();
    }
  }

  Future<void> _openPdfPreview(BuildContext context, Proforma proforma) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _ProformaPdfPreviewPage(proforma: proforma),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = context.watch<ProformaDetailController>();
    final proforma = c.proforma;

    return PopScope<bool>(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(true);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Detalle proforma'),
          actions: [
            if (proforma != null)
              IconButton(
                onPressed: () => _openPdfPreview(context, proforma),
                icon: const Icon(Icons.picture_as_pdf_outlined),
                tooltip: 'PDF',
              ),
            if (proforma != null)
              IconButton(
                onPressed: () => _openEdit(context, proforma.id),
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Editar',
              ),
          ],
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
                  return Center(child: Text(c.error!));
                }
                if (proforma == null) {
                  return const Center(child: Text('Proforma no encontrada'));
                }

                final subtotal = proforma.items.fold<double>(
                  0,
                  (sum, i) => sum + i.subtotal,
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              proforma.customerName,
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              formatDateTime(proforma.createdAt),
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 12),
                            if (proforma.discount > 0) ...[
                              Row(
                                children: [
                                  Text(
                                    'Subtotal',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const Spacer(),
                                  Text(
                                    formatMoney(subtotal),
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'Descuento',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                  const Spacer(),
                                  Text(
                                    '- ${formatMoney(proforma.discount)}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w900),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                            ],
                            Row(
                              children: [
                                Text(
                                  'Total',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                                const Spacer(),
                                Text(
                                  formatMoney(proforma.total),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w900),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Productos',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.separated(
                        itemCount: proforma.items.length,
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final item = proforma.items[index];
                          return Card(
                            child: ListTile(
                              title: Text(item.name),
                              subtitle: Text(
                                'Cant: ${item.quantity}  •  Precio: ${formatMoney(item.price)}',
                              ),
                              trailing: Text(
                                formatMoney(item.subtotal),
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w900),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _ProformaPdfPreviewPage extends StatelessWidget {
  const _ProformaPdfPreviewPage({required this.proforma});

  final Proforma proforma;

  Future<T> _runWithLoading<T>(
    BuildContext context,
    Future<T> Function() action,
  ) async {
    showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      builder: (context) {
        return const SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SizedBox(
              height: 72,
              child: Center(child: CircularProgressIndicator()),
            ),
          ),
        );
      },
    );
    try {
      return await action();
    } finally {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    }
  }

  Future<void> _share(BuildContext context, ProformaPdfService service) async {
    await _runWithLoading<void>(context, () async {
      final bytes = await service.generateProformaPdf(proforma);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'proforma_${proforma.id}.pdf',
      );
    });
  }

  Future<void> _print(BuildContext context, ProformaPdfService service) async {
    await Printing.layoutPdf(
      onLayout: (_) => service.generateProformaPdf(proforma),
      name: 'proforma_${proforma.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = ProformaPdfService();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proforma PDF'),
        actions: [
          IconButton(
            onPressed: () => _share(context, service),
            icon: const Icon(Icons.ios_share_outlined),
            tooltip: 'Compartir',
          ),
          IconButton(
            onPressed: () => _print(context, service),
            icon: const Icon(Icons.print_outlined),
            tooltip: 'Imprimir',
          ),
        ],
      ),
      body: PdfPreview(
        build: (_) => service.generateProformaPdf(proforma),
        allowPrinting: true,
        allowSharing: true,
        canChangePageFormat: false,
        canChangeOrientation: false,
        canDebug: false,
        pdfFileName: 'proforma_${proforma.id}.pdf',
      ),
    );
  }
}
