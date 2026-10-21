import React, { createContext, useContext, useState, useEffect, useMemo, useCallback } from 'react';
import {
  Product,
  Category,
  Customer,
  CartItem,
  Sale,
  SaleItem,
  PaymentMethod,
  DailyRevenueStat,
  ThermalPrinterSettings,
} from '../types';
import {
  INITIAL_CATEGORIES,
  INITIAL_PRODUCTS,
  INITIAL_CUSTOMERS,
  generateHistoricSales,
} from '../data/seedData';
import { ultraLocalDb } from '../services/localDb';
import { posSounds } from '../services/soundService';
import { supabaseSyncService, SupabaseConfig } from '../services/supabaseSyncService';

interface CartSummary {
  subtotalHT: number;
  totalTax: number;
  discountAmount: number;
  totalTTC: number;
  totalItems: number;
  uniqueCount: number;
}

export type ViewType = 'dashboard' | 'pos' | 'catalog' | 'sales' | 'customers' | 'admin';

export const DEFAULT_PRINTER_SETTINGS: ThermalPrinterSettings = {
  paperWidth: '80mm',
  printerInterface: 'SYSTEM_DEFAULT',
  printerName: 'Imprimante Thermique Système (80mm ESC/POS)',
  printerIp: '192.168.1.200',
  printerPort: 9100,
  autoCut: true,
  openCashDrawer: true,
  printLogo: true,
  logoDataUrl: '',
  storeName: 'SHERWOOD ISLAND POS',
  storeSubtitle: 'Boutique & Caisse Artisanale',
  storeAddress: '14 Boulevard Zighout Youcef, 16000 Alger',
  storePhone: '+213 (0) 21 73 45 67',
  storeTaxId: 'NIF: 099900112233001 • RC: 16/00-0987654',
  receiptFooterMessage: 'Merci de votre visite à Sherwood Island ! Articles échangeables sous 15 jours sur présentation du ticket.',
  printCopies: 1,
};

interface PosContextType {
  // Navigation & Active View
  activeView: ViewType;
  setActiveView: (view: ViewType) => void;
  isMobileMenuOpen: boolean;
  setIsMobileMenuOpen: (open: boolean) => void;
  isCartDrawerOpen: boolean;
  setIsCartDrawerOpen: (open: boolean) => void;
  isCheckoutOpen: boolean;
  setIsCheckoutOpen: (open: boolean) => void;
  isPrintPreviewOpen: boolean;
  setIsPrintPreviewOpen: (open: boolean) => void;
  selectedPaymentMethod: PaymentMethod;
  setSelectedPaymentMethod: (method: PaymentMethod) => void;
  amountTenderedInput: string;
  setAmountTenderedInput: (val: string) => void;
  initiateCheckout: () => void;

  // Offline & Network status
  isOffline: boolean;
  setIsOffline: (offline: boolean) => void;
  pendingSyncCount: number;
  refreshPendingSyncCount: () => void;

  // Entities
  products: Product[];
  categories: Category[];
  customers: Customer[];
  sales: Sale[];

  // Persistent Cart
  cart: CartItem[];
  cartSummary: CartSummary;
  selectedCustomerId: number;
  setSelectedCustomerId: (id: number) => void;
  globalDiscountPercent: number;
  setGlobalDiscountPercent: (pct: number) => void;
  orderNote: string;
  setOrderNote: (note: string) => void;

  // Cart actions
  addToCart: (product: Product, quantity?: number) => void;
  updateQuantity: (productId: number, quantity: number) => void;
  incrementQuantity: (productId: number) => void;
  decrementQuantity: (productId: number) => void;
  setItemDiscount: (productId: number, discountPercent: number) => void;
  removeFromCart: (productId: number) => void;
  clearCart: (saveForUndo?: boolean) => void;

  // High-performance barcode scanner action
  scanAndAddToCart: (
    barcodeOrSku: string
  ) => Promise<{ success: boolean; product?: Product; error?: string; lookupTimeMs: number }>;

  // Products CRUD & Benchmark
  updateProduct: (product: Product) => void;
  addProduct: (product: Omit<Product, 'id'>) => Product;
  bulkAddBenchmarkProducts: (count: number) => Promise<{ count: number; timeMs: number }>;

  // Customers CRUD
  addCustomer: (cust: Omit<Customer, 'id'>) => Customer;

