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
            label: 'Panier de vente réinitialisé',
            type: 'warning',
          });
          setTimeout(() => setShortcutFeedback(null), 2200);
        }
        return;
      }

      // 4. Hardware Barcode Scanner Buffer interceptor
      const target = e.target as HTMLElement;
      const isInput =
        target.tagName === 'INPUT' ||
        target.tagName === 'TEXTAREA' ||
        target.isContentEditable;

      const currentTime = Date.now();
      const charDiff = currentTime - lastKeyTime;
      lastKeyTime = currentTime;

      if (e.key === 'Enter') {
        if (buffer.length >= 3 && charDiff < 100) {
          e.preventDefault();
          executeScan(buffer.trim());
          buffer = '';
        }
        return;
      }

      if (e.key.length === 1) {
        if (charDiff < 75) {
          buffer += e.key;
        } else {
          buffer = e.key;
        }
      }
    };

    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [
    cart,
    isCheckoutOpen,
    isPrintPreviewOpen,
    showShortcutGuideModal,
    isCartDrawerOpen,
    initiateCheckout,
    clearCart,
    setIsCheckoutOpen,
    setIsPrintPreviewOpen,
    setIsCartDrawerOpen,
  ]);

  // Map cart quantities by productId
  const cartQtyMap = useMemo(() => {
    const map = new Map<number, number>();
    cart.forEach((it) => map.set(it.product.id, it.quantity));
    return map;
  }, [cart]);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  const executeScan = async (code: string) => {
    if (!code.trim()) return;

    const res = await scanAndAddToCart(code);

    if (res.success && res.product) {
      setLastScannedId(res.product.id);
      checkLowStockAlert(res.product);

      setScanFeedback({
        message: `Ajouté : ${res.product.name} (${formatMoney(res.product.price)})`,
        type: 'success',
        latencyMs: res.lookupTimeMs,
      });

      setTimeout(() => setLastScannedId(null), 1400);
    } else {
      setScanFeedback({
        message: res.error || 'Article non trouvé dans le catalogue',
        type: 'error',
        latencyMs: res.lookupTimeMs,
      });
    }

    setBarcodeInput('');
    setTimeout(() => setScanFeedback(null), 3000);
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
      <div className="flex-1 flex flex-col sherwood-panel p-4 sm:p-5 overflow-hidden">
        {/* Top Header & Barcode scanner tool */}
        <div className="space-y-3 pb-3 border-b border-[#e7ddca]">
          {/* Barcode scanner form with latency indicator */}
          <form onSubmit={handleFormSubmit} className="flex items-center gap-2">
            <div className="relative flex-1">
              <Barcode className="w-5 h-5 text-[#234931] absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                ref={barcodeInputRef}
                type="text"
                value={barcodeInput}
                onChange={(e) => setBarcodeInput(e.target.value)}
                placeholder="Scanner un code-barres EAN (ou tapez SKU / EAN et Entrée)..."
                className="w-full pl-11 pr-24 py-2.5 bg-[#f7f2e7] border border-[#d8cdba] rounded-2xl text-xs sm:text-sm font-mono placeholder:font-sans placeholder:text-[#877a6b] focus:outline-hidden focus:border-[#234931] focus:ring-2 focus:ring-[#234931]/15"
              />
              <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1">
                <span className="hidden sm:inline-flex items-center gap-1 text-[10px] font-bold text-[#234931] bg-[#eaf2e8] px-2 py-0.5 rounded-md border border-[#cbe0cb]">
                  <Zap className="w-3 h-3 text-[#234931]" />
                  Auto-Scan Actif
                </span>
              </div>
            </div>

            <button
              type="submit"
              className="touch-btn px-4 py-2.5 sherwood-btn-forest text-xs font-bold flex items-center gap-1.5 shrink-0"
            >
              <Barcode className="w-4 h-4" />
              <span>Valider</span>
            </button>
          </form>

          {/* Quick Barcode Test Chips */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-[11px]">
            <span className="text-[#877a6b] font-bold shrink-0 flex items-center gap-1">
              <Sparkles className="w-3 h-3 text-[#d97706]" />
              Test rapide EAN :
            </span>
            <button
              type="button"
              onClick={() => executeScan('613000000001')}
              className="px-2.5 py-1 bg-[#fdfbf7] hover:bg-[#faeee2] border border-[#d8cdba] hover:border-[#85522b] text-[#2c241c] hover:text-[#85522b] rounded-xl font-mono transition-colors shrink-0 cursor-pointer font-bold"
            >
              Coca-Cola (613000000001)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000004')}
              className="px-2.5 py-1 bg-[#fdfbf7] hover:bg-[#faeee2] border border-[#d8cdba] hover:border-[#85522b] text-[#2c241c] hover:text-[#85522b] rounded-xl font-mono transition-colors shrink-0 cursor-pointer font-bold"
            >
              Huile Olive (613000000004)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000012')}
              className="px-2.5 py-1 bg-[#fdfbf7] hover:bg-[#faeee2] border border-[#d8cdba] hover:border-[#85522b] text-[#2c241c] hover:text-[#85522b] rounded-xl font-mono transition-colors shrink-0 cursor-pointer font-bold"
            >
              Écouteurs BT (613000000012)
            </button>
            <button
              type="button"
              onClick={() => executeScan('613000000013')}
              className="px-2.5 py-1 bg-[#fdfbf7] hover:bg-[#fef2f2] border border-[#d8cdba] hover:border-[#fca5a5] text-[#2c241c] hover:text-[#b91c1c] rounded-xl font-mono transition-colors shrink-0 cursor-pointer font-bold"
            >
              Pain Rupture (613000000013)
            </button>
          </div>

          {/* Barcode feedback banner */}
          {scanFeedback && (
            <div
              className={`p-3 rounded-2xl text-xs font-bold flex items-center justify-between animate-in fade-in zoom-in-95 duration-150 ${
                scanFeedback.type === 'success'
                  ? 'bg-[#eaf2e8] text-[#234931] border border-[#cbe0cb]'
                  : 'bg-[#fef2f2] text-[#991b1b] border border-[#fecaca]'
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
            <div className="p-3 bg-[#fffbeb] text-[#92400e] border-2 border-[#fde68a] rounded-2xl text-xs font-bold flex items-center justify-between shadow-md animate-in slide-in-from-top-2 duration-200">
              <div className="flex items-center gap-2.5">
                <AlertCircle className="w-5 h-5 text-[#d97706] shrink-0" />
                <div>
                  <div className="font-extrabold text-[#78350f]">
                    ⚠️ Attention : Seuil Minimal de Stock Dépassé !
                  </div>
                  <div className="text-[11px] font-normal text-[#92400e]">
                    "{stockWarningToast.productName}" ne dispose plus que de{' '}
                    <strong className="font-bold underline">{stockWarningToast.stock} unité(s)</strong>{' '}
                    en stock (seuil minimal d'alerte : {stockWarningToast.threshold}).
                  </div>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setStockWarningToast(null)}
                className="touch-btn p-1 text-[#b45309] hover:text-[#78350f] transition-colors cursor-pointer"
                title="Ignorer l'alerte"
              >
                <X className="w-4 h-4" />
              </button>
            </div>
          )}

          {/* Search Input with F1 shortcut badge */}
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-[#877a6b] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Filtrer les articles par nom ou référence... [F1]"
                className="w-full pl-9 pr-12 py-2 sherwood-input text-xs"
              />
              <span className="absolute right-2.5 top-1/2 -translate-y-1/2 font-mono font-bold text-[10px] text-[#234931] bg-[#eaf2e8] border border-[#cbe0cb] px-1.5 py-0.5 rounded shadow-2xs">
                F1
              </span>
            </div>

            {/* Mobile View Cart Button */}
            <button
              type="button"
              onClick={() => setIsCartDrawerOpen(true)}
              className="lg:hidden touch-btn px-3 py-2 sherwood-btn-forest text-xs font-bold flex items-center gap-1.5 cursor-pointer shrink-0"
            >
              <ShoppingCart className="w-4 h-4 text-[#faeee2]" />
              <span>Panier ({cartSummary.totalItems})</span>
            </button>
          </div>

          {/* Keyboard Shortcuts Mapping Bar */}
          <div className="flex items-center justify-between sherwood-panel-subtle px-3 py-1.5 text-xs">
            <div className="flex items-center gap-2 overflow-x-auto text-[11px]">
              <span className="font-bold text-[#605547] flex items-center gap-1 shrink-0">
                <Keyboard className="w-3.5 h-3.5 text-[#234931]" />
                Raccourcis :
              </span>
              <button
                type="button"
                onClick={() => {
                  searchInputRef.current?.focus();
                  searchInputRef.current?.select();
                }}
                className="inline-flex items-center gap-1 bg-[#fdfbf7] hover:bg-[#f4efe4] px-2 py-0.5 rounded-lg border border-[#e2d7c2] shadow-2xs transition-colors cursor-pointer"
                title="Cibler la recherche produit"
              >
                <kbd className="font-mono font-black text-[10px] bg-[#eaf2e8] text-[#234931] px-1 rounded">F1</kbd>
                <span className="text-[#2c241c] font-semibold">Recherche</span>
              </button>
              <button
                type="button"
                onClick={initiateCheckout}
                className="inline-flex items-center gap-1 bg-[#fdfbf7] hover:bg-[#f4efe4] px-2 py-0.5 rounded-lg border border-[#e2d7c2] shadow-2xs transition-colors cursor-pointer"
                title="Initier l'encaissement"
              >
                <kbd className="font-mono font-black text-[10px] bg-[#eaf2e8] text-[#234931] px-1 rounded">F2</kbd>
                <span className="text-[#2c241c] font-semibold">Encaisser</span>
              </button>
              <button
                type="button"
                onClick={clearCart}
                disabled={cart.length === 0}
                className="inline-flex items-center gap-1 bg-[#fdfbf7] hover:bg-[#f4efe4] disabled:opacity-40 px-2 py-0.5 rounded-lg border border-[#e2d7c2] shadow-2xs transition-colors cursor-pointer"
                title="Vider le panier"
              >
                <kbd className="font-mono font-black text-[10px] bg-[#faeee2] text-[#85522b] px-1 rounded">Échap</kbd>
                <span className="text-[#2c241c] font-semibold">Vider Panier</span>
              </button>
            </div>
            <button
              type="button"
              onClick={() => setShowShortcutGuideModal(true)}
              className="text-[11px] font-bold text-[#234931] hover:underline flex items-center gap-1 shrink-0 cursor-pointer ml-2"
              title="Guide des raccourcis caisse"
            >
              <HelpCircle className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Guide Raccourcis</span>
            </button>
          </div>

          {/* Keyboard shortcut feedback toast */}
          {shortcutFeedback && (
            <div
              className={`p-2.5 rounded-xl text-xs font-bold flex items-center justify-between shadow-sm animate-in fade-in slide-in-from-top-1 duration-150 ${
                shortcutFeedback.type === 'success'
                  ? 'bg-[#eaf2e8] text-[#234931] border border-[#cbe0cb]'
                  : shortcutFeedback.type === 'warning'
                  ? 'bg-[#fffbeb] text-[#92400e] border border-[#fde68a]'
                  : 'bg-[#faeee2] text-[#85522b] border border-[#f0d4ba]'
              }`}
            >
              <div className="flex items-center gap-2">
                <kbd className="font-mono bg-white px-2 py-0.5 rounded-md border border-[#d8cdba] shadow-2xs font-black">
                  {shortcutFeedback.key}
                </kbd>
                <span>{shortcutFeedback.label}</span>
              </div>
            </div>
          )}

          {/* Category Chips scroll */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs">
            <button
              type="button"
              onClick={() => setSelectedCatId('ALL')}
              className={`touch-btn px-3.5 py-1.5 rounded-xl font-bold transition-all whitespace-nowrap cursor-pointer ${
                selectedCatId === 'ALL'
                  ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                  : 'sherwood-btn-outline'
              }`}
            >
              Tous
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => setSelectedCatId(c.id)}
                className={`touch-btn px-3.5 py-1.5 rounded-xl font-bold transition-all whitespace-nowrap cursor-pointer ${
                  selectedCatId === c.id
                    ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                    : 'sherwood-btn-outline'
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
            <div className="h-full flex flex-col items-center justify-center p-8 text-center text-[#877a6b]">
              <Package className="w-10 h-10 mb-2 text-[#c7baa3]" />
              <p className="text-xs font-bold text-[#483d31]">Aucun produit ne correspond</p>
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
                        ? 'ring-4 ring-[#234931]/30 border-[#234931] scale-102 bg-[#eaf2e8]'
                        : isOutOfStock
                        ? 'bg-[#f7f2e7]/70 border-[#e2d7c2] opacity-60 cursor-not-allowed'
                        : 'sherwood-card hover:border-[#234931]/60 hover:shadow-md active:scale-98'
                    }`}
                  >
                    {/* Image / Thumbnail */}
                    <div className="aspect-4/3 rounded-xl bg-[#f7f2e7] overflow-hidden mb-2 relative border border-[#e7ddca]">
                      {p.imageUrl ? (
                        <img
                          src={p.imageUrl}
                          alt={p.name}
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-[#c7baa3]">
                          <Package className="w-8 h-8" />
                        </div>
                      )}

                      {/* Stock badge */}
                      <div className="absolute top-1.5 left-1.5">
                        {isOutOfStock ? (
                          <span className="bg-[#dc2626] text-white text-[9px] font-bold px-1.5 py-0.5 rounded-md">
                            Rupture
                          </span>
                        ) : p.stock <= p.lowStockThreshold ? (
                          <span className="bg-[#d97706] text-white text-[9px] font-bold px-1.5 py-0.5 rounded-md">
                            Reste {p.stock}
                          </span>
                        ) : null}
                      </div>

                      {/* Cart badge on tile */}
                      {inCart > 0 && (
                        <div className="absolute top-1.5 right-1.5 bg-[#85522b] text-white text-[10px] font-black px-1.5 py-0.5 rounded-lg shadow-sm font-mono">
                          x{inCart}
                        </div>
                      )}
                    </div>

                    {/* Details */}
                    <div>
                      <h4 className="font-bold text-xs text-[#2c241c] line-clamp-1">
                        {p.name}
                      </h4>
                      <div className="text-[10px] text-[#877a6b] font-mono mt-0.5 flex items-center justify-between">
                        <span>{p.sku}</span>
                        <span className="text-[9px] text-[#877a6b]">{p.barcode.slice(-4)}</span>
                      </div>
                    </div>

                    {/* Price and tap to add button */}
                    <div className="mt-2 pt-2 border-t border-[#e7ddca] flex items-center justify-between">
                      <div className="font-black text-xs text-[#234931] font-mono">
                        {formatMoney(p.price)}
                      </div>
                      <button
                        type="button"
                        disabled={isOutOfStock}
                        className="touch-btn w-7 h-7 rounded-xl bg-[#eaf2e8] group-hover:bg-[#234931] text-[#234931] group-hover:text-white flex items-center justify-center transition-colors shadow-2xs"
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
        <div className="fixed inset-0 z-50 lg:hidden bg-black/50 backdrop-blur-xs flex flex-col justify-end">
          <div className="bg-[#fdfbf7] rounded-t-3xl max-h-[92vh] h-[85vh] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200">
            <div className="p-3 bg-[#f7f2e7] border-b border-[#e7ddca] flex items-center justify-between relative">
              <span className="w-10 h-1 bg-[#d8cdba] rounded-full mx-auto block mb-1"></span>
              <button
                type="button"
                onClick={() => setIsCartDrawerOpen(false)}
                className="touch-btn p-1 text-[#605547] hover:text-[#2c241c] absolute right-3 top-2"
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

      {/* Keyboard Shortcuts Guide Modal */}
      {showShortcutGuideModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-150">
          <div className="sherwood-panel w-full max-w-md p-0 overflow-hidden shadow-2xl">
            <div className="px-5 py-4 bg-[#1f3d29] text-white flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Keyboard className="w-5 h-5 text-emerald-300" />
                <h3 className="font-bold text-sm">Raccourcis Clavier du Poste Caisse</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowShortcutGuideModal(false)}
                className="text-[#c7dac7] hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              <p className="text-xs text-[#605547] font-medium">
                Utilisez ces raccourcis clavier pour accélérer les opérations en caisse sans toucher à la souris :
              </p>

              <div className="space-y-2.5">
                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Cibler la Recherche Produit</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Place le focus et sélectionne le texte du champ de recherche d'articles.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-[#eaf2e8] text-[#234931] px-2 py-1 rounded-lg border border-[#cbe0cb] shadow-2xs shrink-0">
                    F1
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Initier l'Encaissement (Transaction)</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Ouvre la fenêtre de règlement et de paiement pour la commande en cours.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-[#eaf2e8] text-[#234931] px-2 py-1 rounded-lg border border-[#cbe0cb] shadow-2xs shrink-0">
                    F2
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Vider le Panier / Fermer Modales</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Ferme les dialogues ouverts ou réinitialise immédiatement le panier de vente.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-[#faeee2] text-[#85522b] px-2 py-1 rounded-lg border border-[#f0d4ba] shadow-2xs shrink-0">
                    Échap / Esc
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Lecteur Code-barres USB / Bluetooth</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Validation automatique lors du scan d'un code EAN-13 ou code-barres.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-white text-[#2c241c] px-2 py-1 rounded-lg border border-[#d8cdba] shadow-2xs shrink-0">
                    Entrée ↵
                  </kbd>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => setShowShortcutGuideModal(false)}
                  className="w-full py-2.5 sherwood-btn-forest text-xs font-bold"
                >
                  Compris
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
