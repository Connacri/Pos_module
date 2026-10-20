import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Product } from '../../types';
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
} from 'lucide-react';

export const ProductCatalogView: React.FC = () => {
  const {
    products,
    categories,
    cart,
    addToCart,
    incrementQuantity,
    decrementQuantity,
    updateProduct,
    addProduct,
    setActiveView,
  } = usePos();

  // Search & Filter state
  const [searchQuery, setSearchQuery] = useState('');
  const [selectedCategoryId, setSelectedCategoryId] = useState<number | 'ALL'>('ALL');
  const [stockFilter, setStockFilter] = useState<'ALL' | 'IN_STOCK' | 'LOW_STOCK' | 'OUT_OF_STOCK'>('ALL');
  const [sortBy, setSortBy] = useState<'name' | 'price-asc' | 'price-desc' | 'stock'>('name');

  // Modal states
  const [editingProduct, setEditingProduct] = useState<Product | null>(null);
  const [isCreatingNew, setIsCreatingNew] = useState(false);

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
    <div className="space-y-6">
      {/* Top Header & Quick Actions */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs">
        <div>
          <h2 className="text-xl font-bold text-slate-800 flex items-center gap-2">
            <Package className="w-6 h-6 text-indigo-600" />
            Catalogue des Produits
          </h2>
          <p className="text-xs text-slate-500 mt-0.5">
            Gérez vos références, suivez les stocks en temps réel et alimentez le panier POS
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setIsCreatingNew(true)}
            className="inline-flex items-center gap-2 px-4 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors cursor-pointer"
          >
            <Plus className="w-4 h-4" />
            Nouveau Produit
          </button>

          {cart.length > 0 && (
            <button
              type="button"
              onClick={() => setActiveView('pos')}
              className="inline-flex items-center gap-2 px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors cursor-pointer"
            >
              <ShoppingCart className="w-4 h-4 text-emerald-400" />
              Voir Panier ({cart.reduce((sum, item) => sum + item.quantity, 0)})
            </button>
          )}
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white p-4 rounded-2xl border border-slate-200/80 shadow-xs space-y-4">
        {/* Row 1: Search + Sort + Stock Filter */}
        <div className="flex flex-col lg:flex-row items-stretch lg:items-center gap-3">
          {/* Search Input */}
          <div className="relative flex-1">
            <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              placeholder="Rechercher par nom, SKU (ex: REF-0001) ou code-barres..."
              className="w-full pl-10 pr-9 py-2 bg-slate-50 border border-slate-200 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500 text-slate-800 placeholder:text-slate-400"
            />
            {searchQuery && (
              <button
                type="button"
                onClick={() => setSearchQuery('')}
                className="absolute right-3 top-1/2 -translate-y-1/2 text-slate-400 hover:text-slate-600"
              >
                <X className="w-4 h-4" />
              </button>
            )}
          </div>

          {/* Stock status filter pills */}
          <div className="flex items-center gap-1.5 overflow-x-auto pb-1 lg:pb-0 text-xs font-medium">
            <button
              type="button"
              onClick={() => setStockFilter('ALL')}
              className={`px-3 py-1.5 rounded-lg border transition-all ${
                stockFilter === 'ALL'
                  ? 'bg-slate-900 text-white border-slate-900'
                  : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
              }`}
            >
              Tous ({stockCounts.total})
            </button>
            <button
              type="button"
              onClick={() => setStockFilter('IN_STOCK')}
              className={`px-3 py-1.5 rounded-lg border transition-all flex items-center gap-1.5 ${
                stockFilter === 'IN_STOCK'
                  ? 'bg-emerald-600 text-white border-emerald-600'
                  : 'bg-white text-emerald-700 border-emerald-200 hover:bg-emerald-50'
              }`}
            >
              <span className="w-2 h-2 rounded-full bg-emerald-400 inline-block"></span>
              En stock ({stockCounts.inStock})
            </button>
            <button
              type="button"
              onClick={() => setStockFilter('LOW_STOCK')}
              className={`px-3 py-1.5 rounded-lg border transition-all flex items-center gap-1.5 ${
                stockFilter === 'LOW_STOCK'
                  ? 'bg-amber-600 text-white border-amber-600'
                  : 'bg-white text-amber-700 border-amber-200 hover:bg-amber-50'
              }`}
            >
              <AlertTriangle className="w-3 h-3 text-amber-500" />
              Alerte stock ({stockCounts.lowStock})
            </button>
            <button
              type="button"
              onClick={() => setStockFilter('OUT_OF_STOCK')}
              className={`px-3 py-1.5 rounded-lg border transition-all flex items-center gap-1.5 ${
                stockFilter === 'OUT_OF_STOCK'
                  ? 'bg-rose-600 text-white border-rose-600'
                  : 'bg-white text-rose-700 border-rose-200 hover:bg-rose-50'
              }`}
            >
              <XCircle className="w-3 h-3 text-rose-500" />
              Rupture ({stockCounts.outOfStock})
            </button>
          </div>

          {/* Sort Selector */}
          <div className="flex items-center gap-2 self-end lg:self-auto min-w-[170px]">
            <ArrowUpDown className="w-4 h-4 text-slate-400 shrink-0" />
            <select
              value={sortBy}
              onChange={(e) => setSortBy(e.target.value as any)}
              className="w-full bg-slate-50 border border-slate-200 rounded-xl px-2.5 py-2 text-xs font-medium text-slate-700 focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20"
            >
              <option value="name">Nom (A → Z)</option>
              <option value="price-asc">Prix (Croissant)</option>
              <option value="price-desc">Prix (Décroissant)</option>
              <option value="stock">Quantité en stock</option>
            </select>
          </div>
        </div>

        {/* Row 2: Category Filter Tabs */}
        <div className="flex items-center gap-2 overflow-x-auto pb-1 pt-1 border-t border-slate-100">
          <span className="text-xs text-slate-400 font-medium shrink-0 flex items-center gap-1 mr-1">
            <Filter className="w-3.5 h-3.5" />
            Rayon:
          </span>
          <button
            type="button"
            onClick={() => setSelectedCategoryId('ALL')}
            className={`px-3 py-1.5 rounded-xl text-xs font-medium whitespace-nowrap transition-colors ${
              selectedCategoryId === 'ALL'
                ? 'bg-indigo-50 text-indigo-700 border border-indigo-200 font-semibold'
                : 'text-slate-600 hover:bg-slate-100'
            }`}
          >
            Toutes les catégories
          </button>
          {categories.map((cat) => {
            const count = products.filter((p) => p.categoryId === cat.id).length;
            const isSelected = selectedCategoryId === cat.id;
            return (
              <button
                key={cat.id}
                type="button"
                onClick={() => setSelectedCategoryId(cat.id)}
                className={`px-3 py-1.5 rounded-xl text-xs font-medium whitespace-nowrap transition-colors flex items-center gap-1.5 ${
                  isSelected
                    ? 'bg-indigo-600 text-white font-semibold shadow-xs'
                    : 'bg-slate-50 text-slate-600 hover:bg-slate-100 border border-slate-200/60'
                }`}
              >
                <span>{cat.name}</span>
                <span
                  className={`text-[10px] px-1.5 py-0.2 rounded-full ${
                    isSelected ? 'bg-indigo-700 text-white' : 'bg-slate-200 text-slate-700'
                  }`}
                >
                  {count}
                </span>
              </button>
            );
          })}
        </div>
      </div>

      {/* Responsive Products Grid */}
      {filteredProducts.length === 0 ? (
        <div className="bg-white rounded-2xl p-12 text-center border border-slate-200/80 shadow-xs">
          <div className="w-16 h-16 mx-auto mb-4 bg-slate-100 rounded-full flex items-center justify-center text-slate-400">
            <Package className="w-8 h-8" />
          </div>
          <h3 className="text-base font-bold text-slate-800 mb-1">
            Aucun article correspondant
          </h3>
          <p className="text-xs text-slate-500 max-w-sm mx-auto mb-4">
            Modifiez votre recherche ou réinitialisez les filtres pour afficher des produits.
          </p>
          <button
            type="button"
            onClick={() => {
              setSearchQuery('');
              setSelectedCategoryId('ALL');
              setStockFilter('ALL');
            }}
            className="px-4 py-2 bg-slate-100 hover:bg-slate-200 text-slate-700 text-xs font-semibold rounded-xl transition-colors cursor-pointer"
          >
            Réinitialiser les filtres
          </button>
        </div>
      ) : (
        <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 lg:grid-cols-4 xl:grid-cols-5 gap-4">
          {filteredProducts.map((product) => {
            const inCartQty = cartQuantityMap.get(product.id) || 0;
            const category = categories.find((c) => c.id === product.categoryId);
            const isOutOfStock = product.stock <= 0;
            const isLowStock = !isOutOfStock && product.stock <= product.lowStockThreshold;

            return (
              <div
                key={product.id}
                className="bg-white rounded-2xl border border-slate-200/80 shadow-xs hover:shadow-md hover:border-indigo-200 transition-all flex flex-col overflow-hidden group"
              >
                {/* Product Image & Badges */}
                <div className="relative aspect-4/3 bg-slate-100 overflow-hidden">
                  {product.imageUrl ? (
                    <img
                      src={product.imageUrl}
                      alt={product.name}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-300"
                      loading="lazy"
                    />
                  ) : (
                    <div className="w-full h-full flex items-center justify-center text-slate-300">
                      <Package className="w-12 h-12" />
                    </div>
                  )}

                  {/* Top Badges */}
                  <div className="absolute top-2 left-2 flex flex-col gap-1">
                    <span className="bg-slate-900/80 backdrop-blur-xs text-white text-[10px] font-mono px-2 py-0.5 rounded-md">
                      {product.sku}
                    </span>
                    {category && (
                      <span className="bg-white/90 backdrop-blur-xs text-slate-700 text-[10px] font-medium px-2 py-0.5 rounded-md shadow-xs">
                        {category.name}
                      </span>
                    )}
                  </div>

                  {/* Edit button */}
                  <button
                    type="button"
                    onClick={() => setEditingProduct(product)}
                    className="absolute top-2 right-2 w-7 h-7 bg-white/90 hover:bg-white text-slate-600 hover:text-indigo-600 rounded-full flex items-center justify-center shadow-xs transition-colors cursor-pointer"
                    title="Modifier l'article"
                  >
                    <Edit2 className="w-3.5 h-3.5" />
                  </button>

                  {/* In Cart Indicator */}
                  {inCartQty > 0 && (
                    <div className="absolute bottom-2 left-2 bg-indigo-600 text-white text-[11px] font-bold px-2 py-0.5 rounded-lg shadow-sm flex items-center gap-1">
                      <Check className="w-3 h-3" />
                      {inCartQty} au panier
                    </div>
                  )}
                </div>

                {/* Content */}
                <div className="p-3.5 flex-1 flex flex-col justify-between">
                  <div>
                    <h4 className="font-semibold text-sm text-slate-800 line-clamp-1 group-hover:text-indigo-600 transition-colors" title={product.name}>
                      {product.name}
                    </h4>
                    {product.description && (
                      <p className="text-[11px] text-slate-500 line-clamp-1 mt-0.5" title={product.description}>
                        {product.description}
                      </p>
                    )}

                    {/* Stock Status Pill */}
                    <div className="mt-2.5 flex items-center justify-between text-xs">
                      {isOutOfStock ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-rose-600 bg-rose-50 px-2 py-0.5 rounded-md">
                          <XCircle className="w-3 h-3" />
                          Rupture
                        </span>
                      ) : isLowStock ? (
                        <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-amber-700 bg-amber-50 px-2 py-0.5 rounded-md">
                          <AlertTriangle className="w-3 h-3 text-amber-500" />
                          Reste {product.stock} (Alerte)
                        </span>
                      ) : (
                        <span className="inline-flex items-center gap-1 text-[11px] font-medium text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
                          <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                          Stock: {product.stock}
                        </span>
                      )}

                      <span className="text-[10px] text-slate-400 font-mono flex items-center gap-1">
                        <Barcode className="w-3 h-3" />
                        {product.barcode.slice(-4)}
                      </span>
                    </div>
                  </div>

                  {/* Price & Action Section */}
                  <div className="mt-4 pt-3 border-t border-slate-100 flex items-center justify-between gap-2">
                    <div>
                      <div className="text-base font-extrabold text-slate-900 leading-tight">
                        {formatMoney(product.price)}
                      </div>
                      <div className="text-[10px] text-slate-400">
                        {product.taxRate > 0 ? `TVA ${Math.round(product.taxRate * 100)}% incluse` : 'Exonéré TVA'}
                      </div>
                    </div>

                    {/* Cart Controls */}
                    {inCartQty > 0 ? (
                      <div className="inline-flex items-center bg-indigo-50 border border-indigo-200 rounded-xl overflow-hidden p-0.5">
                        <button
                          type="button"
                          onClick={() => decrementQuantity(product.id)}
                          className="w-7 h-7 flex items-center justify-center text-indigo-700 hover:bg-indigo-100 rounded-lg font-bold text-xs transition-colors cursor-pointer"
                        >
                          -
                        </button>
                        <span className="w-7 text-center font-bold text-xs text-indigo-900">
                          {inCartQty}
                        </span>
                        <button
                          type="button"
                          onClick={() => incrementQuantity(product.id)}
                          disabled={inCartQty >= product.stock}
                          className="w-7 h-7 flex items-center justify-center text-indigo-700 hover:bg-indigo-100 disabled:opacity-40 disabled:hover:bg-transparent rounded-lg font-bold text-xs transition-colors cursor-pointer"
                        >
                          +
                        </button>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => addToCart(product, 1)}
                        disabled={isOutOfStock}
                        className={`inline-flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold transition-all cursor-pointer ${
                          isOutOfStock
                            ? 'bg-slate-100 text-slate-400 cursor-not-allowed'
                            : 'bg-indigo-600 hover:bg-indigo-700 text-white shadow-xs active:scale-95'
                        }`}
                      >
                        <ShoppingCart className="w-3.5 h-3.5" />
                        Ajouter
                      </button>
                    )}
                  </div>
                </div>
              </div>
            );
          })}
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4 overflow-y-auto">
      <div className="bg-white w-full max-w-lg rounded-2xl shadow-2xl border border-slate-200 overflow-hidden my-8">
        <div className="px-6 py-4 bg-slate-900 text-white flex items-center justify-between">
          <h3 className="font-bold text-sm flex items-center gap-2">
            <Package className="w-4 h-4 text-indigo-400" />
            {product ? 'Modifier le Produit' : 'Ajouter un Nouveau Produit'}
          </h3>
          <button
            type="button"
            onClick={onClose}
            className="text-slate-400 hover:text-white transition-colors cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        <form onSubmit={handleSubmit} className="p-6 space-y-4">
          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Nom du produit *
            </label>
            <input
              type="text"
              required
              value={name}
              onChange={(e) => setName(e.target.value)}
              placeholder="Ex: Coca-Cola 33cl"
              className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20 focus:border-indigo-500"
            />
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Référence SKU
              </label>
              <input
                type="text"
                required
                value={sku}
                onChange={(e) => setSku(e.target.value)}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm font-mono uppercase"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Catégorie / Rayon
              </label>
              <select
                value={categoryId}
                onChange={(e) => setCategoryId(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm bg-white"
              >
                {categories.map((c) => (
                  <option key={c.id} value={c.id}>
                    {c.name}
                  </option>
                ))}
              </select>
            </div>
          </div>

          <div className="grid grid-cols-3 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Prix Vente (DA) *
              </label>
              <input
                type="number"
                min="0"
                step="any"
                required
                value={price}
                onChange={(e) => setPrice(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm font-semibold text-indigo-600"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Coût Achat (DA)
              </label>
              <input
                type="number"
                min="0"
                step="any"
                value={costPrice}
                onChange={(e) => setCostPrice(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Taux TVA
              </label>
              <select
                value={taxRate}
                onChange={(e) => setTaxRate(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm bg-white"
              >
                <option value={0.19}>19% (Standard)</option>
                <option value={0.09}>9% (Réduit)</option>
                <option value={0.0}>0% (Exonéré)</option>
              </select>
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Quantité en Stock
              </label>
              <input
                type="number"
                min="0"
                required
                value={stock}
                onChange={(e) => setStock(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm font-semibold"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Seuil Alerte Stock
              </label>
              <input
                type="number"
                min="0"
                value={lowStockThreshold}
                onChange={(e) => setLowStockThreshold(Number(e.target.value))}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
              />
            </div>
          </div>

          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                Code-barres EAN
              </label>
              <input
                type="text"
                value={barcode}
                onChange={(e) => setBarcode(e.target.value)}
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm font-mono"
              />
            </div>
            <div>
              <label className="block text-xs font-semibold text-slate-700 mb-1">
                URL Image (optionnel)
              </label>
              <input
                type="url"
                value={imageUrl}
                onChange={(e) => setImageUrl(e.target.value)}
                placeholder="https://..."
                className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
              />
            </div>
          </div>

          <div>
            <label className="block text-xs font-semibold text-slate-700 mb-1">
              Description / Notes
            </label>
            <textarea
              rows={2}
              value={description}
              onChange={(e) => setDescription(e.target.value)}
              placeholder="Spécifications, contenance, saveur..."
              className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
            />
          </div>

          <div className="pt-4 border-t border-slate-100 flex items-center justify-end gap-3">
            <button
              type="button"
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-600 hover:text-slate-800 cursor-pointer"
            >
              Annuler
            </button>
            <button
              type="submit"
              className="px-5 py-2 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-xl shadow-xs transition-colors cursor-pointer"
            >
              {product ? 'Enregistrer les modifications' : 'Créer le produit'}
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
