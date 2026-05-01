import 'package:app/src/features/proformas/domain/entities/proforma.dart';
import 'package:app/src/shared/utils/formatters.dart';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class ProformaPdfService {
  Future<Uint8List> generateProformaPdf(Proforma proforma) async {
    final doc = pw.Document();
    final logo = await _loadLogo();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 44),
        footer: (context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                'Gracias por su preferencia',
                style: pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                'Página ${context.pageNumber} de ${context.pagesCount}',
                style: const pw.TextStyle(
                  color: PdfColors.grey700,
                  fontSize: 10,
                ),
              ),
            ],
          );
        },
        build: (context) {
          return [
            _header(logo: logo, proforma: proforma),
            pw.SizedBox(height: 18),
            _proformaInfo(proforma),
            pw.SizedBox(height: 18),
            _itemsTable(proforma),
            pw.SizedBox(height: 14),
            _totals(proforma),
          ];
        },
      ),
    );

    return doc.save();
  }

  Future<pw.ImageProvider?> _loadLogo() async {
    try {
      final data = await rootBundle.load('assets/images/logo.png');
      return pw.MemoryImage(data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  pw.Widget _header({
    required pw.ImageProvider? logo,
    required Proforma proforma,
  }) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 14),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey300, width: 1),
        ),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.ClipRRect(
              horizontalRadius: 10,
              verticalRadius: 10,
              child: pw.Image(
                logo,
                width: 62,
                height: 62,
                fit: pw.BoxFit.cover,
              ),
            )
          else
            pw.Container(
              width: 62,
              height: 62,
              decoration: pw.BoxDecoration(
                color: PdfColors.grey200,
                borderRadius: pw.BorderRadius.circular(10),
              ),
            ),
          pw.SizedBox(width: 14),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Pulpería y Artículos ferreteros Pérez',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Vivero rosalinda 300 metros al oeste, Estelí-Nicaragua',
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  children: [
                    pw.Text(
                      '5744-7776',
                      style: const pw.TextStyle(
                        fontSize: 10,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          pw.SizedBox(width: 12),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
            decoration: pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.circular(12),
              border: pw.Border.all(color: PdfColors.blue100),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text(
                  'PROFORMA',
                  style: pw.TextStyle(
                    fontSize: 12,
                    letterSpacing: 1,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blue900,
                  ),
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  'No. ${proforma.id}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.blueGrey900,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  formatDate(proforma.createdAt),
                  style: const pw.TextStyle(
                    fontSize: 10,
                    color: PdfColors.grey700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _proformaInfo(Proforma proforma) {
    pw.Widget item({required String label, required String value}) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColors.grey700,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 11,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey900,
            ),
          ),
        ],
      );
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(12),
        border: pw.Border.all(color: PdfColors.grey200),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
            child: item(label: 'Cliente', value: proforma.customerName),
          ),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: item(label: 'Fecha', value: formatDate(proforma.createdAt)),
          ),
        ],
      ),
    );
  }

  pw.Widget _itemsTable(Proforma proforma) {
    final headers = <String>[
      'Producto',
      'Cantidad',
      'Precio unitario',
      'Subtotal',
    ];

    final data = proforma.items
        .map(
          (i) => <String>[
            i.name,
            i.quantity.toString(),
            formatMoney(i.price),
            formatMoney(i.subtotal),
          ],
        )
        .toList();

    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: data,
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.8),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      headerHeight: 28,
      cellHeight: 28,
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      headerStyle: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColors.grey900,
      ),
      cellStyle: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
      rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
      columnWidths: {
        0: const pw.FlexColumnWidth(4),
        1: const pw.FlexColumnWidth(1.2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FlexColumnWidth(2),
      },
      cellAlignments: {
        0: pw.Alignment.centerLeft,
        1: pw.Alignment.center,
        2: pw.Alignment.centerRight,
        3: pw.Alignment.centerRight,
      },
    );
  }

  pw.Widget _totals(Proforma proforma) {
    final subtotal = proforma.items.fold<double>(
      0,
      (sum, i) => sum + i.subtotal,
    );
    final discount = proforma.discount;

    pw.Widget row({
      required String label,
      required String value,
      bool emphasize = false,
    }) {
      final style = emphasize
          ? pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)
          : pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold);

      return pw.Row(
        children: [
          pw.Expanded(
            child: pw.Text(
              label,
              style: style.copyWith(color: PdfColors.grey800),
            ),
          ),
          pw.Text(value, style: style.copyWith(color: PdfColors.grey900)),
        ],
      );
    }

    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 260,
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(
          color: PdfColors.blue50,
          borderRadius: pw.BorderRadius.circular(12),
          border: pw.Border.all(color: PdfColors.blue100),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            row(label: 'Subtotal', value: formatMoney(subtotal)),
            if (discount > 0) ...[
              pw.SizedBox(height: 6),
              row(label: 'Descuento', value: '- ${formatMoney(discount)}'),
            ],
            pw.SizedBox(height: 10),
            pw.Container(height: 1, color: PdfColors.blue100),
            pw.SizedBox(height: 12),
            row(
              label: 'Total',
              value: formatMoney(proforma.total),
              emphasize: true,
            ),
          ],
        ),
      ),
    );
  }
}
