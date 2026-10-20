export type PaymentMethod = 'CASH' | 'CARD' | 'TRANSFER' | 'CHEQUE';
export type SaleStatus = 'COMPLETED' | 'PENDING' | 'CANCELLED';

export interface Category {
  id: number;
  name: string;
  icon?: string;
  sortOrder: number;
  color?: string;
}

export interface Product {
  id: number;
  sku: string;
  name: string;
  categoryId: number;
  price: number;
  costPrice: number;
  stock: number;
  description?: string;
  taxRate: number; // e.g. 0.19, 0.09, 0.0
  lowStockThreshold: number;
  barcode: string;
  imageUrl?: string;
  isActive: boolean;
}

export interface Customer {
  id: number;
  name: string;
  phone?: string;
  email?: string;
  address?: string;
  company?: string;
  taxId?: string;
  notes?: string;
  balanceDue?: number;
}

export interface CartItem {
  product: Product;
  quantity: number;
  unitPrice: number;
  discountPercent: number; // 0 to 100
  note?: string;
}

export interface SaleItem {
  productId: number;
  productName: string;
  sku: string;
  quantity: number;
  unitPrice: number;
  taxRate: number;
  discountPercent: number;
  totalHT: number;
  totalTTC: number;
}

export interface Sale {
  id: number;
  saleNumber: string;
  customerId?: number;
  customerName?: string;
  items: SaleItem[];
  subtotalHT: number;
  taxTotal: number;
  discountTotal: number;
  totalTTC: number;
  paymentMethod: PaymentMethod;
  amountTendered?: number;
  changeGiven?: number;
  status: SaleStatus;
  createdAt: string; // ISO format
  notes?: string;
}

export interface DailyRevenueStat {
  date: string;
  formattedDate: string;
  revenue: number;
  cost: number;
  profit: number;
  orders: number;
  unitsSold: number;
}
