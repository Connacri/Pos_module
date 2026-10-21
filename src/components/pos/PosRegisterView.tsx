import React, { useState, useEffect, useRef, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Product } from '../../types';
import { CartPanel } from './CartPanel';
import {
  Search,
  Barcode,
  Plus,
  Package,
  AlertCircle,
  ShoppingCart,
  X,
  Volume2,
  Zap,
  Sparkles,
  Keyboard,
  HelpCircle,
} from 'lucide-react';

export const PosRegisterView: React.FC = () => {
  const {
    products,
    categories,
    cart,
    addToCart,
    initiateCheckout,
    isCheckoutOpen,
    setIsCheckoutOpen,
    isPrintPreviewOpen,
    setIsPrintPreviewOpen,
    scanAndAddToCart,
    cartSummary,
    isCartDrawerOpen,
    setIsCartDrawerOpen,
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

  // Responsive state to prevent double mounting of CartPanel on mobile
  const [isDesktop, setIsDesktop] = useState(() =>
    typeof window !== 'undefined' ? window.innerWidth >= 1024 : true
  );

  useEffect(() => {
    const handleResize = () => setIsDesktop(window.innerWidth >= 1024);
    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

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
  // NOTE: Per design critique, Esc ONLY closes modals/drawers and NEVER erases the cart!
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
            label: "Panier vide : ajoutez des articles avant d'encaisser",
            type: 'warning',
          });
        }
        setTimeout(() => setShortcutFeedback(null), 2500);
        return;
      }

      // 3. Esc (Escape): Safely dismiss modals and drawers only
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
        // Unfocus active inputs if pressed with no modal open
        if (document.activeElement instanceof HTMLElement) {
          document.activeElement.blur();
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
    cart.length,
    isCheckoutOpen,
    isPrintPreviewOpen,
    showShortcutGuideModal,
    isCartDrawerOpen,
    initiateCheckout,
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
    <div className="flex flex-col lg:flex-row items-stretch gap-6 h-[calc(100vh-140px)] min-h-[620px] relative">
      {/* FLOATING OVERLAY NOTIFICATIONS (Scan & Stock Warnings) - Does NOT push or jump product grid */}
      <div
        id="pos-toast-notifications"
        role="region"
        aria-label="Notifications et alertes de caisse"
        aria-live="polite"
        aria-atomic="false"
        className="fixed top-20 right-6 z-50 space-y-2 max-w-sm pointer-events-none"
      >
        {scanFeedback && (
          <div
            role="status"
            aria-live="polite"
            className={`p-3 rounded-2xl text-xs font-bold flex items-center justify-between shadow-lg pointer-events-auto animate-in fade-in slide-in-from-top-2 duration-150 ${
              scanFeedback.type === 'success'
                ? 'bg-forest-900 text-[#fcfbf7] border border-[#2b5437]'
                : 'bg-rose-700 text-white border border-rose-800'
            }`}
          >
            <div className="flex items-center gap-2">
              <Volume2 className="w-4 h-4 shrink-0 text-[#a8d3a8]" />
              <span>{scanFeedback.message}</span>
            </div>
            {scanFeedback.latencyMs !== undefined && (
              <span className="font-mono text-xs px-2 py-0.5 rounded-md bg-white/20 text-white shrink-0 ml-2">
                ⚡ {scanFeedback.latencyMs} ms
              </span>
            )}
          </div>
        )}

        {stockWarningToast && (
          <div
            role="alert"
            className="p-3 bg-amber-50 text-amber-900 border-2 border-amber-300 rounded-2xl text-xs font-bold flex items-center justify-between shadow-xl pointer-events-auto animate-in slide-in-from-top-2 duration-200"
          >
            <div className="flex items-center gap-2.5">
              <AlertCircle className="w-5 h-5 text-amber-600 shrink-0" />
              <div>
                <div className="font-extrabold text-amber-950">
                  ⚠️ Seuil minimal dépassé
                </div>
                <div className="text-xs font-normal text-amber-800">
                  "{stockWarningToast.productName}" : {stockWarningToast.stock} restant(s) (seuil : {stockWarningToast.threshold}).
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setStockWarningToast(null)}
              aria-label="Ignorer l'alerte"
              className="touch-btn p-1 text-amber-700 hover:text-amber-950 cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {shortcutFeedback && (
          <div
            role="status"
            aria-live="polite"
            className={`p-2.5 rounded-xl text-xs font-bold flex items-center justify-between shadow-lg pointer-events-auto animate-in fade-in slide-in-from-top-1 duration-150 ${
              shortcutFeedback.type === 'success'
                ? 'bg-forest-800 text-[#fdfbf7]'
                : shortcutFeedback.type === 'warning'
                ? 'bg-wood-600 text-white'
                : 'bg-ink-900 text-[#fdfbf7]'
            }`}
          >
            <div className="flex items-center gap-2">
              <kbd className="font-mono bg-white/20 px-2 py-0.5 rounded text-xs font-black">
                {shortcutFeedback.key}
              </kbd>
              <span>{shortcutFeedback.label}</span>
            </div>
          </div>
        )}
      </div>

      {/* Left Column: Product Selection & Barcode scanner */}
      <div className="flex-1 flex flex-col sherwood-card p-4 sm:p-5 overflow-hidden">
        {/* Top Header & Barcode scanner tool */}
        <div className="space-y-3 pb-3 border-b border-sand-100">
          {/* Barcode scanner form with latency indicator */}
          <form onSubmit={handleFormSubmit} className="flex items-center gap-2">
            <div className="relative flex-1">
              <Barcode className="w-5 h-5 text-forest-700 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                ref={barcodeInputRef}
                type="text"
                value={barcodeInput}
                onChange={(e) => setBarcodeInput(e.target.value)}
                placeholder="Scanner un code-barres EAN (ou tapez SKU / EAN et Entrée)..."
                className="w-full pl-11 pr-24 py-2.5 bg-sand-100/60 border border-sand-300/80 rounded-2xl text-xs sm:text-sm font-mono placeholder:font-sans placeholder:text-ink-600 focus:outline-hidden focus:ring-2 focus:ring-forest-700/20 focus:border-forest-700"
              />
              <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-1">
                <span className="hidden sm:inline-flex items-center gap-1 text-xs font-bold text-forest-800 bg-sand-200/80 px-2 py-0.5 rounded-md">
                  <Zap className="w-3 h-3 text-forest-700" />
                  Auto-Scan Actif
                </span>
              </div>
            </div>

            <button
              type="submit"
              className="touch-btn px-4 py-2.5 bg-forest-700 hover:bg-forest-800 text-white rounded-2xl text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer shrink-0"
            >
              <Barcode className="w-4 h-4" />
              <span>Valider</span>
            </button>
          </form>

          {/* Chips de test EAN : visibles en développement uniquement */}
          {import.meta.env.DEV && (
            <div className="flex items-center gap-1.5 overflow-x-auto pb-1 text-xs">
              <span className="text-ink-600 font-semibold shrink-0 flex items-center gap-1">
                <Sparkles className="w-3 h-3 text-amber-500" />
                Test rapide EAN :
              </span>
              <button
                type="button"
                onClick={() => executeScan('613000000001')}
                className="touch-btn px-2.5 py-1 bg-white hover:bg-sand-100 border border-sand-200 hover:border-sand-300 text-ink-700 hover:text-forest-800 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
              >
                Coca-Cola (613000000001)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000004')}
                className="touch-btn px-2.5 py-1 bg-white hover:bg-sand-100 border border-sand-200 hover:border-sand-300 text-ink-700 hover:text-forest-800 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
              >
                Huile Olive (613000000004)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000012')}
                className="touch-btn px-2.5 py-1 bg-white hover:bg-sand-100 border border-sand-200 hover:border-sand-300 text-ink-700 hover:text-forest-800 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
              >
                Écouteurs BT (613000000012)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000013')}
                className="touch-btn px-2.5 py-1 bg-white hover:bg-rose-50 border border-sand-200 hover:border-rose-300 text-ink-700 hover:text-rose-700 rounded-xl font-mono transition-colors shrink-0 cursor-pointer"
              >
                Pain Rupture (613000000013)
              </button>
            </div>
          )}

          {/* Search Input with F1 shortcut badge */}
          <div className="flex items-center gap-2">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-ink-600 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Filtrer les articles par nom ou référence... [F1]"
                className="w-full pl-9 pr-12 py-2 bg-sand-50 border border-sand-200 rounded-xl text-xs text-ink-900 focus:outline-hidden focus:ring-2 focus:ring-forest-700/20 focus:border-forest-700"
              />
              <span className="absolute right-2.5 top-1/2 -translate-y-1/2 font-mono font-bold text-xs text-forest-800 bg-sand-100 border border-sand-300 px-1.5 py-0.5 rounded shadow-2xs">
                F1
              </span>
            </div>

            <button
              type="button"
              onClick={() => setIsCartDrawerOpen(true)}
              className="lg:hidden touch-btn px-3 py-2 bg-forest-700 text-white rounded-xl text-xs font-bold flex items-center gap-1.5 shadow-xs cursor-pointer shrink-0"
            >
              <ShoppingCart className="w-4 h-4 text-emerald-300" />
              <span>Panier ({cartSummary.totalItems})</span>
            </button>
          </div>

          {/* Keyboard Shortcuts Mapping Bar */}
          <div className="flex items-center justify-between bg-sand-50 border border-sand-200/80 rounded-xl px-3 py-1.5 text-xs">
            <div className="flex items-center gap-2 overflow-x-auto text-xs">
              <span className="font-bold text-ink-600 flex items-center gap-1 shrink-0">
                <Keyboard className="w-3.5 h-3.5 text-forest-700" />
                Raccourcis :
              </span>
              <button
                type="button"
                onClick={() => {
                  searchInputRef.current?.focus();
                  searchInputRef.current?.select();
                }}
                className="inline-flex items-center gap-1 bg-white hover:bg-sand-100 px-2 py-0.5 rounded-lg border border-sand-200 shadow-2xs transition-colors cursor-pointer"
                title="Cibler la recherche produit"
              >
                <kbd className="font-mono font-black text-xs bg-sand-100 text-forest-800 px-1 rounded">F1</kbd>
                <span className="text-ink-700">Recherche</span>
              </button>
              <button
                type="button"
                onClick={initiateCheckout}
                className="inline-flex items-center gap-1 bg-white hover:bg-sand-100 px-2 py-0.5 rounded-lg border border-sand-200 shadow-2xs transition-colors cursor-pointer"
                title="Initier l'encaissement"
              >
                <kbd className="font-mono font-black text-xs bg-emerald-50 text-emerald-800 px-1 rounded">F2</kbd>
                <span className="text-ink-700">Encaisser</span>
              </button>
              <span className="inline-flex items-center gap-1 px-2 py-0.5 text-ink-700">
                <kbd className="font-mono font-black text-xs bg-rose-50 text-rose-800 px-1 rounded">Échap</kbd>
                <span>Fermer</span>
              </span>
            </div>
            <button
              type="button"
              onClick={() => setShowShortcutGuideModal(true)}
              className="text-xs font-bold text-forest-700 hover:text-forest-900 flex items-center gap-1 shrink-0 cursor-pointer ml-2"
              title="Guide des raccourcis caisse"
            >
              <HelpCircle className="w-3.5 h-3.5" />
              <span className="hidden sm:inline">Guide</span>
            </button>
          </div>

          {/* Category Chips scroll */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5 text-xs">
            <button
              type="button"
              onClick={() => setSelectedCatId('ALL')}
              className={`touch-btn px-4 rounded-xl font-semibold transition-all whitespace-nowrap cursor-pointer ${
                selectedCatId === 'ALL'
                  ? 'bg-ink-900 text-white shadow-2xs'
                  : 'bg-sand-100 text-ink-700 hover:bg-sand-200'
              }`}
            >
              Tous ({products.length})
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => setSelectedCatId(c.id)}
                className={`touch-btn px-4 rounded-xl font-semibold transition-all whitespace-nowrap cursor-pointer ${
                  selectedCatId === c.id
                    ? 'bg-forest-700 text-white shadow-2xs'
                    : 'bg-sand-100 text-ink-700 hover:bg-sand-200'
                }`}
              >
                {c.name}
              </button>
            ))}
          </div>
        </div>

        {/* Product Grid (Fast Touch-friendly tiles directly under categories) */}
        <div className="flex-1 overflow-y-auto pt-3 pr-1">
          {filteredProducts.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center p-8 text-center text-ink-600">
              <Package className="w-10 h-10 mb-2 text-sand-300" />
              <p className="text-xs font-semibold">Aucun produit ne correspond</p>
            </div>
          ) : (
            <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-3 xl:grid-cols-4 gap-3">
              {filteredProducts.map((p) => {
                const inCart = cartQtyMap.get(p.id) || 0;
                const isOutOfStock = p.stock <= 0;
                const isRecentlyScanned = lastScannedId === p.id;

                return (
                  <button
                    type="button"
                    key={p.id}
                    disabled={isOutOfStock}
                    aria-label={`Ajouter ${p.name}, ${formatMoney(p.price)}${isOutOfStock ? ', rupture de stock' : ''}`}
                    onClick={() => {
                      if (!isOutOfStock) {
                        addToCart(p, 1);
                        checkLowStockAlert(p);
                        setScanFeedback({
                          message: `Ajouté : ${p.name} (${formatMoney(p.price)})`,
                          type: 'success',
                        });
                        setTimeout(() => setScanFeedback(null), 1800);
                      }
                    }}
                    className={`p-3 text-left w-full rounded-2xl border transition-all flex flex-col justify-between group cursor-pointer relative focus-visible:ring-4 focus-visible:ring-forest-700/40 ${
                      isRecentlyScanned
                        ? 'ring-4 ring-forest-700/40 border-forest-700 scale-102 bg-sand-100/50'
                        : isOutOfStock
                        ? 'bg-sand-50/70 border-sand-200 opacity-60 cursor-not-allowed'
                        : 'bg-white border-sand-200/80 hover:border-forest-600 hover:shadow-md active:scale-98'
                    }`}
                  >
                    {/* Image / Thumbnail */}
                    <div className="aspect-4/3 rounded-xl bg-sand-100 overflow-hidden mb-2 relative border border-sand-200">
                      {p.imageUrl ? (
                        <img
                          src={p.imageUrl}
                          alt=""
                          className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                        />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center text-sand-300">
                          <Package className="w-8 h-8" />
                        </div>
                      )}

                      {/* Stock badge */}
                      <div className="absolute top-1.5 left-1.5">
                        {isOutOfStock ? (
                          <span className="bg-rose-600 text-white text-xs font-bold px-1.5 py-0.5 rounded-md">
                            Rupture
                          </span>
                        ) : p.stock <= p.lowStockThreshold ? (
                          <span className="bg-amber-500 text-white text-xs font-bold px-1.5 py-0.5 rounded-md">
                            Reste {p.stock}
                          </span>
                        ) : null}
                      </div>

                      {/* Cart badge on tile */}
                      {inCart > 0 && (
                        <div className="absolute top-1.5 right-1.5 bg-forest-700 text-white text-xs font-black px-1.5 py-0.5 rounded-lg shadow-sm font-mono">
                          x{inCart}
                        </div>
                      )}
                    </div>

                    {/* Details */}
                    <div>
                      <h4 className="font-bold text-xs text-ink-900 line-clamp-2 min-h-[2.2rem] leading-snug">
                        {p.name}
                      </h4>
                      <div className="text-xs text-ink-600 font-mono mt-0.5 flex items-center justify-between">
                        <span>{p.sku}</span>
                        <span className="text-xs text-ink-600">{p.barcode.slice(-4)}</span>
                      </div>
                    </div>

                    {/* Price and tap to add button */}
                    <div className="mt-2 pt-2 border-t border-sand-100 flex items-center justify-between">
                      <div className="font-extrabold text-xs text-forest-700 font-mono">
                        {formatMoney(p.price)}
                      </div>
                      <span
                        aria-hidden="true"
                        className="w-9 h-9 rounded-xl bg-sand-100 group-hover:bg-forest-700 text-forest-800 group-hover:text-white flex items-center justify-center transition-colors shadow-2xs"
                      >
                        <Plus className="w-4 h-4" />
                      </span>
                    </div>
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </div>

      {/* Right Column: Sticky Cart and Checkout Panel (Desktop only, mounted only on large screens) */}
      <div className="w-full lg:w-[380px] xl:w-[420px] shrink-0 hidden lg:flex flex-col">
        {isDesktop && <CartPanel />}
      </div>

      {/* Keyboard Shortcuts Guide Modal */}
      {showShortcutGuideModal && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink-900/60 backdrop-blur-xs p-4 animate-in fade-in duration-150">
          <div role="dialog" aria-modal="true" aria-labelledby="shortcut-guide-title" className="bg-white w-full max-w-md rounded-2xl shadow-2xl border border-sand-200 overflow-hidden">
            <div className="px-5 py-4 bg-ink-900 text-white flex items-center justify-between">
              <div className="flex items-center gap-2">
                <Keyboard className="w-5 h-5 text-sand-300" />
                <h3 id="shortcut-guide-title" className="font-bold text-sm">Raccourcis Clavier du Poste Caisse</h3>
              </div>
              <button
                type="button"
                onClick={() => setShowShortcutGuideModal(false)}
                aria-label="Fermer le guide des raccourcis"
                className="touch-btn inline-flex items-center justify-center text-sand-300 hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-5 space-y-4">
              <p className="text-xs text-ink-600">
                Utilisez ces raccourcis clavier pour accélérer les opérations en caisse sans toucher à la souris :
              </p>

              <div className="space-y-2.5">
                <div className="flex items-start justify-between gap-3 p-3 rounded-xl bg-sand-50 border border-sand-200/80">
                  <div>
                    <div className="font-bold text-xs text-ink-900">Cibler la Recherche Produit</div>
                    <div className="text-xs text-ink-600 mt-0.5">
                      Place le focus et sélectionne le texte du champ de recherche d'articles.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-sand-100 text-forest-800 px-2 py-1 rounded-lg border border-sand-300 shadow-2xs shrink-0">
                    F1
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl bg-sand-50 border border-sand-200/80">
                  <div>
                    <div className="font-bold text-xs text-ink-900">Initier l'Encaissement (Transaction)</div>
                    <div className="text-xs text-ink-600 mt-0.5">
                      Ouvre la fenêtre de règlement et de paiement pour la commande en cours.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-emerald-50 text-emerald-800 px-2 py-1 rounded-lg border border-emerald-300 shadow-2xs shrink-0">
                    F2
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl bg-sand-50 border border-sand-200/80">
                  <div>
                    <div className="font-bold text-xs text-ink-900">Fermer les fenêtres</div>
                    <div className="text-xs text-ink-600 mt-0.5">
                      Ferme les fenêtres ouvertes. Le panier n'est jamais vidé par ce raccourci.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-rose-50 text-rose-800 px-2 py-1 rounded-lg border border-rose-200 shadow-2xs shrink-0">
                    Échap
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl bg-sand-50 border border-sand-200/80">
                  <div>
                    <div className="font-bold text-xs text-ink-900">Lecteur Code-barres USB / Bluetooth</div>
                    <div className="text-xs text-ink-600 mt-0.5">
                      Validation automatique lors du scan d'un code EAN-13 ou code-barres.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-sand-100 text-ink-900 px-2 py-1 rounded-lg border border-sand-300 shadow-2xs shrink-0">
                    Entrée ↵
                  </kbd>
                </div>
              </div>

              <div className="pt-2">
                <button
                  type="button"
                  onClick={() => setShowShortcutGuideModal(false)}
                  className="w-full py-2.5 bg-forest-700 hover:bg-forest-800 text-white rounded-xl text-xs font-bold transition-colors cursor-pointer"
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
