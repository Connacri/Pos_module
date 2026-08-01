import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

class InventoryPdfService {
  InventoryPdfService._();

  static Future<Uint8List> generate({
    required List<Product> products,
    required Map<int, String> categoryNames,
    required String title,
  }) async {
    final doc = pw.Document();
    final now = DateTime.now();

    final totalProducts = products.length;
    final totalUnits = products.fold<double>(0, (s, p) => s + p.stock);
    final stockValue = products.fold<double>(
      0,
      (s, p) => s + p.stock * (p.costPrice > 0 ? p.costPrice : p.price),
    );
    final outOfStock = products.where((p) => p.isOutOfStock).length;
    final lowStock = products
        .where((p) => p.isLowStock && !p.isOutOfStock)
        .length;

    final byCategory = <int?, List<Product>>{};
    for (final product in products) {
      byCategory.putIfAbsent(product.categoryId, () => []).add(product);
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                title,
                style: const pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                '${now.day.toString().padLeft(2, '0')}/'
                '${now.month.toString().padLeft(2, '0')}/${now.year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            'Liste des produits de l\'inventaire',
            style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: [
              'Produits',
              'Unités',
              'Valeur stock',
              'Stock faible',
              'Ruptures',
            ],
            data: [
              [
                '$totalProducts',
                '${totalUnits.round()}',
                CurrencyUtils.format(stockValue),
                '$lowStock',
                '$outOfStock',
              ],
            ],
            headerStyle: pw.TextStyle(
              fontSize: 8,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.center,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.center,
              4: pw.Alignment.center,
            },
          ),
          pw.SizedBox(height: 16),
          pw.Text(
            'Détail par catégorie',
            style: const pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: const {
              0: pw.FlexColumnWidth(1.1),
              1: pw.FlexColumnWidth(3),
              2: pw.FlexColumnWidth(2),
              3: pw.FlexColumnWidth(1),
              4: pw.FlexColumnWidth(1),
              5: pw.FlexColumnWidth(1),
              6: pw.FlexColumnWidth(1.4),
            },
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
                children: const [
                  _Cell(pw.Text('SKU', style: _headerStyle)),
                  _Cell(pw.Text('Nom', style: _headerStyle)),
                  _Cell(pw.Text('Catégorie', style: _headerStyle)),
                  _Cell(pw.Text('Prix', style: _headerStyle), alignRight: true),
                  _Cell(pw.Text('Coût', style: _headerStyle), alignRight: true),
                  _Cell(
                    pw.Text('Stock', style: _headerStyle),
                    alignRight: true,
                  ),
                  _Cell(
                    pw.Text('Valeur', style: _headerStyle),
                    alignRight: true,
                  ),
                ],
              ),
              for (final entry in byCategory.entries)
                ..._categoryRows(entry, categoryNames),
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                children: [
                  _Cell(
                    pw.Text(
                      'TOTAL',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                  ),
                  const _Cell(pw.SizedBox.shrink()),
                  const _Cell(pw.SizedBox.shrink()),
                  const _Cell(pw.SizedBox.shrink()),
                  const _Cell(pw.SizedBox.shrink()),
                  _Cell(
                    pw.Text(
                      '${totalUnits.round()}',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    alignRight: true,
                  ),
                  _Cell(
                    pw.Text(
                      CurrencyUtils.format(stockValue),
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    alignRight: true,
                  ),
                ],
              ),
            ],
          ),
        ],
        footer: (context) => pw.Text(
          'Page ${context.pageNumber} / ${context.pagesCount}',
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
        ),
      ),
    );

    return doc.save();
  }

  static List<pw.TableRow> _categoryRows(
    MapEntry<int?, List<Product>> entry,
    Map<int, String> categoryNames,
  ) {
    final products = entry.value;
    final categoryLabel = entry.key == null
        ? 'Sans catégorie'
        : categoryNames[entry.key] ?? 'Sans catégorie';
    final subtotal = products.fold<double>(
      0,
      (s, p) => s + p.stock * (p.costPrice > 0 ? p.costPrice : p.price),
    );

    return [
      for (final product in products)
        pw.TableRow(
          children: [
            _Cell(pw.Text(product.sku, style: _cellStyle)),
            _Cell(pw.Text(product.name, style: _cellStyle)),
            _Cell(pw.Text(categoryLabel, style: _cellStyle)),
            _Cell(
              pw.Text(CurrencyUtils.format(product.price), style: _cellStyle),
              alignRight: true,
            ),
            _Cell(
              pw.Text(
                CurrencyUtils.format(product.costPrice),
                style: _cellStyle,
              ),
              alignRight: true,
            ),
            _Cell(
              pw.Text('${product.stock.round()}', style: _cellStyle),
              alignRight: true,
            ),
            _Cell(
              pw.Text(
                CurrencyUtils.format(
                  product.stock *
                      (product.costPrice > 0
                          ? product.costPrice
                          : product.price),
                ),
                style: _cellStyle,
              ),
              alignRight: true,
            ),
          ],
        ),
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          const _Cell(pw.SizedBox.shrink()),
          const _Cell(pw.SizedBox.shrink()),
          _Cell(
            pw.Text(
              'Sous-total $categoryLabel',
              style: pw.TextStyle(
                fontSize: 8,
                fontWeight: pw.FontWeight.bold,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ),
          const _Cell(pw.SizedBox.shrink()),
          const _Cell(pw.SizedBox.shrink()),
          _Cell(
            pw.Text(
              '${products.fold<double>(0, (s, p) => s + p.stock).round()}',
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            alignRight: true,
          ),
          _Cell(
            pw.Text(
              CurrencyUtils.format(subtotal),
              style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
            ),
            alignRight: true,
          ),
        ],
      ),
    ];
  }
}

const _headerStyle = pw.TextStyle(
  fontSize: 8,
  fontWeight: pw.FontWeight.bold,
  color: PdfColors.grey800,
);

const _cellStyle = pw.TextStyle(fontSize: 8);

class _Cell extends pw.StatelessWidget {
  const _Cell(this.child, {this.alignRight = false});

  final pw.Widget child;
  final bool alignRight;

  @override
  pw.Widget build(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: alignRight
          ? pw.Alignment.centerRight
          : pw.Alignment.centerLeft,
      child: child,
    );
  }
}
