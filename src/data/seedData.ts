import { Category, Product, Customer, Sale } from '../types';

export const INITIAL_CATEGORIES: Category[] = [
  { id: 1, name: 'Boissons', icon: 'CupSoda', sortOrder: 1, color: '#3b82f6' },
  { id: 2, name: 'Alimentation', icon: 'Utensils', sortOrder: 2, color: '#10b981' },
  { id: 3, name: 'Hygiène & Soins', icon: 'Sparkles', sortOrder: 3, color: '#ec4899' },
  { id: 4, name: 'High-Tech & Accessoires', icon: 'Smartphone', sortOrder: 4, color: '#8b5cf6' },
  { id: 5, name: 'Boulangerie & Pâtisserie', icon: 'Croissant', sortOrder: 5, color: '#f59e0b' },
  { id: 6, name: 'Entretien & Maison', icon: 'Home', sortOrder: 6, color: '#06b6d4' },
];

export const INITIAL_PRODUCTS: Product[] = [
  {
    id: 1,
    sku: 'REF-0001',
    name: 'Coca-Cola 33cl',
    categoryId: 1,
    price: 120,
    costPrice: 80,
    stock: 95,
    description: 'Canette 33cl, boisson gazeuse fraîche',
    taxRate: 0.19,
    lowStockThreshold: 20,
    barcode: '613000000001',
    imageUrl: 'https://images.unsplash.com/photo-1622483767028-3f66f32aef97?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 2,
    sku: 'REF-0002',
    name: 'Eau minérale naturelle 1,5L',
    categoryId: 1,
    price: 60,
    costPrice: 35,
    stock: 180,
    description: 'Bouteille 1,5L pureté des montagnes',
    taxRate: 0.09,
    lowStockThreshold: 30,
    barcode: '613000000002',
    imageUrl: 'https://images.unsplash.com/photo-1548839140-29a749e1bc4e?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 3,
    sku: 'REF-0003',
    name: 'Jus d\'orange 100% Pur 1L',
    categoryId: 1,
    price: 180,
    costPrice: 120,
    stock: 45,
    description: 'Brique 1L sans sucre ajouté',
    taxRate: 0.19,
    lowStockThreshold: 15,
    barcode: '613000000003',
    imageUrl: 'https://images.unsplash.com/photo-1600271886742-f049cd451bba?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 4,
    sku: 'REF-0004',
    name: 'Huile d\'olive Vierge Extra 1L',
    categoryId: 2,
    price: 950,
    costPrice: 700,
    stock: 55,
    description: 'Huile d\'olive première pression à froid',
    taxRate: 0.19,
    lowStockThreshold: 10,
    barcode: '613000000004',
    imageUrl: 'https://images.unsplash.com/photo-1474979266404-7eaacbcd87c5?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 5,
    sku: 'REF-0005',
    name: 'Riz Basmati Sélection 5kg',
    categoryId: 2,
    price: 2200,
    costPrice: 1800,
    stock: 35,
    description: 'Sac de 5kg, grains longs parfumés',
    taxRate: 0.19,
    lowStockThreshold: 8,
    barcode: '613000000005',
    imageUrl: 'https://images.unsplash.com/photo-1586201375761-83865001e31c?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 6,
    sku: 'REF-0006',
    name: 'Couscous Fin Traditionnel 1kg',
    categoryId: 2,
    price: 190,
    costPrice: 130,
    stock: 80,
    description: 'Semoule de blé dur de qualité supérieure',
    taxRate: 0.09,
    lowStockThreshold: 15,
    barcode: '613000000006',
    imageUrl: 'https://images.unsplash.com/photo-1541544741938-0af808871cc0?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 7,
    sku: 'REF-0007',
    name: 'Café Moulu Torréfié 250g',
    categoryId: 2,
    price: 340,
    costPrice: 240,
    stock: 50,
    description: 'Arôme intense et corsé',
    taxRate: 0.19,
    lowStockThreshold: 12,
    barcode: '613000000007',
    imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 8,
    sku: 'REF-0008',
    name: 'Shampooing Nourrissant 400ml',
    categoryId: 3,
    price: 420,
    costPrice: 280,
    stock: 38,
    description: 'Enrichi à l\'huile d\'argan',
    taxRate: 0.19,
    lowStockThreshold: 10,
    barcode: '613000000008',
    imageUrl: 'https://images.unsplash.com/photo-1535585209827-a15fcdbc4c2d?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 9,
    sku: 'REF-0009',
    name: 'Dentifrice Blancheur Active 75ml',
    categoryId: 3,
    price: 160,
    costPrice: 95,
    stock: 65,
    description: 'Fraîcheur intense et protection émail',
    taxRate: 0.19,
    lowStockThreshold: 15,
    barcode: '613000000009',
    imageUrl: 'https://images.unsplash.com/photo-1559599101-f09722fb4948?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 10,
    sku: 'REF-0010',
    name: 'Savon liquide mains Aloe 500ml',
    categoryId: 3,
    price: 220,
    costPrice: 130,
    stock: 28,
    description: 'Flacon pompe avec agents hydratants',
    taxRate: 0.19,
    lowStockThreshold: 8,
    barcode: '613000000010',
    imageUrl: 'https://images.unsplash.com/photo-1600857544200-b2f666a9a2ec?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 11,
    sku: 'REF-0011',
    name: 'Chargeur Rapide USB-C PD 25W',
    categoryId: 4,
    price: 900,
    costPrice: 500,
    stock: 7, // Low stock alert
    description: 'Chargeur compact compatible smartphones et tablettes',
    taxRate: 0.19,
    lowStockThreshold: 10,
    barcode: '613000000011',
    imageUrl: 'https://images.unsplash.com/photo-1583863788434-e58a36330cf0?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 12,
    sku: 'REF-0012',
    name: 'Écouteurs Sans Fil TWS Bluetooth 5.3',
    categoryId: 4,
    price: 2500,
    costPrice: 1500,
    stock: 14,
    description: 'Réduction de bruit passive, boîtier autonome',
    taxRate: 0.19,
    lowStockThreshold: 5,
    barcode: '613000000012',
    imageUrl: 'https://images.unsplash.com/photo-1590658268037-6bf12165a8df?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 13,
    sku: 'REF-0013',
    name: 'Pain Complet Artisanal Bio',
    categoryId: 5,
    price: 25,
    costPrice: 12,
    stock: 0, // Out of stock
    description: 'Farine bio, levain naturel',
    taxRate: 0.0,
    lowStockThreshold: 15,
    barcode: '613000000013',
    imageUrl: 'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 14,
    sku: 'REF-0014',
    name: 'Baguette Traditionnelle Dorée',
    categoryId: 5,
    price: 15,
    costPrice: 7,
    stock: 140,
    description: 'Cuisson sur sole, croustillante',
    taxRate: 0.0,
    lowStockThreshold: 30,
    barcode: '613000000014',
    imageUrl: 'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 15,
    sku: 'REF-0015',
    name: 'Croissant au Beurre AOP',
    categoryId: 5,
    price: 45,
    costPrice: 20,
    stock: 60,
    description: 'Feuilletage artisanal pur beurre',
    taxRate: 0.09,
    lowStockThreshold: 15,
    barcode: '613000000015',
    imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 16,
    sku: 'REF-0016',
    name: 'Lessive Liquide Fraîcheur 2L',
    categoryId: 6,
    price: 850,
    costPrice: 600,
    stock: 25,
    description: 'Formule détachante efficace à froid',
    taxRate: 0.19,
    lowStockThreshold: 8,
    barcode: '613000000016',
    imageUrl: 'https://images.unsplash.com/photo-1610557892470-55d9e80c0bce?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 17,
    sku: 'REF-0017',
    name: 'Liquide Vaisselle Concentré Citron 750ml',
    categoryId: 6,
    price: 180,
    costPrice: 110,
    stock: 55,
    description: 'Dégraissant actif brillance express',
    taxRate: 0.19,
    lowStockThreshold: 15,
    barcode: '613000000017',
    imageUrl: 'https://images.unsplash.com/photo-1585670270677-3acce33679d2?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
  {
    id: 18,
    sku: 'REF-0018',
    name: 'Sacs Poubelle Ultra-Résistants 50L (x20)',
    categoryId: 6,
    price: 120,
    costPrice: 70,
    stock: 125,
    description: 'Avec lien coulissant étanche',
    taxRate: 0.19,
    lowStockThreshold: 25,
    barcode: '613000000018',
    imageUrl: 'https://images.unsplash.com/photo-1563245372-f21724e3856d?w=400&auto=format&fit=crop&q=80',
    isActive: true,
  },
];

export const INITIAL_CUSTOMERS: Customer[] = [
  {
    id: 1,
    name: 'Client Comptoir (Passager)',
    phone: '',
    email: '',
    address: 'Vente directe magasin',
    notes: 'Encaissements rapides sans compte pro',
    balanceDue: 0,
  },
  {
    id: 2,
    name: 'Kamel Benali',
    phone: '0550 12 34 56',
    email: 'kamel.benali@example.dz',
    address: 'Cité 200 Logts, Bab Ezzouar, Alger',
    company: 'SARL Benali Import',
    taxId: '099912345678',
    notes: 'Compte Pro - Règlement 30 jours fin de mois',
    balanceDue: 38575,
  },
  {
    id: 3,
    name: 'Fatima Zohra Mansouri',
    phone: '0661 98 76 54',
    email: 'fz.mansouri@algerie-tech.com',
    company: 'EURL Mansouri Services',
    taxId: '088876543210',
    address: 'Rue Didouche Mourad, Alger Centre',
    notes: 'Facturation officielle avec bon de commande',
    balanceDue: 12400,
  },
  {
    id: 4,
    name: 'Yacine Amrani',
    phone: '0770 45 67 89',
    email: 'yacine.amrani@gmail.com',
    address: 'Kouba, Alger',
    company: 'Amrani Retail',
    taxId: '077712349999',
    notes: 'Règlement Carte CIB / Espèces',
    balanceDue: 0,
  },
];

export function generateHistoricSales(): Sale[] {
  const sales: Sale[] = [];
  const now = new Date();

  const dailyPlans = [
    { offset: 13, count: 18, total: 34500 },
    { offset: 12, count: 22, total: 42800 },
    { offset: 11, count: 19, total: 37900 },
    { offset: 10, count: 26, total: 51200 },
    { offset: 9,  count: 28, total: 56400 },
    { offset: 8,  count: 35, total: 72100 }, // Saturday spike
    { offset: 7,  count: 31, total: 61500 },
    { offset: 6,  count: 21, total: 40200 },
    { offset: 5,  count: 25, total: 48900 },
    { offset: 4,  count: 27, total: 53100 },
    { offset: 3,  count: 32, total: 64800 },
    { offset: 2,  count: 38, total: 76400 },
    { offset: 1,  count: 34, total: 68500 },
    { offset: 0,  count: 24, total: 52400 }, // Today
  ];

  let idCounter = 1;

  dailyPlans.forEach(({ offset, count }) => {
    const dayDate = new Date(now);
    dayDate.setDate(dayDate.getDate() - offset);

    for (let i = 0; i < count; i++) {
      const saleDate = new Date(dayDate);
      saleDate.setHours(9 + Math.floor((i / count) * 11), Math.floor(Math.random() * 59));

      const p1 = INITIAL_PRODUCTS[Math.floor(Math.random() * INITIAL_PRODUCTS.length)];
      const p2 = INITIAL_PRODUCTS[Math.floor(Math.random() * INITIAL_PRODUCTS.length)];

      const qty1 = Math.floor(Math.random() * 3) + 1;
      const qty2 = Math.floor(Math.random() * 2) + 1;

      const items = [
        {
          productId: p1.id,
          productName: p1.name,
          sku: p1.sku,
          quantity: qty1,
          unitPrice: p1.price,
          taxRate: p1.taxRate,
          discountPercent: 0,
          totalHT: Math.round((p1.price * qty1) / (1 + p1.taxRate)),
          totalTTC: p1.price * qty1,
        },
      ];

      if (p1.id !== p2.id && Math.random() > 0.4) {
        items.push({
          productId: p2.id,
          productName: p2.name,
          sku: p2.sku,
          quantity: qty2,
          unitPrice: p2.price,
          taxRate: p2.taxRate,
          discountPercent: 0,
          totalHT: Math.round((p2.price * qty2) / (1 + p2.taxRate)),
          totalTTC: p2.price * qty2,
        });
      }

      const totalTTC = items.reduce((sum, item) => sum + item.totalTTC, 0);
      const subtotalHT = items.reduce((sum, item) => sum + item.totalHT, 0);
      const taxTotal = totalTTC - subtotalHT;

      const isCard = Math.random() > 0.65;
      const isCheque = Math.random() > 0.95;
      const method = isCheque ? 'CHEQUE' : isCard ? 'CARD' : 'CASH';

      const custIndex = Math.random() > 0.6 ? Math.floor(Math.random() * 3) + 1 : 0;
      const customer = INITIAL_CUSTOMERS[custIndex];

      const saleNumber = `INV-${saleDate.getFullYear()}${(saleDate.getMonth() + 1)
        .toString()
        .padStart(2, '0')}-${idCounter.toString().padStart(4, '0')}`;

      sales.push({
        id: idCounter,
        saleNumber,
        customerId: customer.id,
        customerName: customer.name,
        items,
        subtotalHT,
        taxTotal,
        discountTotal: 0,
        totalTTC,
        paymentMethod: method,
        status: 'COMPLETED',
        createdAt: saleDate.toISOString(),
      });

      idCounter++;
    }
  });

  return sales;
}
