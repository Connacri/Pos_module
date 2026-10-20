import React, { useState, useEffect, useRef, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Product } from '../../types';
import { CartPanel } from './CartPanel';
import {
  Search,
  Barcode,
  Layers,
  Plus,
  Check,
  Package,
  AlertCircle,
  Filter,
  ShoppingCart,
  X,
  Volume2,
  Zap,
  Sparkles,
  Keyboard,
  HelpCircle,
  ArrowRight,
} from 'lucide-react';

export const PosRegisterView: React.FC = () => {
  const {
    products,
    categories,
    cart,
    addToCart,
    clearCart,
    initiateCheckout,
    isCheckoutOpen,
    setIsCheckoutOpen,
    isPrintPreviewOpen,
    setIsPrintPreviewOpen,
    scanAndAddToCart,
    cartSummary,
    isCartDrawerOpen,
    setIsCartDrawerOpen,
    isOffline,
  } = usePos();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCatId, setSelectedCatId] = useState<number | 'ALL'>('ALL');
  const [barcodeInput, setBarcodeInput] = useState('');
  const [scanFeedback, setScanFeedback] = useState<{
    message: string;
    type: 'success' | 'error' | 'warning';
    latencyMs?: number;
  } | null>(null);
  const [shortcutFeedback, setShortcutFeedback] = useState<{
    key: string;
    label: string;
    type?: 'info' | 'success' | 'warning';
  } | null>(null);
  const [showShortcutGuideModal, setShowShortcutGuideModal] = useState(false);
  const [lastScannedId, setLastScannedId] = useState<number | null>(null);
  const [stockWarningToast, setStockWarningToast] = useState<{
    productName: string;
    stock: number;
    threshold: number;
  } | null>(null);

  const barcodeInputRef = useRef<HTMLInputElement>(null);
  const searchInputRef = useRef<HTMLInputElement>(null);

  // Helper to trigger low stock warning toast
  const checkLowStockAlert = (product: Product) => {
    if (product.stock > 0 && product.stock <= product.lowStockThreshold) {
      setStockWarningToast({
        productName: product.name,
        stock: product.stock,
        threshold: product.lowStockThreshold,
      });
      setTimeout(() => setStockWarningToast(null), 4500);
    }
  };

  // Keyboard shortcut mapping system (F1, F2, Esc) & Barcode Scanner Buffer
  useEffect(() => {
    let buffer = '';
    let lastKeyTime = Date.now();

    const handleKeyDown = (e: KeyboardEvent) => {
      // 1. F1: Focus the product search input
      if (e.key === 'F1') {
        e.preventDefault();
        if (searchInputRef.current) {
          searchInputRef.current.focus();
          searchInputRef.current.select();
        }
        setShortcutFeedback({
          key: 'F1',
          label: 'Recherche produit ciblée',
          type: 'info',
        });
        setTimeout(() => setShortcutFeedback(null), 2200);
        return;
      }

      // 2. F2: Initiate transaction (Open checkout modal)
      if (e.key === 'F2') {
        e.preventDefault();
        if (cart.length > 0) {
          initiateCheckout();
          setShortcutFeedback({
            key: 'F2',
            label: 'Transaction initiée • Encaissement',
            type: 'success',
          });
        } else {
          setShortcutFeedback({
            key: 'F2',
            label: 'Panier vide : ajoutez des articles avant d\'encaisser',
            type: 'warning',
          });
        }
        setTimeout(() => setShortcutFeedback(null), 2500);
        return;
      }

      // 3. Esc (Escape): Clear current cart or dismiss modals
      if (e.key === 'Escape') {
        if (isPrintPreviewOpen) {
          e.preventDefault();
          setIsPrintPreviewOpen(false);
          return;
        }
        if (isCheckoutOpen) {
          e.preventDefault();
          setIsCheckoutOpen(false);
          return;
        }
        if (showShortcutGuideModal) {
          e.preventDefault();
          setShowShortcutGuideModal(false);
          return;
        }
        if (isCartDrawerOpen) {
          e.preventDefault();
          setIsCartDrawerOpen(false);
          return;
        }
        if (cart.length > 0) {
          e.preventDefault();
          clearCart();
          setShortcutFeedback({
            key: 'Échap',
            label: 'Panier de vente vidé avec succès',
            type: 'warning',
          });
          setTimeout(() => setShortcutFeedback(null), 2200);
          return;
        }
      }

      // Hardware Barcode Scanner Buffer (USB / Bluetooth HID)
      const target = e.target as HTMLElement;
      const isInput =
        target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable;

      // Allow barcode input box to receive characters without hijacking other inputs
      if (isInput && target !== barcodeInputRef.current) {
        return;
      }

      const currentTime = Date.now();
      const timeDiff = currentTime - lastKeyTime;
      lastKeyTime = currentTime;

      if (e.key === 'Enter') {
        if (buffer.length >= 3) {
          e.preventDefault();
          executeScan(buffer);
          buffer = '';
        }
      } else if (e.key.length === 1) {
        // Most barcode scanners type characters in < 45ms intervals
        if (timeDiff > 80 && buffer.length > 0) {
          buffer = ''; // Reset buffer if slow human typing outside input
        }
        buffer += e.key;
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [
    cart.length,
    initiateCheckout,
    clearCart,
    isPrintPreviewOpen,
    setIsPrintPreviewOpen,
    isCheckoutOpen,
    setIsCheckoutOpen,
    isCartDrawerOpen,
    setIsCartDrawerOpen,
    showShortcutGuideModal,
  ]);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Map cart quantities
  const cartQtyMap = useMemo(() => {
    const map = new Map<number, number>();
    cart.forEach((it) => map.set(it.product.id, it.quantity));
    return map;
  }, [cart]);

  // Execute fast EAN barcode scan
  const executeScan = async (code: string) => {
    if (!code.trim()) return;
    const cleanCode = code.trim();

    const res = await scanAndAddToCart(cleanCode);

    if (res.success && res.product) {
      setLastScannedId(res.product.id);
      setTimeout(() => setLastScannedId(null), 1500);
      checkLowStockAlert(res.product);
      setScanFeedback({
        message: `Ajouté: ${res.product.name} (Code: ${cleanCode})`,
        type: 'success',
        latencyMs: res.lookupTimeMs,
      });
    } else {
      setScanFeedback({
        message: res.error || `Code "${cleanCode}" introuvable`,
        type: 'error',
        latencyMs: res.lookupTimeMs,
      });
    }

    setBarcodeInput('');
    setTimeout(() => setScanFeedback(null), 3500);
  };

  const handleFormSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    executeScan(barcodeInput);
  };

  // Filter products for POS quick-picker
  const filteredProducts = useMemo(() => {
    return products.filter((p) => {
      const matchCat = selectedCatId === 'ALL' || p.categoryId === selectedCatId;
      const q = searchQuery.toLowerCase().trim();
      const matchSearch =
        !q ||
        p.name.toLowerCase().includes(q) ||
        p.sku.toLowerCase().includes(q) ||
        p.barcode.includes(q);

      return matchCat && matchSearch && p.isActive;
    });
  }, [products, selectedCatId, searchQuery]);

  return (
    <div className="flex flex-col lg:flex-row items-stretch gap-6 h-[calc(100vh-140px)] min-h-[620px]">
      {/* Left Column: Product Selection & Barcode scanner */}
      <div className="flex-1 flex flex-col bg-white/80 backdrop-blur-xl rounded-3xl border border-white shadow-xs p-4 sm:p-5 overflow-hidden">
        {/* Top Header & Barcode scanner tool */}
        <div className="space-y-3 pb-3 border-b border-slate-100">
          {/* Barcode scanner form with latency indicator */}
          <form onSubmit={handleFormSubmit} className="flex items-center gap-2">
            <div className="relative flex-1">
              <Barcode className="w-5 h-5 text-indigo-600 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                ref={barcodeInputRef}
                type="text"
                value={barcodeInput}
                onChange={(e) => setBarcodeInput(e.target.value)}
                placeholder="Scanner un code-barres EAN (ou tapez SKU / EAN et Entrée)..."
                className="w-full pl-11 pr-24 py-2.5 bg-indigo-50/60 border border-indigo-200/80 rounded-2xl text-xs sm:text-sm font-mono placeholder:font-sans placeholder:text-slate-400 focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
              />
              <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1">
                <span className="hidden sm:inline-flex items-center gap-1 text-[10px] font-bold text-indigo-700 bg-indigo-100/80 px-2 py-0.5 rounded-md">
                  <Zap className="w-3 h-3 text-indigo-600" />
                  Auto-Scan Actif
                </span>
              </div>
            </div>

            <button
              type="submit"
              className="touch-btn px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer shrink-0"
            >
              <Barcode className="w-4 h-4" />
              <span>Valider</span>
            </button>
          </form>

          {/* Quick Barcode Test Chips for Cashiers */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[11px]">
            <span className="text-slate-400 font-semibold shrink-0 flex items-center gap-1">
              <Sparkles className="w-3 h-3 text-amber-500" />
              Test rapide EAN :
            </span>
            <button
              type="button"
              onClick={() => executeScan('613000000001')}
              className="px-2.5 py-1 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 text-slate-700 hover:text-indigo-700 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
            >
              Coca-Cola (613000000001)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000004')}
              className="px-2.5 py-1 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 text-slate-700 hover:text-indigo-700 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
            >
              Huile Olive (613000000004)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000012')}
              className="px-2.5 py-1 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 text-slate-700 hover:text-indigo-700 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
            >
              Écouteurs BT (613000000012)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000013')}
              className="px-2.5 py-1 bg-white hover:bg-rose-50 border border-slate-200 hover:border-rose-300 text-slate-700 hover:text-rose-700 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
            >
              Pain Rupture (613000000013)
            </button>
          </div>

          {/* Barcode feedback banner */}
          {scanFeedback && (
            <div
              className={`p-3 rounded-2xl text-xs font-semibold flex items-center justify-between animate-in fade-in zoom-in-95 duration-150 ${
                scanFeedback.type === 'success'
                  ? 'bg-emerald-50 text-emerald-800 border border-emerald-200'
                  : 'bg-rose-50 text-rose-800 border border-rose-200'
              }`}
            >
              <div className="flex items-center gap-2">
                <Volume2 className="w-4 h-4 shrink-0" />
                <span>{scanFeedback.message}</span>
              </div>
              {scanFeedback.latencyMs !== undefined && (
                <span className="font-mono text-[10px] px-2 py-0.5 rounded-md bg-white/80 shadow-2xs">
                  ⚡ {scanFeedback.latencyMs} ms
                </span>
              )}
            </div>
          )}

          {/* Low Stock Threshold Warning Toast */}
          {stockWarningToast && (
            <div className="p-3 bg-amber-50 text-amber-900 border-2 border-amber-300 rounded-2xl text-xs font-bold flex items-center justify-between shadow-md animate-in slide-in-from-top-2 duration-200">
              <div className="flex items-center gap-2.5">
                <AlertCircle className="w-5 h-5 text-amber-600 shrink-0" />
                <div>
                  <div className="font-extrabold text-amber-950">
                    ⚠️ Attention : Stock Minimal Dépassé !
                  </div>
                  <div className="text-[11px] font-normal text-amber-800">
                    "{stockWarningToast.productName}" ne dispose plus que de{' '}
                    <strong className="font-bold underline">{stockWarningToast.stock} unité(s)</strong>{' '}
                    en stock (seuil minimal d'alerte : {stockWarningToast.threshold}).
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setStockWarningToast(null)}
                className="touch-btn p-1 text-amber-600 hover:text-amber-900 transition-colors"
                title="Ignorer l'alerte"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Search + Category chips */}
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Filtrer les articles par nom ou référence..."
                className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs text-slate-800 focus:outline-hidden"
              />
            </div>

            {/* Mobile View Cart Button */}
            <button
              type="button"
              onClick={() => setIsCartDrawerOpen(true)}
              className="lg:hidden touch-btn px-3 py-2 bg-indigo-600 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-xs cursor-pointer shrink-0"
            >
              <ShoppingCart className="w-4 h-4 text-emerald-300" />
              <span>Panier ({cartSummary.totalItems})</span>
            </button>
          </div>

          {/* Category Chips scroll */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs">
            <button
              type="button"
              onClick={() => setSelectedCatId('ALL')}
              className={`px-3 py-1.5 rounded-xl font-semibold transition-all whitespace-nowrap cursor-pointer ${
                selectedCatId === 'ALL'
                  ? 'bg-slate-900 text-white shadow-2xs'
                  : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
              }`}
            >
              Tous
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => setSelectedCatId(c.id)}
                className={`px-3 py-1.5 rounded-xl font-semibold transition-all whitespace-nowrap cursor-pointer ${
                  selectedCatId === c.id
                    ? 'bg-indigo-600 text-white shadow-2xs'
                    : 'bg-slate-100 text-slate-600 hover:bg-slate-200'
                }`}
              >
                {c.name}
              </button>
            ))}
          </div>
        </div>

        {/* Product Grid (Fast Touch-friendly tiles) */}
        <div className="flex-1 overflow-y-auto pt-3 pr-1">
          {filteredProducts.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center p-8 text-center text-slate-400">
              <Package className="w-10 h-10 mb-2 text-slate-300" />
              <p className="text-xs font-semibold">Aucun produit ne correspond</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3 xl:grid-cols-4 gap-3">
              {filteredProducts.map((p) => {
                const inCart = cartQtyMap.get(p.id) || 0;
                const isOutOfStock = p.stock <= 0;
                const isRecentlyScanned = lastScannedId === p.id;

                return (
                  <div
                    key={p.id}
                    onClick={() => {
                      if (!isOutOfStock) {
                        addToCart(p, 1);
                        checkLowStockAlert(p);
                      }
                    }}
                    className={`p-3 rounded-2xl border transition-all flex flex-col justify-between group cursor-pointer relative ${
                      isRecentlyScanned
                        ? 'ring-4 ring-indigo-500/40 border-indigo-500 scale-102 bg-indigo-50/50'
                        : isOutOfStock
                        ? 'bg-slate-50/70 border-slate-200 opacity-60 cursor-not-allowed'
                        : 'bg-white border-slate-200/80 hover:border-indigo-400 hover:shadow-md active:scale-98'
                    }`}
                  >
                    {/* Image / Thumbnail */}
                    <div className="aspect-4/3 rounded-xl bg-slate-100 overflow-hidden mb-2 relative">
                      {p.imageUrl ? (
                        <img
                          src={p.imageUrl}
                          alt={p.name}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-slate-300">
                          <Package className="w-8 h-8" />
                        </div>
                      )}

                      {/* Stock badge */}
                      <div className="absolute top-1.5 left-1.5">
                        {isOutOfStock ? (
                          <span className="bg-rose-600 text-white text-[9px] font-bold px-1.5 py-0.5 rounded-md">
                            Rupture
                          </span>
                        ) : p.stock <= p.lowStockThreshold ? (
                          <span className="bg-amber-500 text-white text-[9px] font-bold px-1.5 py-0.5 rounded-md">
                            Reste {p.stock}
                          </span>
                        ) : null}
                      </div>

                      {/* Cart badge on tile */}
                      {inCart > 0 && (
                        <div className="absolute top-1.5 right-1.5 bg-indigo-600 text-white text-[10px] font-black px-1.5 py-0.5 rounded-lg shadow-sm">
                          x{inCart}
                        </div>
                      )}
                    </div>

                    {/* Details */}
                    <div>
                      <h4 className="font-bold text-xs text-slate-800 line-clamp-1">
                        {p.name}
                      </h4>
                      <div className="text-[10px] text-slate-400 font-mono mt-0.5 flex items-center justify-between">
                        <span>{p.sku}</span>
                        <span className="text-[9px] text-slate-400">{p.barcode.slice(-4)}</span>
                      </div>
                    </div>

                    {/* Price and tap to add button */}
                    <div className="mt-2 pt-2 border-t border-slate-100 flex items-center justify-between">
                      <div className="font-extrabold text-xs text-indigo-600">
                        {formatMoney(p.price)}
                      </div>
                      <button
                        type="button"
                        disabled={isOutOfStock}
                        className="touch-btn w-7 h-7 rounded-xl bg-indigo-50 group-hover:bg-indigo-600 text-indigo-700 group-hover:text-white flex items-center justify-center transition-colors shadow-2xs"
                      >
                        <Plus className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Right Column (Desktop Persistent Cart Panel) */}
      <div className="hidden lg:flex w-[380px] shrink-0">
        <CartPanel />
      </div>

      {/* Mobile Cart Slide-over Drawer / Bottom Sheet */}
      {isCartDrawerOpen && (
        <div className="fixed inset-0 z-50 lg:hidden bg-slate-900/50 backdrop-blur-xs flex flex-col justify-end">
          <div className="bg-white rounded-t-3xl max-h-[92vh] h-[85vh] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200">
            <div className="p-3 bg-slate-100 border-b border-slate-200 flex items-center justify-between">
              <span className="w-10 h-1 bg-slate-300 rounded-full mx-auto block mb-1"></span>
              <button
                type="button"
                onClick={() => setIsCartDrawerOpen(false)}
                className="touch-btn p-1 text-slate-500 hover:text-slate-800 absolute right-3 top-2"
              >
                <X className="w-5 h-5" />
              </button>
            </div>
            <div className="flex-1 overflow-hidden">
              <CartPanel />
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
