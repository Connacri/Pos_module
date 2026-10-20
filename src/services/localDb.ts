import { Product, Sale } from '../types';

const DB_NAME = 'pos_ultra_db';
const DB_VERSION = 1;

class UltraLocalDatabase {
  private dbPromise: Promise<IDBDatabase> | null = null;
  // In-memory dual-layer index for ultra sub-millisecond barcode lookup
  private memoryBarcodeMap: Map<string, Product> = new Map();
  private memorySkuMap: Map<string, Product> = new Map();
  public isReady: boolean = false;

  constructor() {
    if (typeof window !== 'undefined') {
      this.init();
    }
  }

  private init(): Promise<IDBDatabase> {
    if (this.dbPromise) return this.dbPromise;

    this.dbPromise = new Promise((resolve, reject) => {
      const request = indexedDB.open(DB_NAME, DB_VERSION);

      request.onupgradeneeded = (event) => {
        const db = (event.target as IDBOpenDBRequest).result;

        // Products Store
        if (!db.objectStoreNames.contains('products')) {
          const productStore = db.createObjectStore('products', { keyPath: 'id' });
          productStore.createIndex('barcode', 'barcode', { unique: false });
          productStore.createIndex('sku', 'sku', { unique: true });
          productStore.createIndex('categoryId', 'categoryId', { unique: false });
          productStore.createIndex('stock', 'stock', { unique: false });
          productStore.createIndex('price', 'price', { unique: false });
        }

        // Sales Store
        if (!db.objectStoreNames.contains('sales')) {
          const salesStore = db.createObjectStore('sales', { keyPath: 'id' });
          salesStore.createIndex('saleNumber', 'saleNumber', { unique: true });
          salesStore.createIndex('createdAt', 'createdAt', { unique: false });
          salesStore.createIndex('status', 'status', { unique: false });
        }

        // Supabase Sync Outbox Queue
        if (!db.objectStoreNames.contains('syncQueue')) {
          const queueStore = db.createObjectStore('syncQueue', { keyPath: 'queueId', autoIncrement: true });
          queueStore.createIndex('entityType', 'entityType', { unique: false });
          queueStore.createIndex('status', 'status', { unique: false });
        }
      };

      request.onsuccess = () => {
        this.isReady = true;
        resolve(request.result);
      };

      request.onerror = () => {
        reject(request.error);
      };
    });

    return this.dbPromise;
  }

  // Populate in-memory fast index from an array of products
  loadMemoryCache(products: Product[]) {
    this.memoryBarcodeMap.clear();
    this.memorySkuMap.clear();
    for (let i = 0; i < products.length; i++) {
      const p = products[i];
      if (p.barcode) this.memoryBarcodeMap.set(p.barcode, p);
      if (p.sku) this.memorySkuMap.set(p.sku.toLowerCase(), p);
    }
  }

  // Ultra-fast sub-millisecond barcode lookup (O(1))
  async lookupByBarcodeOrSku(code: string): Promise<{ product: Product | null; lookupTimeMs: number }> {
    const start = performance.now();
    const cleanCode = code.trim();
    const lowerCode = cleanCode.toLowerCase();

    // 1. Check in-memory index (< 0.05ms)
    let prod = this.memoryBarcodeMap.get(cleanCode) || this.memorySkuMap.get(lowerCode) || null;

    // 2. If not in memory, query IndexedDB B-Tree index
    if (!prod && this.isReady) {
      try {
        const db = await this.init();
        const tx = db.transaction('products', 'readonly');
        const store = tx.objectStore('products');
        const barcodeIndex = store.index('barcode');

        const dbResult = await new Promise<Product | null>((resolve) => {
          const req = barcodeIndex.get(cleanCode);
          req.onsuccess = () => resolve(req.result || null);
          req.onerror = () => resolve(null);
        });

        if (dbResult) {
          prod = dbResult;
          this.memoryBarcodeMap.set(cleanCode, prod);
        }
      } catch (e) {
        console.warn('IndexedDB lookup error:', e);
      }
    }

    const elapsed = Math.round((performance.now() - start) * 100) / 100;
    return { product: prod, lookupTimeMs: elapsed };
  }

  // High-performance batch insert for tens of thousands of items in a single readwrite transaction
  async bulkPutProducts(products: Product[]): Promise<{ count: number; timeMs: number }> {
    const start = performance.now();
    const db = await this.init();

    return new Promise((resolve, reject) => {
      const tx = db.transaction('products', 'readwrite');
      const store = tx.objectStore('products');

      for (let i = 0; i < products.length; i++) {
        store.put(products[i]);
      }

      tx.oncomplete = () => {
        this.loadMemoryCache(products);
        const elapsed = Math.round(performance.now() - start);
        resolve({ count: products.length, timeMs: elapsed });
      };

      tx.onerror = () => reject(tx.error);
    });
  }

  // Count items stored in IndexedDB
  async countProducts(): Promise<number> {
    const db = await this.init();
    return new Promise((resolve) => {
      const tx = db.transaction('products', 'readonly');
      const store = tx.objectStore('products');
      const req = store.count();
      req.onsuccess = () => resolve(req.result);
      req.onerror = () => resolve(0);
    });
  }

  // Queue an offline sale for cloud sync
  async queueSaleForSync(sale: Sale): Promise<void> {
    try {
      const db = await this.init();
      const tx = db.transaction(['sales', 'syncQueue'], 'readwrite');
      tx.objectStore('sales').put(sale);
      tx.objectStore('syncQueue').add({
        entityType: 'sale',
        entityId: sale.id,
        payload: sale,
        status: 'PENDING',
        createdAt: new Date().toISOString(),
      });
    } catch (e) {
      console.warn('Failed to queue sale to IndexedDB:', e);
    }
  }

  // Get count of pending sync items
  async getPendingSyncCount(): Promise<number> {
    try {
      const db = await this.init();
      return new Promise((resolve) => {
        const tx = db.transaction('syncQueue', 'readonly');
        const req = tx.objectStore('syncQueue').count();
        req.onsuccess = () => resolve(req.result);
        req.onerror = () => resolve(0);
      });
    } catch {
      return 0;
    }
  }

  // Clear sync queue after successful Supabase upload
  async clearSyncQueue(): Promise<void> {
    try {
      const db = await this.init();
      const tx = db.transaction('syncQueue', 'readwrite');
      tx.objectStore('syncQueue').clear();
    } catch {}
  }
}

export const ultraLocalDb = new UltraLocalDatabase();
