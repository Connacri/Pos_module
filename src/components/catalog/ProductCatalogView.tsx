import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Product } from '../../types';
import { ProductImage } from '../common/ProductImage';
import {
  Search,
  Filter,
  Plus,
  ShoppingCart,
  Check,
  AlertTriangle,
  XCircle,
  Package,
  ArrowUpDown,
  Barcode,
  Layers,
  Edit2,
  X,
  Truck,
  Camera,
  Sparkles,
} from 'lucide-react';
import { CameraBarcodeScannerModal } from './CameraBarcodeScannerModal';

export const ProductCatalogView: React.FC = () => {
  const {
    products,
    categories,
    cart,
    cartSummary,
    addToCart,
    incrementQuantity,
    decrementQuantity,
    updateProduct,
    addProduct,
    setActiveView,
    setIsCartDrawerOpen,
  } = usePos();

  // Search & Filter state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | 'ALL'>('ALL');
  const [stockFilter, setStockFilter] = useState<'ALL' | 'IN_STOCK' | 'LOW_STOCK' | 'OUT_OF_STOCK'>('ALL');
  const [sortBy, setSortBy] = useState<'name' | 'price-asc' | 'price-desc' | 'stock'>('name');

  // Modal states
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [isCreatingNew, setIsCreatingNew] = useState(false);
  const [isCameraScannerOpen, setIsCameraScannerOpen] = useState(false);

  // Format currency
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Map cart quantities by productId for rapid O(1) lookup
  const cartQuantityMap = useMemo(() => {
    const map = new Map<number, number>();
    cart.forEach((item) => {
      map.set(item.product.id, item.quantity);
    });
    return map;
  }, [cart]);

  // Filter and sort products
  const filteredProducts = useMemo(() => {
    let result = [...products];

    // Search query filter (matches name, SKU, or barcode)
    if (searchQuery.trim()) {
      const q = searchQuery.toLowerCase().trim();
      result = result.filter(
        (p) =>
          p.name.toLowerCase().includes(q) ||
          p.sku.toLowerCase().includes(q) ||
          p.barcode.includes(q) ||
          (p.description && p.description.toLowerCase().includes(q))
      );
    }

    // Category filter
    if (selectedCategoryId !== 'ALL') {
      result = result.filter((p) => p.categoryId === selectedCategoryId);
    }

    // Stock status filter
    if (stockFilter === 'IN_STOCK') {
      result = result.filter((p) => p.stock > p.lowStockThreshold);
    } else if (stockFilter === 'LOW_STOCK') {
      result = result.filter((p) => p.stock > 0 && p.stock <= p.lowStockThreshold);
    } else if (stockFilter === 'OUT_OF_STOCK') {
      result = result.filter((p) => p.stock === 0);
    }

    // Sort
    result.sort((a, b) => {
      if (sortBy === 'name') return a.name.localeCompare(b.name, 'fr');
      if (sortBy === 'price-asc') return a.price - b.price;
      if (sortBy === 'price-desc') return b.price - a.price;
      if (sortBy === 'stock') return b.stock - a.stock;
      return 0;
    });

    return result;
  }, [products, searchQuery, selectedCategoryId, stockFilter, sortBy]);

  // Counts for filters
  const stockCounts = useMemo(() => {
    let inStock = 0;
    let lowStock = 0;
    let outOfStock = 0;

    products.forEach((p) => {
      if (p.stock === 0) outOfStock++;
      else if (p.stock <= p.lowStockThreshold) lowStock++;
      else inStock++;
    });

    return { inStock, lowStock, outOfStock, total: products.length };
  }, [products]);

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Top Header & Quick Actions */}
      <div className="sherwood-panel flex flex-col md:flex-row md:items-center justify-between gap-4 overflow-hidden w-full min-w-0">
        <div className="min-w-0">
          <div className="sherwood-badge-forest mb-2">
            <Package className="w-3.5 h-3.5 text-[#234931] shrink-0" />
            <span>Inventaire & Tarification</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-[#234931] font-serif-title tracking-tight flex items-center gap-2 truncate">
            <span>🍃</span>
            <span>Catalogue des Produits</span>
          </h2>
          <p className="text-xs sm:text-sm text-[#605547] mt-1 font-medium leading-relaxed">
            Gérez vos références, suivez les stocks en temps réel et alimentez le panier POS
          </p>
        </div>

        <div className="flex items-center gap-2.5 flex-wrap sm:flex-nowrap shrink-0 w-full md:w-auto">
          <button
            type="button"
            onClick={() => setIsCameraScannerOpen(true)}
            className="touch-btn min-h-[44px] inline-flex items-center justify-center gap-2 px-4 py-2.5 sherwood-btn-outline text-xs font-bold shadow-2xs flex-1 md:flex-initial"
            title="Ouvrir le scanner caméra pour scanner un code-barres"
          >
            <Camera className="w-4 h-4 text-[#234931] shrink-0" />
            <span className="whitespace-nowrap">Scanner Caméra</span>
          </button>

          <button
            type="button"
            onClick={() => setIsCreatingNew(true)}
            className="touch-btn min-h-[44px] inline-flex items-center justify-center gap-2 px-4 py-2.5 sherwood-btn-forest text-xs font-bold shadow-xs flex-1 md:flex-initial"
          >
            <Plus className="w-4 h-4 shrink-0" />
            <span className="whitespace-nowrap">Nouveau Produit</span>
          </button>

          {cart.length > 0 && (
            <button
              type="button"
              onClick={() => setIsCartDrawerOpen(true)}
              className="touch-btn min-h-[44px] inline-flex items-center justify-center gap-2 px-4 py-2.5 sherwood-btn-wood text-xs font-bold shadow-xs w-full sm:w-auto"
            >
              <ShoppingCart className="w-4 h-4 text-[#fcdbb6] shrink-0" />
              <span className="whitespace-nowrap">Voir Panier ({cart.reduce((sum, item) => sum + item.quantity, 0)})</span>
            </button>
          )}
        </div>
      </div>

      {/* Filter and Search Bar: Adaptive 2-tier responsive architecture */}
      <div className="sherwood-panel p-4 sm:p-5 space-y-4 w-full min-w-0 overflow-hidden">
        {/* Tier 1: Search + Sort row (balanced 2-column on md+, stacked on mobile) */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center gap-3 w-full min-w-0">
          {/* Search Input with inline camera scanner trigger */}
          <div className="relative flex-1 flex items-center gap-2 min-w-0">
            <div className="relative flex-1 min-w-0">
              <Search className="w-4 h-4 text-[#877a6b] absolute left-3.5 top-1/2 -translate-y-1/2 pointer-events-none" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Rechercher par nom, SKU (ex: REF-0001) ou code-barres..."
                className="w-full pl-10 pr-9 py-2.5 min-h-[44px] sherwood-input text-xs sm:text-sm font-medium"
              />
              {searchQuery && (
                <button
                  type="button"
                  onClick={() => setSearchQuery('')}
                  aria-label="Effacer la recherche"
                  className="touch-btn absolute right-2.5 top-1/2 -translate-y-1/2 p-1 text-[#877a6b] hover:text-[#2c241c] cursor-pointer"
                >
                  <X className="w-4 h-4" />
                </button>
              )}
            </div>

            <button
              type="button"
              onClick={() => setIsCameraScannerOpen(true)}
              className="touch-btn min-h-[44px] px-3.5 py-2.5 sherwood-btn-forest text-xs font-bold flex items-center justify-center gap-1.5 shrink-0"
              title="Scanner une étiquette physique avec la caméra"
            >
              <Camera className="w-4 h-4 shrink-0" />
              <span className="hidden sm:inline">Scanner</span>
            </button>
          </div>

          {/* Sort Selector: Fixed width on md+, full width on mobile */}
          <div className="flex items-center gap-2 w-full md:w-64 shrink-0">
            <ArrowUpDown className="w-4 h-4 text-[#877a6b] shrink-0" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              className="w-full min-h-[44px] sherwood-input px-3 py-2 text-xs font-bold cursor-pointer"
              aria-label="Trier les produits"
            >
              <option value="name">Nom (A → Z)</option>
              <option value="price-asc">Prix (Croissant)</option>
              <option value="price-desc">Prix (Décroissant)</option>
              <option value="stock">Quantité en stock</option>
            </select>
          </div>
        </div>

        {/* Tier 2: Stock Status Filter Pills (segmented bar, never overflows parent) */}
        <div className="pt-2 border-t border-[#e7ddca] w-full min-w-0">
          <div className="flex items-center gap-2 overflow-x-auto pb-1 max-w-full text-xs font-bold scrollbar-none">
            <button
              type="button"
              onClick={() => setStockFilter('ALL')}
              className={`touch-btn min-h-[44px] px-3.5 py-2 rounded-2xl transition-all whitespace-nowrap cursor-pointer flex items-center gap-2 shrink-0 ${
                stockFilter === 'ALL'
                  ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                  : 'bg-white text-ink-800 border border-sand-300 hover:bg-sand-100'
              }`}
            >
              <span>Tous les articles</span>
              <span className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded-full ${stockFilter === 'ALL' ? 'bg-white/20 text-white' : 'bg-sand-200 text-ink-800'}`}>
                {stockCounts.total}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStockFilter('IN_STOCK')}
              className={`touch-btn min-h-[44px] px-3.5 py-2 rounded-2xl transition-all flex items-center gap-2 whitespace-nowrap cursor-pointer shrink-0 ${
                stockFilter === 'IN_STOCK'
                  ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                  : 'bg-white text-emerald-800 border border-emerald-300 hover:bg-emerald-50'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-emerald-500 inline-block shrink-0"></span>
              <span>En stock</span>
              <span className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded-full ${stockFilter === 'IN_STOCK' ? 'bg-white/20 text-white' : 'bg-emerald-100 text-emerald-900'}`}>
                {stockCounts.inStock}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStockFilter('LOW_STOCK')}
              className={`touch-btn min-h-[44px] px-3.5 py-2 rounded-2xl transition-all flex items-center gap-2 whitespace-nowrap cursor-pointer shrink-0 ${
                stockFilter === 'LOW_STOCK'
                  ? 'bg-[#b45309] text-white shadow-xs'
                  : 'bg-white text-[#b45309] border border-amber-300 hover:bg-amber-50'
              }`}
            >
              <AlertTriangle className="w-3.5 h-3.5 text-[#d97706] shrink-0" />
              <span>Alerte seuil</span>
              <span className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded-full ${stockFilter === 'LOW_STOCK' ? 'bg-white/20 text-white' : 'bg-amber-100 text-amber-900'}`}>
                {stockCounts.lowStock}
              </span>
            </button>

            <button
              type="button"
              onClick={() => setStockFilter('OUT_OF_STOCK')}
              className={`touch-btn min-h-[44px] px-3.5 py-2 rounded-2xl transition-all flex items-center gap-2 whitespace-nowrap cursor-pointer shrink-0 ${
                stockFilter === 'OUT_OF_STOCK'
                  ? 'bg-[#dc2626] text-white shadow-xs'
                  : 'bg-white text-[#dc2626] border border-rose-300 hover:bg-rose-50'
              }`}
            >
              <XCircle className="w-3.5 h-3.5 text-[#ef4444] shrink-0" />
              <span>Rupture</span>
              <span className={`text-[11px] font-mono font-bold px-2 py-0.5 rounded-full ${stockFilter === 'OUT_OF_STOCK' ? 'bg-white/20 text-white' : 'bg-rose-100 text-rose-900'}`}>
                {stockCounts.outOfStock}
              </span>
            </button>
          </div>
        </div>

        {/* Tier 3: Category Filter Tabs with smooth scroll and container containment */}
        <div className="pt-2 border-t border-[#e7ddca] w-full min-w-0">
          <div className="flex items-center gap-2 overflow-x-auto pb-1 max-w-full scrollbar-none">
            <span className="text-xs text-[#877a6b] font-bold shrink-0 flex items-center gap-1 mr-1">
              <Filter className="w-3.5 h-3.5" />
              Rayons :
            </span>

            <button
              type="button"
              onClick={() => setSelectedCategoryId('ALL')}
              className={`touch-btn min-h-[44px] px-4 py-2 rounded-2xl text-xs font-bold whitespace-nowrap transition-colors cursor-pointer flex items-center gap-2 shrink-0 ${
                selectedCategoryId === 'ALL'
                  ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                  : 'bg-white text-ink-800 border border-sand-300 hover:bg-sand-100'
              }`}
            >
              <span>Tous les rayons</span>
              <span
                className={`text-[11px] px-2 py-0.5 rounded-full font-mono font-bold ${
                  selectedCategoryId === 'ALL' ? 'bg-white/20 text-white' : 'bg-sand-200 text-ink-800'
                }`}
              >
                {products.length}
              </span>
            </button>

            {categories.map((cat) => {
              const count = products.filter((p) => p.categoryId === cat.id).length;
              const isSelected = selectedCategoryId === cat.id;
              return (
                <button
                  key={cat.id}
                  type="button"
                  onClick={() => setSelectedCategoryId(cat.id)}
                  className={`touch-btn min-h-[44px] px-4 py-2 rounded-2xl text-xs font-bold whitespace-nowrap transition-colors flex items-center gap-2 cursor-pointer shrink-0 ${
                    isSelected
                      ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                      : 'bg-white text-ink-800 border border-sand-300 hover:bg-sand-100'
                  }`}
                >
                  <span>{cat.name}</span>
                  <span
                    className={`text-[11px] px-2 py-0.5 rounded-full font-mono font-bold ${
                      isSelected ? 'bg-white/20 text-white' : 'bg-sand-200 text-ink-800'
                    }`}
                  >
                    {count}
                  </span>
                </button>
              );
            })}
          </div>
        </div>
      </div>

      {/* Reorder Needs Visual Indicator Banner */}
      {(stockCounts.lowStock > 0 || stockCounts.outOfStock > 0) && (
        <div className="bg-gradient-to-r from-[#fef3c7] via-[#fffbeb] to-[#faeee2] border-2 border-[#fde68a] rounded-3xl p-4 flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3 shadow-xs">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-2xl bg-[#d97706] text-white flex items-center justify-center shrink-0 shadow-sm animate-pulse">
              <AlertTriangle className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h3 className="font-serif-title font-black text-sm text-[#78350f]">
                  Surveillance des Réapprovisionnements
                </h3>
                <span className="bg-[#fef3c7] text-[#92400e] border border-[#fde68a] text-[10px] font-black px-2 py-0.5 rounded-full font-mono">
                  {stockCounts.lowStock + stockCounts.outOfStock} référence(s) sous le seuil
                </span>
              </div>
              <p className="text-xs text-[#92400e] mt-0.5 font-medium">
                Certains articles ont atteint ou dépassé leur seuil minimal de sécurité. Les cartes en surbrillance ambrée/rouge indiquent le besoin de réapprovisionnement.
              </p>
            </div>
          </div>
          <div className="flex items-center gap-2 shrink-0 self-end sm:self-auto">
            <button
              type="button"
              onClick={() => setStockFilter(stockFilter === 'LOW_STOCK' ? 'ALL' : 'LOW_STOCK')}
              className={`touch-btn px-3.5 py-1.5 text-xs font-bold rounded-xl transition-all flex items-center gap-1.5 cursor-pointer shadow-2xs ${
                stockFilter === 'LOW_STOCK'
                  ? 'bg-[#85522b] text-white'
                  : 'bg-white hover:bg-[#faeee2] text-[#85522b] border border-[#f0d4ba]'
              }`}
            >
              <Truck className="w-3.5 h-3.5" />
              <span>{stockFilter === 'LOW_STOCK' ? 'Afficher tous les articles' : 'Filtrer besoins de réappro'}</span>
            </button>
          </div>
        </div>
      )}

      {/* Responsive Products Grid */}
      {filteredProducts.length === 0 ? (
        <div className="sherwood-panel p-12 text-center">
          <div className="w-16 h-16 mx-auto mb-4 bg-[#f7f2e7] rounded-full flex items-center justify-center text-[#c7baa3] border border-[#e2d7c2]">
            <Package className="w-8 h-8" />
          </div>
          <h3 className="text-base font-bold text-[#2c241c] mb-1">
            Aucun article correspondant
          </h3>
          <p className="text-xs text-[#877a6b] max-w-sm mx-auto mb-4 font-medium">
            Modifiez votre recherche ou réinitialisez les filtres pour afficher des produits.
          </p>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setSelectedCategoryId('ALL');
              setStockFilter('ALL');
            }}
            className="touch-btn px-4 py-2 sherwood-btn-outline text-xs font-bold"
          >
            Réinitialiser les filtres
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-5">
          {filteredProducts.map((product) => {
            const inCartQty = cartQuantityMap.get(product.id) || 0;
            const category = categories.find((c) => c.id === product.categoryId);
            const isOutOfStock = product.stock <= 0;
            const isLowStock = !isOutOfStock && product.stock <= product.lowStockThreshold;

            return (
              <div
                key={product.id}
                className={`sherwood-card transition-all flex flex-col overflow-hidden group relative ${
                  isOutOfStock
                    ? 'border-2 border-[#dc2626] bg-[#fef2f2]/40 ring-1 ring-[#fca5a5]'
                    : isLowStock
                    ? 'border-2 border-[#d97706] bg-[#fffbeb]/40 ring-1 ring-[#fde68a]'
                    : 'hover:border-[#234931]/60'
                }`}
              >
                {/* Product Image & Badges */}
                <div className="relative aspect-4/3 bg-[#f7f2e7] overflow-hidden border-b border-[#e7ddca]">
                  <ProductImage
                    src={product.imageUrl}
                    alt={product.name}
                    categoryId={product.categoryId}
                    categoryName={category?.name}
                  />

                  {/* Top Badges: constrained within bounds so they never collide with edit button */}
                  <div className="absolute top-2 left-2 right-14 flex flex-col gap-1 z-10 min-w-0 pointer-events-none">
                    {isOutOfStock ? (
                      <span className="bg-[#dc2626] text-white text-[10px] font-black px-2 py-0.5 rounded-md shadow-xs flex items-center gap-1 w-fit max-w-full truncate">
                        <XCircle className="w-3 h-3 shrink-0" />
                        <span className="truncate">Rupture • Réappro</span>
                      </span>
                    ) : isLowStock ? (
                      <span className="bg-[#d97706] text-white text-[10px] font-bold px-2 py-0.5 rounded-md shadow-xs flex items-center gap-1 animate-pulse w-fit max-w-full truncate">
                        <AlertTriangle className="w-3 h-3 shrink-0" />
                        <span className="truncate">Sous seuil ({product.stock}/{product.lowStockThreshold})</span>
                      </span>
                    ) : null}

                    <div className="flex items-center gap-1 flex-wrap max-w-full">
                      <span className="bg-[#1f3d29]/90 text-white text-[10px] font-mono px-2 py-0.5 rounded-md font-bold shrink-0">
                        {product.sku}
                      </span>
                      {category && (
                        <span className="bg-[#fdfbf7]/95 text-[#2c241c] text-[10px] font-bold px-2 py-0.5 rounded-md shadow-xs truncate border border-[#e2d7c2] max-w-[130px]">
                          {category.name}
                        </span>
                      )}
                    </div>
                  </div>

                  {/* Edit button with >= 44x44px touch target (Fitts's Law) */}
                  <button
                    type="button"
                    onClick={() => setEditingProduct(product)}
                    className="touch-btn absolute top-2 right-2 w-11 h-11 min-w-[44px] min-h-[44px] bg-white/95 hover:bg-white text-[#605547] hover:text-[#234931] rounded-2xl flex items-center justify-center shadow-xs transition-colors cursor-pointer z-20 border border-[#e2d7c2] focus:outline-hidden focus:ring-2 focus:ring-[#234931]"
                    title="Modifier l'article et son seuil"
                    aria-label={`Modifier ${product.name}`}
                  >
                    <Edit2 className="w-4 h-4" />
                  </button>

                  {/* In Cart Indicator */}
                  {inCartQty > 0 && (
                    <div className="absolute bottom-2 left-2 bg-[#85522b] text-white text-[11px] font-black px-2.5 py-1 rounded-lg shadow-sm flex items-center gap-1.5 z-10 font-mono">
                      <Check className="w-3.5 h-3.5" />
                      {inCartQty} au panier
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="p-4 flex-1 flex flex-col justify-between space-y-3 min-w-0">
                  <div className="min-w-0">
                    <h4 className="font-bold text-sm text-[#2c241c] line-clamp-2 group-hover:text-[#234931] transition-colors leading-snug break-words" title={product.name}>
                      {product.name}
                    </h4>
                    {product.description && (
                      <p className="text-[11px] text-[#877a6b] line-clamp-1 mt-1 font-medium truncate" title={product.description}>
                        {product.description}
                      </p>
                    )}

                    {/* Stock Status Pill: responsive flex wrapping */}
                    <div className="mt-2.5 flex flex-wrap sm:flex-nowrap items-center justify-between gap-1.5 text-xs min-w-0">
                      {isOutOfStock ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-[#dc2626] bg-[#fef2f2] px-2.5 py-1 rounded-lg border border-[#fecaca] shrink-0">
                          <XCircle className="w-3.5 h-3.5" />
                          Rupture (0)
                        </span>
                      ) : isLowStock ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-[#92400e] bg-[#fef3c7] px-2.5 py-1 rounded-lg border border-[#fde68a] shrink-0 truncate">
                          <AlertTriangle className="w-3.5 h-3.5 text-[#d97706] shrink-0" />
                          <span>Stock {product.stock} (Min {product.lowStockThreshold})</span>
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-bold text-[#234931] bg-[#eaf2e8] px-2.5 py-1 rounded-lg border border-[#cbe0cb] shrink-0">
                          <span className="w-2 h-2 rounded-full bg-emerald-600"></span>
                          <span>Stock : {product.stock}</span>
                        </span>
                      )}

                      <span className="text-[11px] text-[#877a6b] font-mono flex items-center gap-1 shrink-0 ml-auto sm:ml-0">
                        <Barcode className="w-3.5 h-3.5" />
                        {product.barcode.slice(-4)}
                      </span>
                    </div>

                    {/* Reorder Needs Visual Indicator Panel */}
                    {(isLowStock || isOutOfStock) && (
                      <div className={`mt-3 p-2.5 rounded-2xl text-[11px] border min-w-0 ${
                        isOutOfStock
                          ? 'bg-[#fef2f2] border-[#fecaca] text-[#991b1b]'
                          : 'bg-[#fef3c7] border-[#fde68a] text-[#78350f]'
                      }`}>
                        <div className="flex items-center justify-between font-bold gap-1">
                          <span className="flex items-center gap-1.5 truncate">
                            <Truck className="w-3.5 h-3.5 text-[#d97706] shrink-0" />
                            <span>Réappro requis :</span>
                          </span>
                          <span className="font-mono font-black shrink-0">
                            {product.stock} / {product.lowStockThreshold} min
                          </span>
                        </div>
                        <div className="w-full bg-[#e2d7c2] rounded-full h-2 mt-2 overflow-hidden">
                          <div
                            className={`h-full rounded-full transition-all duration-300 ${isOutOfStock ? 'bg-[#dc2626] w-0' : 'bg-[#d97706]'}`}
                            style={{ width: `${Math.min(100, Math.round((product.stock / Math.max(1, product.lowStockThreshold)) * 100))}%` }}
                          />
                        </div>
                        <div className="mt-2.5 flex flex-col sm:flex-row items-stretch sm:items-center justify-between text-xs gap-2 min-w-0">
                          <span className="text-[10px] truncate">
                            Déficit : <strong className="font-bold">{Math.max(0, product.lowStockThreshold - product.stock)} unité(s)</strong>
                          </span>
                          <button
                            type="button"
                            onClick={() => updateProduct({ ...product, stock: product.stock + 10 })}
                            className="touch-btn min-h-[44px] px-3.5 py-1.5 bg-white text-[#234931] font-bold rounded-xl border border-[#d8cdba] hover:bg-[#f7f2e7] transition-colors cursor-pointer flex items-center justify-center text-xs shadow-2xs whitespace-nowrap shrink-0"
                            title="Ajouter 10 unités pour réapprovisionner"
                          >
                            +10 Réappro
                          </button>
                        </div>
                      </div>
                    )}
                  </div>

                  {/* Price & Action Section with >= 44x44px touch targets (Fitts's Law) */}
                  <div className="pt-3 border-t border-[#e7ddca] flex flex-wrap sm:flex-nowrap items-center justify-between gap-2 min-w-0">
                    <div className="min-w-0">
                      <div className="text-base font-black text-[#234931] font-mono leading-tight truncate">
                        {formatMoney(product.price)}
                      </div>
                      <div className="text-[10px] text-[#877a6b] font-medium truncate">
                        {product.taxRate > 0 ? `TVA ${Math.round(product.taxRate * 100)}%` : 'Exonéré TVA'}
                      </div>
                    </div>

                    {/* Cart Controls with accessible touch targets (all >= 44x44px) */}
                    {inCartQty > 0 ? (
                      <div className="inline-flex items-center bg-[#faeee2] border border-[#f0d4ba] rounded-2xl overflow-hidden p-0.5 shadow-2xs shrink-0">
                        <button
                          type="button"
                          onClick={() => decrementQuantity(product.id)}
                          aria-label={`Retirer une unité de ${product.name}`}
                          className="touch-btn w-11 h-11 min-w-[44px] min-h-[44px] flex items-center justify-center text-[#85522b] hover:bg-[#f0d4ba] active:bg-[#e4be9c] rounded-xl font-bold text-base transition-colors cursor-pointer"
                        >
                          -
                        </button>
                        <span className="w-9 text-center font-black text-xs text-[#482611] font-mono">
                          {inCartQty}
                        </span>
                        <button
                          type="button"
                          onClick={() => incrementQuantity(product.id)}
                          disabled={inCartQty >= product.stock}
                          aria-label={`Ajouter une unité de ${product.name}`}
                          className="touch-btn w-11 h-11 min-w-[44px] min-h-[44px] flex items-center justify-center text-[#85522b] hover:bg-[#f0d4ba] active:bg-[#e4be9c] disabled:opacity-40 disabled:hover:bg-transparent rounded-xl font-bold text-base transition-colors cursor-pointer"
                        >
                          +
                        </button>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => addToCart(product, 1)}
                        disabled={isOutOfStock}
                        aria-label={`Ajouter ${product.name} au panier`}
                        className={`touch-btn min-h-[44px] min-w-[44px] inline-flex items-center justify-center gap-2 px-4 py-2.5 rounded-2xl text-xs font-bold transition-all cursor-pointer shadow-xs shrink-0 ${
                          isOutOfStock
                            ? 'bg-[#e2d7c2] text-[#877a6b] cursor-not-allowed'
                            : 'sherwood-btn-forest'
                        }`}
                      >
                        <ShoppingCart className="w-4 h-4 shrink-0" />
                        <span>Ajouter</span>
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Mobile Floating Cart Summary Bar (Consistent with Caisse POS) */}
      {cart.length > 0 && (
        <div className="lg:hidden sticky bottom-1 sm:bottom-2 z-30 pt-2 animate-in slide-in-from-bottom-2 duration-200">
          <div className="bg-[#1f3d29] text-[#fdfbf7] p-3 sm:p-3.5 rounded-2xl shadow-xl border border-[#2d563a] flex items-center justify-between gap-3">
            <div className="flex items-center gap-2.5 sm:gap-3 min-w-0">
              <div className="relative p-2 bg-[#8d5732] rounded-xl text-[#fcdbb6] shadow-xs shrink-0">
                <ShoppingCart className="w-4 h-4 sm:w-5 sm:h-5" />
                <span className="absolute -top-1.5 -right-1.5 bg-[#dc2626] text-white text-[10px] font-black w-4.5 h-4.5 rounded-full flex items-center justify-center border-2 border-[#1f3d29]">
                  {cartSummary.totalItems}
                </span>
              </div>
              <div className="min-w-0">
                <div className="text-[11px] text-[#c5ddc5] font-semibold truncate">
                  {cartSummary.uniqueCount} réf. • Total Commande
                </div>
                <div className="text-base sm:text-lg font-black font-mono text-[#86efac]">
                  {formatMoney(cartSummary.totalTTC)}
                </div>
              </div>
            </div>

            <div className="flex items-center gap-2 shrink-0">
              <button
                type="button"
                onClick={() => setIsCartDrawerOpen(true)}
                className="touch-btn min-h-[44px] px-3.5 sm:px-4 py-2 bg-[#fdfbf7] text-[#1f3d29] hover:bg-white rounded-xl text-xs font-black shadow-md flex items-center gap-1.5 cursor-pointer active:scale-95 transition-all"
              >
                <span>Voir Panier</span>
                <span className="text-xs">🍃</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Edit Product Modal */}
      {editingProduct && (
        <ProductModal
          product={editingProduct}
          categories={categories}
          onClose={() => setEditingProduct(null)}
          onSave={(updated) => {
            updateProduct(updated as Product);
            setEditingProduct(null);
          }}
        />
      )}

      {/* Create New Product Modal */}
      {isCreatingNew && (
        <ProductModal
          categories={categories}
          onClose={() => setIsCreatingNew(false)}
          onSave={(newProd) => {
            addProduct(newProd as any);
            setIsCreatingNew(false);
          }}
        />
      )}

      {/* Camera-based Barcode Scanner Overlay Modal */}
      <CameraBarcodeScannerModal
        isOpen={isCameraScannerOpen}
        onClose={() => setIsCameraScannerOpen(false)}
        onSelectProduct={(prod) => {
          setSearchQuery(prod.barcode);
          setSelectedCategoryId('ALL');
          setStockFilter('ALL');
        }}
      />
    </div>
  );
};

// Modal for Adding or Editing Product
interface ProductModalProps {
  product?: Product;
  categories: { id: number; name: string }[];
  onClose: () => void;
  onSave: (product: Product | Omit<Product, 'id'>) => void;
}

const ProductModal: React.FC<ProductModalProps> = ({
  product,
  categories,
  onClose,
  onSave,
}) => {
  const [name, setName] = useState(product?.name || '');
  const [sku, setSku] = useState(product?.sku || `REF-${Math.floor(1000 + Math.random() * 9000)}`);
  const [categoryId, setCategoryId] = useState<number>(product?.categoryId || categories[0]?.id || 1);
  const [price, setPrice] = useState<number>(product?.price || 100);
  const [costPrice, setCostPrice] = useState<number>(product?.costPrice || 70);
  const [stock, setStock] = useState<number>(product?.stock || 50);
  const [lowStockThreshold, setLowStockThreshold] = useState<number>(product?.lowStockThreshold || 10);
  const [taxRate, setTaxRate] = useState<number>(product?.taxRate ?? 0.19);
  const [barcode, setBarcode] = useState(product?.barcode || `613000${Math.floor(100000 + Math.random() * 900000)}`);
  const [description, setDescription] = useState(product?.description || '');
  const [imageUrl, setImageUrl] = useState(product?.imageUrl || '');

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    const data = {
      ...(product ? { id: product.id } : {}),
      name: name.trim(),
      sku: sku.trim(),
      categoryId,
      price: Number(price),
      costPrice: Number(costPrice),
      stock: Number(stock),
      lowStockThreshold: Number(lowStockThreshold),
      taxRate: Number(taxRate),
      barcode: barcode.trim(),
      description: description.trim() || undefined,
      imageUrl: imageUrl.trim() || undefined,
      isActive: true,
    };

    onSave(data as any);
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start sm:items-center justify-center bg-black/60 backdrop-blur-xs p-4 overflow-y-auto">
      <div className="sherwood-panel w-full max-w-lg p-0 overflow-hidden shadow-2xl my-8">
        <div className="px-6 py-4 bg-[#1f3d29] text-white flex items-center justify-between">
          <h3 className="font-serif-title font-black text-sm flex items-center gap-2">
            <Package className="w-4 h-4 text-emerald-300" />
            <span>{product ? 'Modifier le Produit' : 'Ajouter un Nouveau Produit'}</span>
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="text-[#c7dac7] hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-bold text-[#483d31] mb-1">
              Nom du produit *
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex: Coca-Cola 33cl"
              className="w-full px-3 py-2 sherwood-input text-sm"
            />
          </div>

          <div className="grid grid-cols-1 min-[420px]:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Référence SKU
              </label>
              <input
                type="text"
                required
                value={sku}
                onChange={(e) => setSku(e.target.value)}
                className="w-full px-3 py-2 sherwood-input text-sm font-mono uppercase"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Catégorie / Rayon
              </label>
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-bold"
              >
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 min-[420px]:grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Prix Vente (DA) *
              </label>
              <input
                type="number"
                min="0"
                step="any"
                required
                value={price}
                onChange={(e) => setPrice(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-black text-[#234931] font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Coût Achat (DA)
              </label>
              <input
                type="number"
                min="0"
                step="any"
                value={costPrice}
                onChange={(e) => setCostPrice(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Taux TVA
              </label>
              <select
                value={taxRate}
                onChange={(e) => setTaxRate(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-bold"
              >
                <option value={0.19}>19% (Standard)</option>
                <option value={0.09}>9% (Réduit)</option>
                <option value={0.0}>0% (Exonéré)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-1 min-[420px]:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Quantité en Stock
              </label>
              <input
                type="number"
                min="0"
                required
                value={stock}
                onChange={(e) => setStock(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-bold font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Seuil Alerte Stock
              </label>
              <input
                type="number"
                min="0"
                value={lowStockThreshold}
                onChange={(e) => setLowStockThreshold(Number(e.target.value))}
                className="w-full px-3 py-2 sherwood-input text-sm font-mono"
              />
            </div>
          </div>

          <div className="grid grid-cols-1 min-[420px]:grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                Code-barres EAN
              </label>
              <input
                type="text"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                className="w-full px-3 py-2 sherwood-input text-sm font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-bold text-[#483d31] mb-1">
                URL Image (optionnel)
              </label>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://..."
                className="w-full px-3 py-2 sherwood-input text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-bold text-[#483d31] mb-1">
              Description / Notes
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Spécifications, contenance, saveur..."
              className="w-full px-3 py-2 sherwood-input text-sm"
            />
          </div>

          <div className="pt-4 border-t border-[#e7ddca] flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="touch-btn px-4 py-2 sherwood-btn-outline text-xs font-bold"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="touch-btn px-5 py-2 sherwood-btn-forest text-xs font-bold shadow-xs"
            >
              {product ? 'Enregistrer les modifications' : 'Créer le produit'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
