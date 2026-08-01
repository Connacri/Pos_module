import 'package:pos_domain/pos_domain.dart';

class SeedCategory {
  const SeedCategory({
    required this.id,
    required this.name,
    this.parentId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  final int id;
  final String name;
  final int? parentId;
  final int sortOrder;
  final bool isActive;
}

class SeedProduct {
  const SeedProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.categoryId,
    required this.price,
    required this.costPrice,
    required this.stock,
    this.description,
    this.taxRate = 0.19,
    this.lowStockThreshold = 5,
    this.barcode,
    this.isActive = true,
  });

  final int id;
  final String sku;
  final String name;
  final int categoryId;
  final double price;
  final double costPrice;
  final double stock;
  final String? description;
  final double taxRate;
  final double lowStockThreshold;
  final String? barcode;
  final bool isActive;
}

class SeedCustomer {
  const SeedCustomer({
    required this.id,
    required this.name,
    this.phone,
    this.email,
    this.address,
    this.company,
    this.taxId,
    this.notes,
  });

  final int id;
  final String name;
  final String? phone;
  final String? email;
  final String? address;
  final String? company;
  final String? taxId;
  final String? notes;
}

class SeedSaleItem {
  const SeedSaleItem({
    required this.productId,
    required this.quantity,
    this.unitPrice,
    this.discount = 0,
  });

  final int productId;
  final double quantity;
  final double? unitPrice;
  final double discount;
}

