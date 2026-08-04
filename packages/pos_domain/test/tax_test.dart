import 'package:test/test.dart';

import 'package:pos_domain/pos_domain.dart';

void main() {
  group('SaleItem', () {
    const item = SaleItem(
      productId: 1,
      productName: 'Produit',
      sku: 'REF-1',
      unitPrice: 100,
      costPrice: 60,
      taxRate: 0.19,
      quantity: 2,
    );

    test('lineSubtotal = unitPrice * quantity', () {
      expect(item.lineSubtotal, 200);
    });

    test('taxAmount = lineSubtotal * taxRate', () {
      expect(item.taxAmount, closeTo(38, 0.001));
    });

    test('lineTotal = lineSubtotal + taxAmount', () {
      expect(item.lineTotal, closeTo(238, 0.001));
    });
  });

  group('SaleItem avec remise ligne', () {
    const item = SaleItem(
      productId: 1,
      productName: 'Produit',
      sku: 'REF-1',
      unitPrice: 100,
      costPrice: 60,
      taxRate: 0.19,
      quantity: 2,
      discount: 20,
    );

    test('la taxe se calcule sur le sous-total net de remise', () {
      expect(item.lineSubtotal, 180);
      expect(item.taxAmount, closeTo(34.2, 0.001));
      expect(item.lineTotal, closeTo(214.2, 0.001));
    });
  });

  group('Sale', () {
    const sale = Sale(
      id: 1,
      saleNumber: '000001',
      items: [
        SaleItem(
          productId: 1,
          productName: 'A',
          sku: 'A',
          unitPrice: 100,
          costPrice: 50,
          taxRate: 0.19,
          quantity: 1,
        ),
        SaleItem(
          productId: 2,
          productName: 'B',
          sku: 'B',
          unitPrice: 200,
          costPrice: 100,
          taxRate: 0,
          quantity: 1,
        ),
      ],
      discountTotal: 10,
      paymentMethod: PaymentMethod.cash,
    );

    test('total = subtotal + taxe - remise globale', () {
      expect(sale.subtotal, 300);
      expect(sale.taxTotal, closeTo(19, 0.001));
      expect(sale.total, closeTo(309, 0.001));
    });
  });

  group('Invoice', () {
    const invoice = Invoice(
      id: 1,
      invoiceNumber: '000001',
      items: [
        InvoiceItem(
          productId: 1,
          description: 'A',
          unitPrice: 100,
          quantity: 3,
          taxRate: 0.19,
        ),
      ],
      discountTotal: 20,
    );

    test('total = subtotal + taxe - remise globale', () {
      expect(invoice.subtotal, 300);
      expect(invoice.taxTotal, closeTo(57, 0.001));
      expect(invoice.total, closeTo(337, 0.001));
    });
  });

  group('ReturnRecord', () {
    const record = ReturnRecord(
      id: 1,
      saleId: 1,
      items: [
        ReturnItem(
          productId: 1,
          description: 'A',
          unitPrice: 100,
          quantity: 2,
          taxRate: 0.19,
        ),
      ],
    );

    test('refundTotal inclut la TVA', () {
      expect(record.subtotal, 200);
      expect(record.taxTotal, closeTo(38, 0.001));
      expect(record.refundTotal, closeTo(238, 0.001));
    });
  });
}