  // Checkout & Sales
  lastCompletedSale: Sale | null;
  setLastCompletedSale: (sale: Sale | null) => void;
  selectedInvoice: Sale | null;
  setSelectedInvoice: (sale: Sale | null) => void;
  completeSale: (
    paymentMethod: PaymentMethod,
    amountTendered?: number
  ) => { success: boolean; sale?: Sale; error?: string };

  // Analytics & Dashboard
  dailyStats: DailyRevenueStat[];
  todayStats: {
    revenue: number;
    salesCount: number;
    averageBasket: number;
    itemsSold: number;
    lowStockCount: number;
  };

  // Supabase sync
  supabaseConfig: SupabaseConfig;
  updateSupabaseConfig: (cfg: SupabaseConfig) => void;
  triggerSyncNow: () => Promise<{ success: boolean; pushedCount: number; pulledCount: number }>;

  // Thermal Printer settings
  printerSettings: ThermalPrinterSettings;
  updatePrinterSettings: (settings: ThermalPrinterSettings) => void;

  // Cart Undo & Safety
  canUndoClearCart: boolean;
  undoClearCart: () => void;

  resetDemoData: () => void;
}

const PosContext = createContext<PosContextType | undefined>(undefined);

const STORAGE_KEYS = {
  CART: 'pos_module_cart_v3',
  PRODUCTS: 'pos_module_products_v3',
  SALES: 'pos_module_sales_v3',
  CUSTOMERS: 'pos_module_customers_v3',
  CUSTOMER: 'pos_module_selected_customer_v3',
  NOTE: 'pos_module_order_note_v3',
  DISCOUNT: 'pos_module_global_discount_v3',
  SIMULATED_OFFLINE: 'pos_module_sim_offline_v3',
  PRINTER_SETTINGS: 'pos_module_printer_settings_v2',
};