class SeedSale {
  const SeedSale({
    required this.id,
    required this.saleNumber,
    this.customerId,
    required this.paymentMethod,
    required this.status,
    this.discountTotal = 0,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String saleNumber;
  final int? customerId;
  final PaymentMethod paymentMethod;
  final SaleStatus status;
  final double discountTotal;
  final DateTime createdAt;
  final List<SeedSaleItem> items;
}

class SeedInvoiceItem {
  const SeedInvoiceItem({
    required this.productId,
    required this.description,
    required this.quantity,
    this.unitPrice,
    this.taxRate = 0.19,
    this.discount = 0,
  });

  final int productId;
  final String description;
  final double quantity;
  final double? unitPrice;
  final double taxRate;
  final double discount;
}

class SeedInvoice {
  const SeedInvoice({
    required this.id,
    required this.invoiceNumber,
    this.saleId,
    this.customerId,
    required this.status,
    this.discountTotal = 0,
    this.dueDate,
    required this.createdAt,
    required this.items,
  });

  final int id;
  final String invoiceNumber;
  final int? saleId;
  final int? customerId;
  final InvoiceStatus status;
  final double discountTotal;
  final DateTime? dueDate;
  final DateTime createdAt;
  final List<SeedInvoiceItem> items;
}

class SeedPayment {
  const SeedPayment({
    required this.id,
    required this.amount,
    required this.method,
    this.saleId,
    this.invoiceId,
    this.reference,
    required this.paidAt,
  });

  final int id;
  final double amount;
  final PaymentMethod method;
  final int? saleId;
  final int? invoiceId;
  final String? reference;
  final DateTime paidAt;
}

class SeedData {
  SeedData._();

  static final List<SeedCategory> categories = [
    const SeedCategory(id: 1, name: 'Boissons', sortOrder: 1),
    const SeedCategory(id: 2, name: 'Alimentation', sortOrder: 2),
    const SeedCategory(id: 3, name: 'Hygiène & Beauté', sortOrder: 3),
    const SeedCategory(id: 4, name: 'Électronique', sortOrder: 4),
    const SeedCategory(id: 5, name: 'Boulangerie', sortOrder: 5),
    const SeedCategory(id: 6, name: 'Entretien', sortOrder: 6),
  ];

  static final List<SeedProduct> products = [
    const SeedProduct(
      id: 1,
      sku: 'REF-0001',
      name: 'Coca-Cola 33cl',
      categoryId: 1,
      price: 120,
      costPrice: 80,
      stock: 100,
      description: 'Canette 33cl, boisson gazeuse',
      taxRate: 0.19,
      lowStockThreshold: 20,
      barcode: '613000000001',
    ),
    const SeedProduct(
      id: 2,
      sku: 'REF-0002',
      name: 'Eau minérale 1,5L',
      categoryId: 1,
      price: 60,
      costPrice: 35,
      stock: 200,
      description: 'Bouteille 1,5 litre',
      taxRate: 0.09,
      lowStockThreshold: 40,
      barcode: '613000000002',
    ),
    const SeedProduct(
      id: 3,
      sku: 'REF-0003',
      name: 'Jus d\'orange 1L',
      categoryId: 1,
      price: 180,
      costPrice: 120,
      stock: 45,
      description: 'Jus 100% orange, brique 1L',
      taxRate: 0.19,
      lowStockThreshold: 15,
      barcode: '613000000003',
    ),
    const SeedProduct(
      id: 4,
      sku: 'REF-0004',
      name: 'Huile d\'olive 1L',
      categoryId: 2,
      price: 950,
      costPrice: 700,
      stock: 60,
      description: 'Huile d\'olive extra vierge',
      taxRate: 0.19,
      lowStockThreshold: 10,
      barcode: '613000000004',
    ),
    const SeedProduct(
      id: 5,
      sku: 'REF-0005',
      name: 'Riz basmati 5kg',
      categoryId: 2,
      price: 2200,
      costPrice: 1800,
      stock: 35,
      description: 'Sac de riz basmati 5kg',
      taxRate: 0.19,
      lowStockThreshold: 8,
      barcode: '613000000005',
    ),
    const SeedProduct(
      id: 6,
      sku: 'REF-0006',
      name: 'Couscous 1kg',
      categoryId: 2,
      price: 260,
      costPrice: 190,
      stock: 80,
      description: 'Couscous moyen 1kg',
      taxRate: 0.19,
      lowStockThreshold: 20,
      barcode: '613000000006',
    ),
    const SeedProduct(
      id: 7,
      sku: 'REF-0007',
      name: 'Pâtes spaghetti 500g',
      categoryId: 2,
      price: 150,
      costPrice: 100,
      stock: 120,
      description: 'Paquet de spaghetti 500g',
      taxRate: 0.19,
      lowStockThreshold: 25,
      barcode: '613000000007',
    ),
    const SeedProduct(
      id: 8,
      sku: 'REF-0008',
      name: 'Shampooing 500ml',
      categoryId: 3,
      price: 450,
      costPrice: 300,
      stock: 40,
      description: 'Shampooing cheveux normaux',
      taxRate: 0.19,
      lowStockThreshold: 10,
      barcode: '613000000008',
    ),
    const SeedProduct(
      id: 9,
      sku: 'REF-0009',
      name: 'Dentifrice 100ml',
      categoryId: 3,
      price: 220,
      costPrice: 140,
      stock: 6,
      description: 'Dentifrice blancheur',
      taxRate: 0.19,
      lowStockThreshold: 15,
      barcode: '613000000009',
    ),
    const SeedProduct(
      id: 10,
      sku: 'REF-0010',
      name: 'Gel douche 250ml',
      categoryId: 3,
      price: 300,
      costPrice: 200,
      stock: 0,
      description: 'Gel douche hydratant',
      taxRate: 0.19,
      lowStockThreshold: 12,
      barcode: '613000000010',
    ),
    const SeedProduct(
      id: 11,
      sku: 'REF-0011',
      name: 'Câble USB-C 1m',
      categoryId: 4,
      price: 350,
      costPrice: 150,
      stock: 90,
      description: 'Câble de charge rapide USB-C',
      taxRate: 0.19,
      lowStockThreshold: 20,
      barcode: '613000000011',
    ),
    const SeedProduct(
      id: 12,
      sku: 'REF-0012',
      name: 'Chargeur 25W',
      categoryId: 4,
      price: 900,
      costPrice: 500,
      stock: 30,
      description: 'Chargeur murale 25W USB-C',
      taxRate: 0.19,
      lowStockThreshold: 8,
      barcode: '613000000012',
    ),
    const SeedProduct(
      id: 13,
      sku: 'REF-0013',
      name: 'Écouteurs Bluetooth',
      categoryId: 4,
      price: 2500,
      costPrice: 1500,
      stock: 15,
      description: 'Écouteurs sans fil avec étui',
      taxRate: 0.19,
      lowStockThreshold: 5,
      barcode: '613000000013',
    ),
    const SeedProduct(
      id: 14,
      sku: 'REF-0014',
      name: 'Pain complet',
      categoryId: 5,
      price: 25,
      costPrice: 12,
      stock: 0,
      description: 'Pain de campagne complet',
      taxRate: 0.0,
      lowStockThreshold: 30,
      barcode: '613000000014',
    ),
    const SeedProduct(
      id: 15,
      sku: 'REF-0015',
      name: 'Baguette',
      categoryId: 5,
      price: 15,
      costPrice: 7,
      stock: 150,
      description: 'Baguette traditionnelle',
      taxRate: 0.0,
      lowStockThreshold: 40,
      barcode: '613000000015',
    ),
    const SeedProduct(
      id: 16,
      sku: 'REF-0016',
      name: 'Lessive 2kg',
      categoryId: 6,
      price: 850,
      costPrice: 600,
      stock: 25,
      description: 'Lessive poudre 2kg',
      taxRate: 0.19,
      lowStockThreshold: 8,
      barcode: '613000000016',
    ),
    const SeedProduct(
      id: 17,
      sku: 'REF-0017',
      name: 'Produit vaisselle 750ml',
      categoryId: 6,
      price: 180,
      costPrice: 110,
      stock: 55,
      description: 'Liquide vaisselle citron',
      taxRate: 0.19,
      lowStockThreshold: 15,
      barcode: '613000000017',
    ),
    const SeedProduct(
      id: 18,
      sku: 'REF-0018',
      name: 'Sac poubelle 50L',
      categoryId: 6,
      price: 120,
      costPrice: 70,
      stock: 130,
      description: 'Rouleau 50L (lot de 20)',
      taxRate: 0.19,
      lowStockThreshold: 25,
      barcode: '613000000018',
    ),
  ];

  static final List<SeedCustomer> customers = [
    const SeedCustomer(
      id: 1,
      name: 'Kamel Benali',
      phone: '0550 12 34 56',
      email: 'kamel.benali@example.dz',
      address: 'Cité 200 Logts, Alger',
      company: 'SARL Benali Import',
      taxId: '099912345678',
    ),
    const SeedCustomer(
      id: 2,
      name: 'Fatima Zohra',
      phone: '0661 98 76 54',
      email: 'fatima.zohra@example.dz',
      address: 'Rue Didouche Mourad, Alger',
    ),
    const SeedCustomer(
      id: 3,
      name: 'Restaurant Le Gourmet',
      phone: '023 45 67 89',
      email: 'contact@legourmet.dz',
      address: 'Zone d\'activité, Oran',
      company: 'EURL Le Gourmet',
      taxId: '099876543210',
      notes: 'Client professionnel, facturation 30 jours',
    ),
    const SeedCustomer(
      id: 4,
      name: 'Amina Cherif',
      phone: '0770 22 33 44',
      address: 'Boulevard Zighout Youcef, Constantine',
    ),
    const SeedCustomer(
      id: 5,
      name: 'Épicerie du Centre',
      phone: '0555 11 22 33',
      email: 'epicerie.centre@example.dz',
      company: 'SARL Épicerie du Centre',
      taxId: '099900112233',
      notes: 'Revente en gros',
    ),
    const SeedCustomer(
      id: 6,
      name: 'Mohamed Larbi',
      phone: '0666 44 55 66',
      address: 'Cité 5 Juillet, Blida',
    ),
  ];

  static final List<SeedSale> sales = _buildSales();

  static List<SeedSale> _buildSales() {
    final now = DateTime.now();
    return [
      SeedSale(
        id: 1,
        saleNumber: '000001',
        customerId: 1,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 10)),
        items: const [
          SeedSaleItem(productId: 1, quantity: 2),
          SeedSaleItem(productId: 2, quantity: 4),
          SeedSaleItem(productId: 6, quantity: 1),
        ],
      ),
      SeedSale(
        id: 2,
        saleNumber: '000002',
        customerId: 3,
        paymentMethod: PaymentMethod.card,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 8)),
        items: const [
          SeedSaleItem(productId: 5, quantity: 2),
          SeedSaleItem(productId: 4, quantity: 3),
          SeedSaleItem(productId: 15, quantity: 20),
        ],
      ),
      SeedSale(
        id: 3,
        saleNumber: '000003',
        customerId: 2,
        paymentMethod: PaymentMethod.mobileMoney,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 6)),
        items: const [
          SeedSaleItem(productId: 7, quantity: 5),
          SeedSaleItem(productId: 11, quantity: 2),
        ],
      ),
      SeedSale(
        id: 4,
        saleNumber: '000004',
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 4)),
        items: const [
          SeedSaleItem(productId: 2, quantity: 10),
          SeedSaleItem(productId: 1, quantity: 3),
          SeedSaleItem(productId: 8, quantity: 1),
          SeedSaleItem(productId: 17, quantity: 2),
        ],
      ),
      SeedSale(
        id: 5,
        saleNumber: '000005',
        customerId: 5,
        paymentMethod: PaymentMethod.bankTransfer,
        status: SaleStatus.completed,
        discountTotal: 100,
        createdAt: now.subtract(const Duration(days: 3)),
        items: const [
          SeedSaleItem(productId: 12, quantity: 5),
          SeedSaleItem(productId: 13, quantity: 2),
          SeedSaleItem(productId: 11, quantity: 10),
        ],
      ),
      SeedSale(
        id: 6,
        saleNumber: '000006',
        customerId: 4,
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 2)),
        items: const [
          SeedSaleItem(productId: 9, quantity: 3),
          SeedSaleItem(productId: 10, quantity: 1),
          SeedSaleItem(productId: 16, quantity: 1),
        ],
      ),
      SeedSale(
        id: 7,
        saleNumber: '000007',
        customerId: 6,
        paymentMethod: PaymentMethod.card,
        status: SaleStatus.completed,
        createdAt: now.subtract(const Duration(days: 1)),
        items: const [
          SeedSaleItem(productId: 13, quantity: 1),
          SeedSaleItem(productId: 4, quantity: 2),
          SeedSaleItem(productId: 2, quantity: 6),
        ],
      ),
      SeedSale(
        id: 8,
        saleNumber: '000008',
        paymentMethod: PaymentMethod.cash,
        status: SaleStatus.pending,
        createdAt: now.subtract(const Duration(hours: 5)),
        items: const [
          SeedSaleItem(productId: 15, quantity: 4),
          SeedSaleItem(productId: 1, quantity: 2),
        ],
      ),
    ];
  }

  static final List<SeedInvoice> invoices = [
    SeedInvoice(
      id: 1,
      invoiceNumber: '000001',
      saleId: 2,
      customerId: 3,
      status: InvoiceStatus.paid,
      createdAt: DateTime.now().subtract(const Duration(days: 8)),
      items: const [
        SeedInvoiceItem(
          productId: 5,
          description: 'Riz basmati 5kg',
          quantity: 2,
        ),
        SeedInvoiceItem(
          productId: 4,
          description: 'Huile d\'olive 1L',
          quantity: 3,
        ),
        SeedInvoiceItem(
          productId: 15,
          description: 'Baguette',
          quantity: 20,
          taxRate: 0.0,
        ),
      ],
    ),
    SeedInvoice(
      id: 2,
      invoiceNumber: '000002',
      customerId: 3,
      status: InvoiceStatus.issued,
      discountTotal: 50,
      dueDate: DateTime.now().add(const Duration(days: 20)),
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
      items: const [
        SeedInvoiceItem(
          productId: 12,
          description: 'Chargeur 25W',
          quantity: 5,
        ),
        SeedInvoiceItem(
          productId: 13,
          description: 'Écouteurs Bluetooth',
          quantity: 2,
        ),
        SeedInvoiceItem(
          productId: 11,
          description: 'Câble USB-C 1m',
          quantity: 10,
        ),
      ],
    ),
    SeedInvoice(
      id: 3,
      invoiceNumber: '000003',
      customerId: 5,
      status: InvoiceStatus.overdue,
      dueDate: DateTime.now().subtract(const Duration(days: 5)),
      createdAt: DateTime.now().subtract(const Duration(days: 35)),
      items: const [
        SeedInvoiceItem(
          productId: 6,
          description: 'Couscous 1kg',
          quantity: 20,
        ),
        SeedInvoiceItem(
          productId: 2,
          description: 'Eau minérale 1,5L',
          quantity: 24,
          taxRate: 0.09,
        ),
      ],
    ),
    SeedInvoice(
      id: 4,
      invoiceNumber: '000004',
      customerId: 1,
      status: InvoiceStatus.paid,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      items: const [
        SeedInvoiceItem(
          productId: 9,
          description: 'Dentifrice 100ml',
          quantity: 3,
        ),
        SeedInvoiceItem(
          productId: 16,
          description: 'Lessive 2kg',
          quantity: 1,
        ),
        SeedInvoiceItem(
          productId: 8,
          description: 'Shampooing 500ml',
          quantity: 1,
        ),
      ],
    ),
    SeedInvoice(
      id: 5,
      invoiceNumber: '000005',
      saleId: 8,
      status: InvoiceStatus.draft,
      createdAt: DateTime.now().subtract(const Duration(hours: 3)),
      items: const [
        SeedInvoiceItem(
          productId: 15,
          description: 'Baguette',
          quantity: 4,
          taxRate: 0.0,
        ),
        SeedInvoiceItem(
          productId: 1,
          description: 'Coca-Cola 33cl',
          quantity: 2,
        ),
      ],
    ),
  ];

  static final List<SeedPayment> payments = [
    SeedPayment(
      id: 1,
      amount: 0,
      method: PaymentMethod.cash,
      saleId: 1,
      reference: 'TICKET-000001',
      paidAt: DateTime.now().subtract(const Duration(days: 10)),
    ),
    SeedPayment(
      id: 2,
      amount: 0,
      method: PaymentMethod.card,
      saleId: 2,
      reference: 'TICKET-000002',
      paidAt: DateTime.now().subtract(const Duration(days: 8)),
    ),
    SeedPayment(
      id: 3,
      amount: 0,
      method: PaymentMethod.mobileMoney,
      saleId: 3,
      reference: 'TICKET-000003',
      paidAt: DateTime.now().subtract(const Duration(days: 6)),
    ),
    SeedPayment(
      id: 4,
      amount: 0,
      method: PaymentMethod.cash,
      saleId: 4,
      reference: 'TICKET-000004',
      paidAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
    SeedPayment(
      id: 5,
      amount: 0,
      method: PaymentMethod.bankTransfer,
      saleId: 5,
      reference: 'TICKET-000005',
      paidAt: DateTime.now().subtract(const Duration(days: 3)),
    ),
    SeedPayment(
      id: 6,
      amount: 0,
      method: PaymentMethod.cash,
      saleId: 6,
      reference: 'TICKET-000006',
      paidAt: DateTime.now().subtract(const Duration(days: 2)),
    ),
    SeedPayment(
      id: 7,
      amount: 0,
      method: PaymentMethod.card,
      saleId: 7,
      reference: 'TICKET-000007',
      paidAt: DateTime.now().subtract(const Duration(days: 1)),
    ),
    SeedPayment(
      id: 8,
      amount: 0,
      method: PaymentMethod.cash,
      invoiceId: 3,
      reference: 'REG-000003',
      paidAt: DateTime.now().subtract(const Duration(days: 5)),
    ),
  ];

  static Map<int, SeedProduct> get productById =>
      {for (final p in products) p.id: p};
}
