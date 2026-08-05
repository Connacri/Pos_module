import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'package:pos_core/pos_core.dart';
import 'package:pos_domain/pos_domain.dart';

/// Largeurs des colonnes du tableau d'inventaire, réparties selon le contenu
/// réel de chaque case : les zones à remplir à la main (case à cocher, quantité
/// réelle, écart) sont les plus généreuses, les montants gardent une largeur
/// suffisante pour le format monétaire, les identifiants restent compacts.
const _columnWidths = <int, pw.TableColumnWidth>{
  0: pw.FlexColumnWidth(1.2), // SKU
  1: pw.FlexColumnWidth(3.2), // Nom du produit
  2: pw.FlexColumnWidth(2.0), // Catégorie
  3: pw.FlexColumnWidth(1.2), // Prix
  4: pw.FlexColumnWidth(1.4), // Coût
  5: pw.FlexColumnWidth(1.1), // Stock
  6: pw.FlexColumnWidth(1.8), // Valeur
  7: pw.FlexColumnWidth(0.55), // ✓
  8: pw.FlexColumnWidth(1.9), // Qté réelle
  9: pw.FlexColumnWidth(1.5), // Écart
};

/// Hauteur des zones de saisie manuelle (case à cocher / à écrire).
const double _boxHeight = 16;

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

    var stripe = 0;
    final categoryRows = <pw.TableRow>[];
    for (final entry in byCategory.entries) {
      final (rows, next) = _categoryRows(entry, categoryNames, stripe);
      categoryRows.addAll(rows);
      stripe = next;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    title,
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    'Feuille de comptage — tous les montants en DA',
                    style: const pw.TextStyle(
                      fontSize: 10,
                      color: PdfColors.grey700,
                    ),
                  ),
                ],
              ),
              pw.Text(
                '${now.day.toString().padLeft(2, '0')}/'
                '${now.month.toString().padLeft(2, '0')}/${now.year}',
                style: const pw.TextStyle(fontSize: 10),
              ),
            ],
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
              fontSize: 9,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.blueGrey700,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            border: pw.TableBorder.all(
              color: PdfColors.grey400,
              width: 0.5,
            ),
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
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Table(
            columnWidths: _columnWidths,
            border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blueGrey700,
                ),
                children: [
                  _Cell(pw.Text('SKU', style: _headerStyle)),
                  _Cell(pw.Text('Nom du produit', style: _headerStyle)),
                  _Cell(pw.Text('Catégorie', style: _headerStyle)),
                  _Cell(pw.Text('Prix', style: _headerStyle), alignRight: true),
                  _Cell(
                    pw.Text('Coût', style: _headerStyle),
                    alignRight: true,
                  ),
                  _Cell(
                    pw.Text('Stock', style: _headerStyle),
                    alignRight: true,
                  ),
                  _Cell(
                    pw.Text('Valeur', style: _headerStyle),
                    alignRight: true,
                  ),
                  _Cell(
                    pw.Text('✓', style: _headerStyle),
                    alignment: pw.Alignment.center,
                  ),
                  _Cell(
                    pw.Text('Qté réelle', style: _headerStyle),
                    alignment: pw.Alignment.center,
                  ),
                  _Cell(
                    pw.Text('Écart', style: _headerStyle),
                    alignment: pw.Alignment.center,
                  ),
                ],
              ),
              for (final row in categoryRows) row,
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
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
                  _Cell(pw.SizedBox.shrink()),
                  _Cell(pw.SizedBox.shrink()),
                  _Cell(pw.SizedBox.shrink()),
                  _Cell(pw.SizedBox.shrink()),
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
                  _Cell(pw.SizedBox.shrink()),
                  _Cell(pw.SizedBox.shrink()),
                  _Cell(pw.SizedBox.shrink()),
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

  /// Retourne les lignes d'une catégorie : une ligne par produit (avec cases à
  /// cocher / à écrire) puis le sous-total de la catégorie.
  ///
  /// [stripe] est incrémenté à chaque ligne produit pour alterner la couleur de
  /// fond (zèbre) et améliorer la lisibilité sur papier. Retourne le nouveau
  /// compteur afin que l'alternance soit continue d'une catégorie à l'autre.
  static (List<pw.TableRow>, int) _categoryRows(
    MapEntry<int?, List<Product>> entry,
    Map<int, String> categoryNames,
    int stripe,
  ) {
    final products = entry.value;
    final categoryLabel = entry.key == null
        ? 'Sans catégorie'
        : categoryNames[entry.key] ?? 'Sans catégorie';
    final subtotal = products.fold<double>(
      0,
      (s, p) => s + p.stock * (p.costPrice > 0 ? p.costPrice : p.price),
    );

    final rows = <pw.TableRow>[
      for (var i = 0; i < products.length; i++)
        pw.TableRow(
          decoration: pw.BoxDecoration(
            color: (stripe + i).isEven ? PdfColors.grey50 : PdfColors.white,
          ),
          children: [
            _Cell(pw.Text(products[i].sku, style: _cellStyle)),
            _Cell(pw.Text(products[i].name, style: _cellStyle)),
            _Cell(pw.Text(categoryLabel, style: _cellStyle)),
            _Cell(
              pw.Text(_money(products[i].price), style: _cellStyle),
              alignRight: true,
            ),
            _Cell(
              pw.Text(_money(products[i].costPrice), style: _cellStyle),
              alignRight: true,
            ),
            _Cell(
              pw.Text(
                _quantity(products[i].stock),
                style: _cellStyle,
              ),
              alignRight: true,
            ),
            _Cell(
              pw.Text(
                _money(
                  products[i].stock *
                      (products[i].costPrice > 0
                          ? products[i].costPrice
                          : products[i].price),
                ),
                style: _cellStyle,
              ),
              alignRight: true,
            ),
            _Cell(_box(_checkBox()), alignment: pw.Alignment.center),
            _Cell(_box(pw.SizedBox()), alignment: pw.Alignment.center),
            _Cell(_box(pw.SizedBox()), alignment: pw.Alignment.center),
          ],
        ),
    ];

    rows.add(
      pw.TableRow(
        decoration: const pw.BoxDecoration(color: PdfColors.blueGrey50),
        children: [
          _Cell(pw.SizedBox.shrink()),
          _Cell(pw.SizedBox.shrink()),
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
          _Cell(pw.SizedBox.shrink()),
          _Cell(pw.SizedBox.shrink()),
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
          _Cell(pw.SizedBox.shrink()),
          _Cell(pw.SizedBox.shrink()),
          _Cell(pw.SizedBox.shrink()),
        ],
      ),
    );

    return (rows, stripe + products.length);
  }

  /// Boîte de saisie : une zone vide avec bordure, centrée dans sa cellule et
  /// d'une hauteur fixe adaptée à l'écriture manuelle.
  static pw.Widget _box(pw.Widget child) {
    return pw.Container(
      height: _boxHeight,
      width: double.infinity,
      alignment: pw.Alignment.center,
      margin: const pw.EdgeInsets.symmetric(horizontal: 4),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 0.6),
        borderRadius: pw.BorderRadius.circular(2),
      ),
      child: child,
    );
  }

  static pw.Widget _checkBox() {
    return pw.Container(
      width: 11,
      height: 11,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
        borderRadius: pw.BorderRadius.circular(1),
      ),
    );
  }

  /// Format monétaire compact pour les cellules : « 12 345,67 » (le symbole DA
  /// est porté par l'en-tête de document pour gagner de la largeur).
  static String _money(double value) {
    final parts = value.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final buffer = StringBuffer();
    for (var i = 0; i < intPart.length; i++) {
      buffer.write(intPart[i]);
      final remaining = intPart.length - i - 1;
      if (remaining > 0 && remaining % 3 == 0) buffer.write(' ');
    }
    return '$buffer,${parts[1]}';
  }

  /// Quantité affichée sans décimale superflue (2 décimales au besoin).
  static String _quantity(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }
    return value.toStringAsFixed(2);
  }
}

final _headerStyle = pw.TextStyle(
  fontSize: 8.5,
  fontWeight: pw.FontWeight.bold,
  color: PdfColors.white,
);

const _cellStyle = pw.TextStyle(fontSize: 8);

class _Cell extends pw.StatelessWidget {
  _Cell(
    this.child, {
    this.alignRight = false,
    this.alignment,
  });

  final pw.Widget child;
  final bool alignRight;
  final pw.Alignment? alignment;

  @override
  pw.Widget build(pw.Context context) {
    final resolved = alignment ??
        (alignRight
            ? pw.Alignment.centerRight
            : pw.Alignment.centerLeft);
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      alignment: resolved,
      child: child,
    );
  }
}