export const PosProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [activeView, setActiveView] = useState<ViewType>('dashboard');
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);
  const [isCartDrawerOpen, setIsCartDrawerOpen] = useState(false);

  // Real-time offline detection
  const [isOffline, setIsOfflineState] = useState<boolean>(() => {
    if (typeof window !== 'undefined') {
      const sim = localStorage.getItem(STORAGE_KEYS.SIMULATED_OFFLINE);
      if (sim === 'true') return true;
      return !navigator.onLine;
    }
    return false;
  });

  const setIsOffline = (offline: boolean) => {
    setIsOfflineState(offline);
    try {
      localStorage.setItem(STORAGE_KEYS.SIMULATED_OFFLINE, String(offline));
    } catch {}
  };

  useEffect(() => {
    const handleOnline = () => {
      const sim = localStorage.getItem(STORAGE_KEYS.SIMULATED_OFFLINE);
      if (sim !== 'true') setIsOfflineState(false);
    };
    const handleOffline = () => setIsOfflineState(true);

    window.addEventListener('online', handleOnline);
    window.addEventListener('offline', handleOffline);
    return () => {
      window.removeEventListener('online', handleOnline);
      window.removeEventListener('offline', handleOffline);
    };
  }, []);

  const [pendingSyncCount, setPendingSyncCount] = useState<number>(0);
  const refreshPendingSyncCount = useCallback(async () => {
    const count = await ultraLocalDb.getPendingSyncCount();
    setPendingSyncCount(count);
  }, []);

  useEffect(() => {
    refreshPendingSyncCount();
  }, [refreshPendingSyncCount]);

  // Products
  const [products, setProducts] = useState<Product[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.PRODUCTS);
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.warn('Storage read failed for products:', e);
    }
    return INITIAL_PRODUCTS;
  });

  // Sync products into ultra-fast IndexedDB and in-memory hash index
  useEffect(() => {
    ultraLocalDb.loadMemoryCache(products);
    ultraLocalDb.bulkPutProducts(products).catch(() => {});
  }, [products]);

  // Categories
  const [categories] = useState<Category[]>(INITIAL_CATEGORIES);

  // Customers
  const [customers, setCustomers] = useState<Customer[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.CUSTOMERS);
      if (saved) return JSON.parse(saved);
    } catch {}
    return INITIAL_CUSTOMERS;
  });

  // Sales
  const [sales, setSales] = useState<Sale[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.SALES);
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.warn('Storage read failed for sales:', e);
    }
    return generateHistoricSales();
  });

  // Cart
  const [cart, setCart] = useState<CartItem[]>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.CART);
      if (saved) return JSON.parse(saved);
    } catch (e) {
      console.warn('Storage read failed for cart:', e);
    }
    return [];
  });

  const [selectedCustomerId, setSelectedCustomerId] = useState<number>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.CUSTOMER);
      return saved ? Number(saved) : 1;
    } catch {
      return 1;
    }
  });

  const [globalDiscountPercent, setGlobalDiscountPercent] = useState<number>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.DISCOUNT);
      return saved ? Number(saved) : 0;
    } catch {
      return 0;
    }
  });

  const [orderNote, setOrderNote] = useState<string>(() => {
    try {
      return localStorage.getItem(STORAGE_KEYS.NOTE) || '';
    } catch {
      return '';
    }
  });

  const [lastCompletedSale, setLastCompletedSale] = useState<Sale | null>(null);
  const [selectedInvoice, setSelectedInvoice] = useState<Sale | null>(null);

  // Global Checkout & 80mm Print Preview state
  const [isCheckoutOpen, setIsCheckoutOpen] = useState(false);
  const [isPrintPreviewOpen, setIsPrintPreviewOpen] = useState(false);
  const [selectedPaymentMethod, setSelectedPaymentMethod] = useState<PaymentMethod>('CASH');
  const [amountTenderedInput, setAmountTenderedInput] = useState<string>('');

  // Supabase Config state
  const [supabaseConfig, setSupabaseConfigState] = useState<SupabaseConfig>(() =>
    supabaseSyncService.getConfig()
  );

  const updateSupabaseConfig = (cfg: SupabaseConfig) => {
    setSupabaseConfigState(cfg);
    supabaseSyncService.saveConfig(cfg);
  };

  const triggerSyncNow = async () => {
    const res = await supabaseSyncService.triggerSync(products, sales);
    await refreshPendingSyncCount();
    setSupabaseConfigState(supabaseSyncService.getConfig());
    return res;
  };

  // Thermal Printer Settings state
  const [printerSettings, setPrinterSettings] = useState<ThermalPrinterSettings>(() => {
    try {
      const saved = localStorage.getItem(STORAGE_KEYS.PRINTER_SETTINGS);
      if (saved) {
        return { ...DEFAULT_PRINTER_SETTINGS, ...JSON.parse(saved) };
      }
    } catch {}
    return DEFAULT_PRINTER_SETTINGS;
  });

  const updatePrinterSettings = (newSettings: ThermalPrinterSettings) => {
    setPrinterSettings(newSettings);
    try {
      localStorage.setItem(STORAGE_KEYS.PRINTER_SETTINGS, JSON.stringify(newSettings));
    } catch {}
  };

  // Cart Undo State & Recovery
  const [previousCart, setPreviousCart] = useState<CartItem[] | null>(null);
  const [canUndoClearCart, setCanUndoClearCart] = useState<boolean>(false);

  const undoClearCart = () => {
    if (previousCart && previousCart.length > 0) {
      setCart(previousCart);
      setPreviousCart(null);
      setCanUndoClearCart(false);
      posSounds.playCartAdd();
    }
  };

  // LocalStorage sync
  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.CART, JSON.stringify(cart));
    } catch {}
  }, [cart]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.PRODUCTS, JSON.stringify(products));
    } catch {}
  }, [products]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.SALES, JSON.stringify(sales));
    } catch {}
  }, [sales]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.CUSTOMERS, JSON.stringify(customers));
    } catch {}
  }, [customers]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.CUSTOMER, String(selectedCustomerId));
    } catch {}
  }, [selectedCustomerId]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.DISCOUNT, String(globalDiscountPercent));
    } catch {}
  }, [globalDiscountPercent]);

  useEffect(() => {
    try {
      localStorage.setItem(STORAGE_KEYS.NOTE, orderNote);
    } catch {}
  }, [orderNote]);

  // Cart actions
  const addToCart = (product: Product, quantity = 1) => {
    setCart((prev) => {
      const existingIdx = prev.findIndex((item) => item.product.id === product.id);
      if (existingIdx > -1) {
        const next = [...prev];
        next[existingIdx] = {
          ...next[existingIdx],
          product,
          quantity: next[existingIdx].quantity + quantity,
        };
        return next;
      }
      return [
        ...prev,
        {
          product,
          quantity: Math.max(1, quantity),
          unitPrice: product.price,
          discountPercent: 0,
        },
      ];
    });
  };

  // High-performance barcode scanner action
  const scanAndAddToCart = async (
    barcodeOrSku: string
  ): Promise<{ success: boolean; product?: Product; error?: string; lookupTimeMs: number }> => {
    const { product, lookupTimeMs } = await ultraLocalDb.lookupByBarcodeOrSku(barcodeOrSku);

    if (!product) {
      posSounds.playScanError();
      return {
        success: false,
        error: `Code "${barcodeOrSku}" introuvable`,
        lookupTimeMs,
      };
    }

    if (product.stock <= 0) {
      posSounds.playScanError();
      return {
        success: false,
        product,
        error: `Article "${product.name}" en rupture de stock!`,
        lookupTimeMs,
      };
    }

    // Success sound and instant add
    posSounds.playScanSuccess();
    addToCart(product, 1);

    return {
      success: true,
      product,
      lookupTimeMs,
    };
  };

  const updateQuantity = (productId: number, quantity: number) => {
    if (quantity <= 0) {
      removeFromCart(productId);
      return;
    }
    setCart((prev) =>
      prev.map((it) => (it.product.id === productId ? { ...it, quantity: Math.floor(quantity) } : it))
    );
  };

  const incrementQuantity = (productId: number) => {
    setCart((prev) =>
      prev.map((it) => (it.product.id === productId ? { ...it, quantity: it.quantity + 1 } : it))
    );
  };

  const decrementQuantity = (productId: number) => {
    setCart((prev) =>
      prev
        .map((it) => (it.product.id === productId ? { ...it, quantity: it.quantity - 1 } : it))
        .filter((it) => it.quantity > 0)
    );
  };

  const setItemDiscount = (productId: number, discountPercent: number) => {
    const clamped = Math.min(100, Math.max(0, discountPercent));
    setCart((prev) =>
      prev.map((it) => (it.product.id === productId ? { ...it, discountPercent: clamped } : it))
    );
  };

  const removeFromCart = (productId: number) => {
    setCart((prev) => prev.filter((it) => it.product.id !== productId));
  };

  const clearCart = (saveForUndo = true) => {
    if (saveForUndo && cart.length > 0) {
      setPreviousCart([...cart]);
      setCanUndoClearCart(true);
      setTimeout(() => {
        setCanUndoClearCart(false);
      }, 6000);
    }
    setCart([]);
    setGlobalDiscountPercent(0);
    setOrderNote('');
  };

  // Real-time calculation of totals
  const cartSummary: CartSummary = useMemo(() => {
    let subtotalHT = 0;
    let totalTax = 0;
    let baseTTC = 0;
    let totalItems = 0;

    cart.forEach((item) => {
      totalItems += item.quantity;
      const lineOriginal = item.unitPrice * item.quantity;
      const lineDisc = lineOriginal * (item.discountPercent / 100);
      const lineNet = lineOriginal - lineDisc;

      const lineHT = lineNet / (1 + item.product.taxRate);
      const lineTVA = lineNet - lineHT;

      baseTTC += lineNet;
      subtotalHT += lineHT;
      totalTax += lineTVA;
    });

    const globalDiscountAmount = baseTTC * (globalDiscountPercent / 100);
    const finalTTC = Math.max(0, baseTTC - globalDiscountAmount);

    return {
      subtotalHT: Math.round(subtotalHT * 100) / 100,
      totalTax: Math.round(totalTax * 100) / 100,
      discountAmount: Math.round(globalDiscountAmount * 100) / 100,
      totalTTC: Math.round(finalTTC * 100) / 100,
      totalItems,
      uniqueCount: cart.length,
    };
  }, [cart, globalDiscountPercent]);

  // Products CRUD
  const updateProduct = (updated: Product) => {
    setProducts((prev) => prev.map((p) => (p.id === updated.id ? updated : p)));
    setCart((prev) =>
      prev.map((it) =>
        it.product.id === updated.id ? { ...it, product: updated, unitPrice: updated.price } : it
      )
    );
  };

  const addProduct = (newProdData: Omit<Product, 'id'>): Product => {
    const nextId = Math.max(...products.map((p) => p.id), 0) + 1;
    const newProduct: Product = { ...newProdData, id: nextId };
    setProducts((prev) => [newProduct, ...prev]);
    return newProduct;
  };

  // Generate benchmark products to test millions-capability of IndexedDB
  const bulkAddBenchmarkProducts = async (count: number) => {
    const startId = Math.max(...products.map((p) => p.id), 0) + 1;
    const generated: Product[] = [];
    const catIds = [1, 2, 3, 4, 5, 6];

    for (let i = 0; i < count; i++) {
      const id = startId + i;
      const sku = `BENCH-${id.toString().padStart(6, '0')}`;
      const barcode = `613${id.toString().padStart(9, '0')}`;
      const catId = catIds[i % catIds.length];
      const price = 50 + (i % 500) * 10;
      const costPrice = Math.round(price * 0.7);

      generated.push({
        id,
        sku,
        name: `Article Test High-Performance #${id}`,
        categoryId: catId,
        price,
        costPrice,
        stock: 50 + (i % 100),
        taxRate: 0.19,
        lowStockThreshold: 10,
        barcode,
        isActive: true,
      });
    }

    const { timeMs } = await ultraLocalDb.bulkPutProducts([...products, ...generated]);
    setProducts((prev) => [...prev, ...generated]);
    return { count, timeMs };
  };

  const addCustomer = (newCustData: Omit<Customer, 'id'>): Customer => {
    const nextId = Math.max(...customers.map((c) => c.id), 0) + 1;
    const newCust: Customer = { ...newCustData, id: nextId, balanceDue: 0 };
    setCustomers((prev) => [newCust, ...prev]);
    return newCust;
  };

  // Initiate transaction checkout
  const initiateCheckout = useCallback(() => {
    if (cart.length === 0) {
      posSounds.playScanError();
      return;
    }
    setAmountTenderedInput(cartSummary.totalTTC.toString());
    setIsCheckoutOpen(true);
  }, [cart.length, cartSummary.totalTTC]);

  // Complete checkout
  const completeSale = (
    paymentMethod: PaymentMethod,
    amountTendered?: number
  ): { success: boolean; sale?: Sale; error?: string } => {
    if (cart.length === 0) {
      return { success: false, error: 'Le panier est vide.' };
    }

    const saleItems: SaleItem[] = cart.map((item) => {
      const lineNet = item.unitPrice * item.quantity * (1 - item.discountPercent / 100);
      const lineHT = lineNet / (1 + item.product.taxRate);

      return {
        productId: item.product.id,
        productName: item.product.name,
        sku: item.product.sku,
        quantity: item.quantity,
        unitPrice: item.unitPrice,
        taxRate: item.product.taxRate,
        discountPercent: item.discountPercent,
        totalHT: Math.round(lineHT * 100) / 100,
        totalTTC: Math.round(lineNet * 100) / 100,
      };
    });

    const now = new Date();
    const customer = customers.find((c) => c.id === selectedCustomerId);
    const saleId = Math.max(...sales.map((s) => s.id), 0) + 1;
    const saleNumber = `INV-${now.getFullYear()}${(now.getMonth() + 1)
      .toString()
      .padStart(2, '0')}-${saleId.toString().padStart(4, '0')}`;

    const tendered = amountTendered ?? cartSummary.totalTTC;
    const changeGiven = Math.max(0, tendered - cartSummary.totalTTC);

    const newSale: Sale = {
      id: saleId,
      saleNumber,
      customerId: selectedCustomerId,
      customerName: customer ? customer.name : 'Client Comptoir',
      items: saleItems,
      subtotalHT: cartSummary.subtotalHT,
      taxTotal: cartSummary.totalTax,
      discountTotal: cartSummary.discountAmount,
      totalTTC: cartSummary.totalTTC,
      paymentMethod,
      amountTendered: tendered,
      changeGiven,
      status: 'COMPLETED',
      createdAt: now.toISOString(),
      notes: orderNote || undefined,
    };

    // Deduct stock
    setProducts((prev) =>
      prev.map((prod) => {
        const cartItem = cart.find((ci) => ci.product.id === prod.id);
        if (cartItem) {
          return {
            ...prod,
            stock: Math.max(0, prod.stock - cartItem.quantity),
          };
        }
        return prod;
      })
    );

    // Save sale to local state and IndexedDB outbox
    setSales((prev) => [newSale, ...prev]);
    setLastCompletedSale(newSale);
    ultraLocalDb.queueSaleForSync(newSale).then(() => refreshPendingSyncCount());

    // Close checkout and preview modals
    setIsCheckoutOpen(false);
    setIsPrintPreviewOpen(false);

    // Register chime
    posSounds.playPaymentSuccess();

    clearCart();
    return { success: true, sale: newSale };
  };

  // Recharts Daily Stats
  const dailyStats: DailyRevenueStat[] = useMemo(() => {
    const map = new Map<string, { revenue: number; cost: number; orders: number; unitsSold: number }>();
    const now = new Date();

    for (let i = 13; i >= 0; i--) {
      const d = new Date(now);
      d.setDate(d.getDate() - i);
      const key = d.toISOString().split('T')[0];
      map.set(key, { revenue: 0, cost: 0, orders: 0, unitsSold: 0 });
    }

    sales.forEach((s) => {
      const key = s.createdAt.split('T')[0];
      if (map.has(key)) {
        const cur = map.get(key)!;
        cur.revenue += s.totalTTC;
        cur.orders += 1;
        cur.unitsSold += s.items.reduce((sum, it) => sum + it.quantity, 0);
        cur.cost += s.totalTTC * 0.65;
      }
    });

    const result: DailyRevenueStat[] = [];
    const keys = Array.from(map.keys()).sort();

    keys.forEach((key) => {
      const val = map.get(key)!;
      const [year, month, day] = key.split('-');
      const d = new Date(Number(year), Number(month) - 1, Number(day));
      const formattedDate = d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short' });

      result.push({
        date: key,
        formattedDate,
        revenue: Math.round(val.revenue),
        cost: Math.round(val.cost),
        profit: Math.round(val.revenue - val.cost),
        orders: val.orders,
        unitsSold: val.unitsSold,
      });
    });

    return result;
  }, [sales]);

  // Today KPI
  const todayStats = useMemo(() => {
    const todayStr = new Date().toISOString().split('T')[0];
    const todaySales = sales.filter((s) => s.createdAt.startsWith(todayStr));

    const revenue = todaySales.reduce((sum, s) => sum + s.totalTTC, 0);
    const salesCount = todaySales.length;
    const averageBasket = salesCount > 0 ? revenue / salesCount : 0;
    const itemsSold = todaySales.reduce(
      (sum, s) => sum + s.items.reduce((iSum, it) => iSum + it.quantity, 0),
      0
    );
    const lowStockCount = products.filter((p) => p.stock <= p.lowStockThreshold).length;

    return {
      revenue: Math.round(revenue),
      salesCount,
      averageBasket: Math.round(averageBasket),
      itemsSold,
      lowStockCount,
    };
  }, [sales, products]);

  const resetDemoData = () => {
    localStorage.removeItem(STORAGE_KEYS.CART);
    localStorage.removeItem(STORAGE_KEYS.PRODUCTS);
    localStorage.removeItem(STORAGE_KEYS.SALES);
    localStorage.removeItem(STORAGE_KEYS.CUSTOMERS);
    localStorage.removeItem(STORAGE_KEYS.CUSTOMER);
    localStorage.removeItem(STORAGE_KEYS.NOTE);
    localStorage.removeItem(STORAGE_KEYS.DISCOUNT);
    setProducts(INITIAL_PRODUCTS);
    setSales(generateHistoricSales());
    setCustomers(INITIAL_CUSTOMERS);
    setCart([]);
    setSelectedCustomerId(1);
    setGlobalDiscountPercent(0);
    setOrderNote('');
    refreshPendingSyncCount();
  };

  return (
    <PosContext.Provider
      value={{
        activeView,
        setActiveView,
        isMobileMenuOpen,
        setIsMobileMenuOpen,
        isCartDrawerOpen,
        setIsCartDrawerOpen,
        isOffline,
        setIsOffline,
        pendingSyncCount,
        refreshPendingSyncCount,
        products,
        categories,
        customers,
        sales,
        cart,
        cartSummary,
        selectedCustomerId,
        setSelectedCustomerId,
        globalDiscountPercent,
        setGlobalDiscountPercent,
        orderNote,
        setOrderNote,
        addToCart,
        updateQuantity,
        incrementQuantity,
        decrementQuantity,
        setItemDiscount,
        removeFromCart,
        clearCart,
        scanAndAddToCart,
        updateProduct,
        addProduct,
        bulkAddBenchmarkProducts,
        addCustomer,
        lastCompletedSale,
        setLastCompletedSale,
        selectedInvoice,
        setSelectedInvoice,
        isCheckoutOpen,
        setIsCheckoutOpen,
        isPrintPreviewOpen,
        setIsPrintPreviewOpen,
        selectedPaymentMethod,
        setSelectedPaymentMethod,
        amountTenderedInput,
        setAmountTenderedInput,
        initiateCheckout,
        completeSale,
        dailyStats,
        todayStats,
        supabaseConfig,
        updateSupabaseConfig,
        triggerSyncNow,
        printerSettings,
        updatePrinterSettings,
        canUndoClearCart,
        undoClearCart,
        resetDemoData,
      }}
    >
      {children}
    </PosContext.Provider>
  );
};

export const usePos = () => {
  const context = useContext(PosContext);
  if (!context) throw new Error('usePos must be used within PosProvider');
  return context;
};
