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
  ChevronDown,
  ChevronUp,
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
    isOffline,
  } = usePos();

  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCatId, setSelectedCatId] = useState<number | 'ALL'>('ALL');
  const [barcodeInput, setBarcodeInput] = useState('');
  const [showDemoEanBar, setShowDemoEanBar] = useState(false);
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
            label: 'Panier vide : ajoutez des articles avant d\'encaisser',
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
    cart,
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
      <div className="fixed top-20 right-6 z-50 space-y-2 max-w-sm pointer-events-none">
        {scanFeedback && (
          <div
            className={`p-3 rounded-2xl text-xs font-bold flex items-center justify-between shadow-lg pointer-events-auto animate-in fade-in slide-in-from-top-2 duration-150 ${
              scanFeedback.type === 'success'
                ? 'bg-[#1f3d29] text-[#fcfbf7] border border-[#2b5437]'
                : 'bg-[#b91c1c] text-white border border-rose-800'
            }`}
          >
            <div className="flex items-center gap-2">
              <Volume2 className="w-4 h-4 shrink-0 text-[#a8d3a8]" />
              <span>{scanFeedback.message}</span>
            </div>
            {scanFeedback.latencyMs !== undefined && (
              <span className="font-mono text-[10px] px-2 py-0.5 rounded-md bg-white/20 text-white shrink-0 ml-2">
                ⚡ {scanFeedback.latencyMs} ms
              </span>
            )}
          </div>
        )}

        {stockWarningToast && (
          <div className="p-3 bg-[#fffbeb] text-[#92400e] border-2 border-[#fde68a] rounded-2xl text-xs font-bold flex items-center justify-between shadow-xl pointer-events-auto animate-in slide-in-from-top-2 duration-200">
            <div className="flex items-center gap-2.5">
              <AlertCircle className="w-5 h-5 text-[#d97706] shrink-0" />
              <div>
                <div className="font-extrabold text-[#78350f]">
                  ⚠️ Seuil Minimal Atteint
                </div>
                <div className="text-[11px] font-normal text-[#92400e]">
                  "{stockWarningToast.productName}" : {stockWarningToast.stock} restant(s).
                </div>
              </div>
            </div>
            <button
              type="button"
              onClick={() => setStockWarningToast(null)}
              className="touch-btn p-1 text-[#b45309] hover:text-[#78350f] cursor-pointer"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}

        {shortcutFeedback && (
          <div
            className={`p-2.5 rounded-xl text-xs font-bold flex items-center justify-between shadow-lg pointer-events-auto animate-in fade-in slide-in-from-top-1 duration-150 ${
              shortcutFeedback.type === 'success'
                ? 'bg-[#234931] text-[#fdfbf7]'
                : shortcutFeedback.type === 'warning'
                ? 'bg-[#8d5732] text-white'
                : 'bg-[#2c241c] text-[#fdfbf7]'
            }`}
          >
            <div className="flex items-center gap-2">
              <kbd className="font-mono bg-white/20 px-2 py-0.5 rounded text-[11px] font-black">
                {shortcutFeedback.key}
              </kbd>
              <span>{shortcutFeedback.label}</span>
            </div>
          </div>
        )}
      </div>

      {/* Left Column: Product Selection & Barcode scanner */}
      <div className="flex-1 flex flex-col sherwood-panel p-4 sm:p-5 overflow-hidden">
        {/* Streamlined Top Bar (Dual Barcode & Search) */}
        <div className="space-y-2.5 pb-3 border-b border-[#e7ddca]">
          <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-2.5">
            {/* Barcode scanner form */}
            <form onSubmit={handleFormSubmit} className="flex-1 flex items-center gap-2">
              <div className="relative flex-1">
                <Barcode className="w-4 h-4 text-[#234931] absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  ref={barcodeInputRef}
                  type="text"
                  value={barcodeInput}
                  onChange={(e) => setBarcodeInput(e.target.value)}
                  placeholder="Scanner un code EAN ou tapez réf... [Entrée]"
                  className="w-full pl-9 pr-20 py-2 bg-[#f7f2e7] border border-[#d8cdba] rounded-xl text-xs sm:text-sm font-mono placeholder:font-sans placeholder:text-[#877a6b] focus:outline-hidden focus:border-[#234931]"
                />
                <div className="absolute right-2 top-1/2 -translate-y-1/2 flex items-center">
                  <span className="hidden md:inline-flex items-center gap-1 text-[9px] font-bold text-[#234931] bg-[#eaf2e8] px-1.5 py-0.5 rounded border border-[#cbe0cb]">
                    <Zap className="w-2.5 h-2.5 text-[#234931]" />
                    Auto-Scan
                  </span>
                </div>
              </div>

              <button
                type="submit"
                className="touch-btn px-3.5 py-2 sherwood-btn-forest text-xs font-bold flex items-center gap-1 shrink-0"
              >
                <Barcode className="w-3.5 h-3.5" />
                <span className="hidden xs:inline">Valider</span>
              </button>
            </form>

            {/* Filter Search Input */}
            <div className="relative sm:w-64">
              <Search className="w-4 h-4 text-[#877a6b] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                ref={searchInputRef}
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Filtrer par nom... [F1]"
                className="w-full pl-9 pr-10 py-2 sherwood-input text-xs"
              />
              <span className="absolute right-2 top-1/2 -translate-y-1/2 font-mono font-bold text-[9px] text-[#234931] bg-[#eaf2e8] border border-[#cbe0cb] px-1 py-0.5 rounded">
                F1
              </span>
            </div>

            {/* Controls: Raccourcis + Démo EAN toggle + Mobile Cart */}
            <div className="flex items-center gap-1.5 shrink-0 self-end sm:self-auto">
              <button
                type="button"
                onClick={() => setShowShortcutGuideModal(true)}
                className="touch-btn px-2.5 py-2 sherwood-btn-outline text-[11px] font-bold flex items-center gap-1"
                title="Consulter les raccourcis clavier"
              >
                <Keyboard className="w-3.5 h-3.5 text-[#234931]" />
                <span className="hidden xl:inline">Raccourcis</span>
              </button>

              <button
                type="button"
                onClick={() => setShowDemoEanBar(!showDemoEanBar)}
                className={`touch-btn px-2.5 py-2 rounded-xl text-[11px] font-bold border transition-colors flex items-center gap-1 cursor-pointer ${
                  showDemoEanBar
                    ? 'bg-[#faeee2] text-[#85522b] border-[#e2c7ac]'
                    : 'bg-[#fdfbf7] text-[#605547] border-[#d8cdba] hover:bg-[#f7f2e7]'
                }`}
                title="Codes-barres démo pour tests rapides"
              >
                <Sparkles className="w-3.5 h-3.5 text-[#d97706]" />
                <span className="hidden md:inline">EAN Démo</span>
                {showDemoEanBar ? <ChevronUp className="w-3 h-3" /> : <ChevronDown className="w-3 h-3" />}
              </button>

              {/* Mobile View Cart Button */}
              <button
                type="button"
                onClick={() => setIsCartDrawerOpen(true)}
                className="lg:hidden touch-btn px-3 py-2 sherwood-btn-forest text-xs font-bold flex items-center gap-1.5 shrink-0"
              >
                <ShoppingCart className="w-4 h-4 text-[#faeee2]" />
                <span>({cartSummary.totalItems})</span>
              </button>
            </div>
          </div>

          {/* Collapsible Demo EAN Chips (Hidden by default to save space) */}
          {showDemoEanBar && (
            <div className="p-2.5 bg-[#faeee2]/80 border border-[#eddabb] rounded-xl flex items-center gap-2 overflow-x-auto text-[11px] animate-in fade-in slide-in-from-top-1 duration-150">
              <span className="text-[#85522b] font-bold shrink-0 flex items-center gap-1">
                <Sparkles className="w-3 h-3" />
                Tests rapides EAN :
              </span>
              <button
                type="button"
                onClick={() => executeScan('613000000001')}
                className="px-2 py-0.5 bg-white hover:bg-[#faeee2] border border-[#d8cdba] text-[#2c241c] rounded-lg font-mono font-bold transition-colors shrink-0 cursor-pointer"
              >
                Coca-Cola (613000000001)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000004')}
                className="px-2 py-0.5 bg-white hover:bg-[#faeee2] border border-[#d8cdba] text-[#2c241c] rounded-lg font-mono font-bold transition-colors shrink-0 cursor-pointer"
              >
                Huile Olive (613000000004)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000012')}
                className="px-2 py-0.5 bg-white hover:bg-[#faeee2] border border-[#d8cdba] text-[#2c241c] rounded-lg font-mono font-bold transition-colors shrink-0 cursor-pointer"
              >
                Écouteurs BT (613000000012)
              </button>
              <button
                type="button"
                onClick={() => executeScan('613000000013')}
                className="px-2 py-0.5 bg-white hover:bg-rose-50 border border-rose-200 text-rose-700 rounded-lg font-mono font-bold transition-colors shrink-0 cursor-pointer"
              >
                Pain Rupture (613000000013)
              </button>
            </div>
          )}

          {/* Category Chips scroll */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5 text-xs">
            <button
              type="button"
              onClick={() => setSelectedCatId('ALL')}
              className={`touch-btn px-3 py-1.5 rounded-xl font-bold transition-all whitespace-nowrap cursor-pointer text-xs ${
                selectedCatId === 'ALL'
                  ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                  : 'sherwood-btn-outline'
              }`}
            >
              Tous ({products.length})
            </button>
            {categories.map((c) => (
              <button
                key={c.id}
                type="button"
                onClick={() => setSelectedCatId(c.id)}
                className={`touch-btn px-3 py-1.5 rounded-xl font-bold transition-all whitespace-nowrap cursor-pointer text-xs ${
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

        {/* Product Grid (Fast Touch-friendly tiles directly under categories) */}
        <div className="flex-1 overflow-y-auto pt-2.5 pr-1">
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

                    {/* Details - line-clamp-2 ensures complete readable names */}
                    <div>
                      <h4 className="font-bold text-xs text-[#2c241c] line-clamp-2 min-h-[2.2rem] leading-snug">
                        {p.name}
                      </h4>
                      <div className="text-[10px] text-[#605547] font-mono mt-0.5 flex items-center justify-between">
                        <span>{p.sku}</span>
                        <span className="text-[9px] text-[#877a6b] font-semibold">{p.barcode.slice(-4)}</span>
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
          <div className="relative bg-[#fdfbf7] rounded-t-3xl max-h-[92vh] h-[85vh] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200">
            {/* Sheet Handle and Close button inside the sheet header */}
            <div className="relative p-3 bg-[#f7f2e7] border-b border-[#e7ddca] flex items-center justify-between">
              <span className="w-12 h-1.5 bg-[#d8cdba] rounded-full mx-auto block"></span>
              <button
                type="button"
                onClick={() => setIsCartDrawerOpen(false)}
                className="touch-btn p-1.5 text-[#605547] hover:text-[#2c241c] hover:bg-[#e7ddca] rounded-xl absolute right-3 top-2 transition-colors cursor-pointer"
                aria-label="Fermer le panier"
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
                <h3 className="font-bold text-sm font-serif-title">Raccourcis Clavier du Poste Caisse</h3>
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
                Utilisez ces touches pour accélérer la saisie sans quitter le clavier des yeux :
              </p>

              <div className="space-y-2.5">
                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Cibler la Recherche Produit</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Place le curseur dans le champ de recherche pour filtrer instantanément.
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
                      Ouvre la fenêtre de règlement et de calcul de monnaie.
                    </div>
                  </div>
                  <kbd className="font-mono font-bold text-xs bg-[#eaf2e8] text-[#234931] px-2 py-1 rounded-lg border border-[#cbe0cb] shadow-2xs shrink-0">
                    F2
                  </kbd>
                </div>

                <div className="flex items-start justify-between gap-3 p-3 rounded-xl sherwood-panel-subtle">
                  <div>
                    <div className="font-bold text-xs text-[#2c241c]">Fermer les Fenêtres & Tiroirs</div>
                    <div className="text-[11px] text-[#605547] mt-0.5">
                      Ferme en toute sécurité les modales ou aperçus ouverts (sans jamais effacer le panier).
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
                      Ajout instantané avec bip sonore dès la lecture optique.
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
                  Fermer le Guide
                </button>
              </div>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
