import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Product } from '../../types';
import {
  AlertTriangle,
  XCircle,
  PackageCheck,
  PackagePlus,
  Sliders,
  Filter,
  Package,
  ArrowRight,
  TrendingDown,
  Layers,
  Sparkles,
} from 'lucide-react';

export const InventoryAlertWidget: React.FC = () => {
  const { products, categories, updateProduct, setActiveView } = usePos();

  // Configurable minimum stock threshold (persisted in localStorage or default to 10)
  const [minThreshold, setMinThreshold] = useState<number>(() => {
    try {
      const saved = localStorage.getItem('pos_inventory_min_threshold_v1');
      return saved ? Number(saved) : 10;
    } catch {
      return 10;
    }
  });

  const [activeFilter, setActiveFilter] = useState<'ALL' | 'OUT_OF_STOCK' | 'LOW_STOCK'>('ALL');
  const [restockSuccessId, setRestockSuccessId] = useState<number | null>(null);

  const handleThresholdChange = (val: number) => {
    const clamped = Math.max(1, Math.min(100, val));
    setMinThreshold(clamped);
    try {
      localStorage.setItem('pos_inventory_min_threshold_v1', String(clamped));
    } catch {}
  };

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Compute flagged products based on the configurable threshold
  const flaggedProducts = useMemo(() => {
    return products.filter((p) => {
      // Flag if product stock is below the user's configurable threshold OR its own lowStockThreshold
      const effectiveThreshold = Math.max(minThreshold, p.lowStockThreshold);
      return p.stock <= effectiveThreshold && p.isActive;
    });
  }, [products, minThreshold]);

  // Filter flagged items by severity
  const filteredItems = useMemo(() => {
    if (activeFilter === 'OUT_OF_STOCK') {
      return flaggedProducts.filter((p) => p.stock === 0);
    }
    if (activeFilter === 'LOW_STOCK') {
      return flaggedProducts.filter((p) => p.stock > 0);
    }
    return flaggedProducts;
  }, [flaggedProducts, activeFilter]);

  // Quick re-stock handler
  const handleRestock = (product: Product, addedQuantity: number) => {
    const updated = {
      ...product,
      stock: product.stock + addedQuantity,
    };
    updateProduct(updated);
    setRestockSuccessId(product.id);
    setTimeout(() => setRestockSuccessId(null), 1800);
  };

  const outOfStockCount = flaggedProducts.filter((p) => p.stock === 0).length;
  const lowStockCount = flaggedProducts.filter((p) => p.stock > 0).length;

  // Estimated restock cost (cost price * units to reach 2x threshold)
  const estimatedRestockCost = flaggedProducts.reduce((sum, p) => {
    const needed = Math.max(0, minThreshold * 2 - p.stock);
    return sum + needed * p.costPrice;
  }, 0);

  return (
    <div className="bg-white/90 backdrop-blur-xl rounded-3xl p-5 sm:p-6 border border-white shadow-xs space-y-5">
      {/* Widget Header with Status and Config Toggle */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold shrink-0">
            <AlertTriangle className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-base sm:text-lg text-slate-900">
                Surveillance de l'Inventaire & Alertes Seuil
              </h3>
              <span className="px-2 py-0.5 rounded-full text-[11px] font-bold bg-amber-100 text-amber-800">
                {flaggedProducts.length} sous le seuil
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-0.5">
              Articles dont le niveau de stock requiert un réapprovisionnement
            </p>
          </div>
        </div>

        {/* Configurable Minimum Stock Threshold Controller */}
        <div className="bg-slate-50 p-2.5 rounded-2xl border border-slate-200/80 flex flex-wrap items-center gap-3">
          <div className="flex items-center gap-2">
            <Sliders className="w-3.5 h-3.5 text-slate-500" />
            <span className="text-xs font-semibold text-slate-700">Seuil Minimal :</span>
            <input
              type="number"
              min="1"
              max="100"
              value={minThreshold}
              onChange={(e) => handleThresholdChange(Number(e.target.value))}
              className="w-14 px-2 py-1 bg-white border border-slate-300 rounded-lg text-xs font-bold text-center text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-amber-500/20"
            />
            <span className="text-xs text-slate-500">unités</span>
          </div>

          {/* Quick preset buttons */}
          <div className="flex items-center gap-1">
            {[5, 10, 15, 25].map((val) => (
              <button
                key={val}
                type="button"
                onClick={() => handleThresholdChange(val)}
                className={`px-2 py-1 rounded-lg text-[11px] font-bold transition-colors cursor-pointer ${
                  minThreshold === val
                    ? 'bg-amber-600 text-white shadow-2xs'
                    : 'bg-white border border-slate-200 text-slate-600 hover:bg-slate-100'
                }`}
              >
                {val}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Filter Tabs & Quick Metrics Bar */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        {/* Severity Tabs */}
        <div className="flex items-center gap-1.5 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setActiveFilter('ALL')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer ${
              activeFilter === 'ALL'
                ? 'bg-slate-900 text-white border-slate-900 shadow-2xs'
                : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
            }`}
          >
            Tous les alertés ({flaggedProducts.length})
          </button>
          <button
            type="button"
            onClick={() => setActiveFilter('OUT_OF_STOCK')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer flex items-center gap-1.5 ${
              activeFilter === 'OUT_OF_STOCK'
                ? 'bg-rose-600 text-white border-rose-600 shadow-2xs'
                : 'bg-white text-rose-700 border-rose-200 hover:bg-rose-50'
            }`}
          >
            <XCircle className="w-3.5 h-3.5 text-rose-500" />
            Ruptures ({outOfStockCount})
          </button>
          <button
            type="button"
            onClick={() => setActiveFilter('LOW_STOCK')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer flex items-center gap-1.5 ${
              activeFilter === 'LOW_STOCK'
                ? 'bg-amber-600 text-white border-amber-600 shadow-2xs'
                : 'bg-white text-amber-700 border-amber-200 hover:bg-amber-50'
            }`}
          >
            <AlertTriangle className="w-3.5 h-3.5 text-amber-500" />
            Stock Faible ({lowStockCount})
          </button>
        </div>

        {/* Cost estimate pill */}
        <div className="text-xs text-slate-500 flex items-center gap-1.5">
          <span>Besoin de réappro. estimé :</span>
          <span className="font-extrabold text-slate-800 font-mono">
            {formatMoney(estimatedRestockCost)}
          </span>
        </div>
      </div>

      {/* Flagged Items Grid / List */}
      {filteredItems.length === 0 ? (
        <div className="p-8 bg-emerald-50/60 rounded-2xl border border-emerald-200/80 text-center space-y-2">
          <div className="w-12 h-12 rounded-full bg-emerald-100 text-emerald-600 flex items-center justify-center mx-auto">
            <PackageCheck className="w-6 h-6" />
          </div>
          <h4 className="font-bold text-sm text-emerald-950">
            Tous les stocks sont au-dessus du seuil !
          </h4>
          <p className="text-xs text-emerald-700 max-w-md mx-auto">
            Aucun article ne nécessite de réapprovisionnement immédiat avec le seuil configuré de{' '}
            <strong>{minThreshold} unités</strong>.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-3.5 max-h-[380px] overflow-y-auto pr-1">
          {filteredItems.map((product) => {
            const isOut = product.stock <= 0;
            const category = categories.find((c) => c.id === product.categoryId);
            const isJustRestocked = restockSuccessId === product.id;
            const percentRemaining = Math.min(
              100,
              Math.round((product.stock / minThreshold) * 100)
            );

            return (
              <div
                key={product.id}
                className={`p-3.5 rounded-2xl border transition-all flex flex-col justify-between bg-white relative ${
                  isJustRestocked
                    ? 'ring-2 ring-emerald-500 border-emerald-500'
                    : isOut
                    ? 'border-rose-200/90 shadow-2xs hover:border-rose-400'
                    : 'border-amber-200/90 shadow-2xs hover:border-amber-400'
                }`}
              >
                <div>
                  <div className="flex items-start justify-between gap-2">
                    <div className="flex-1 min-w-0">
                      <div className="flex items-center gap-1.5 mb-1">
                        {isOut ? (
                          <span className="px-2 py-0.5 rounded-md text-[10px] font-black uppercase bg-rose-100 text-rose-700 flex items-center gap-1">
                            <XCircle className="w-3 h-3" />
                            Rupture
                          </span>
                        ) : (
                          <span className="px-2 py-0.5 rounded-md text-[10px] font-black uppercase bg-amber-100 text-amber-800 flex items-center gap-1">
                            <AlertTriangle className="w-3 h-3" />
                            Alerte ({product.stock}/{minThreshold})
                          </span>
                        )}
                        {category && (
                          <span className="text-[10px] text-slate-400 truncate">
                            {category.name}
                          </span>
                        )}
                      </div>

                      <h4 className="font-bold text-xs text-slate-900 line-clamp-1" title={product.name}>
                        {product.name}
                      </h4>
                      <div className="text-[10px] font-mono text-slate-400 mt-0.5">
                        {product.sku} • {product.barcode}
                      </div>
                    </div>

                    <div className="text-right shrink-0">
                      <div className="text-xs font-black text-slate-900">
                        {product.stock}{' '}
                        <span className="text-[10px] font-normal text-slate-500">en stock</span>
                      </div>
                      <div className="text-[10px] text-slate-400 font-mono">
                        P.A: {formatMoney(product.costPrice)}
                      </div>
                    </div>
                  </div>

                  {/* Stock Level Progress Indicator */}
                  <div className="mt-2.5 space-y-1">
                    <div className="w-full bg-slate-100 rounded-full h-1.5 overflow-hidden">
                      <div
                        className={`h-full rounded-full transition-all duration-300 ${
                          isOut ? 'bg-rose-500 w-0' : 'bg-amber-500'
                        }`}
                        style={{ width: `${percentRemaining}%` }}
                      ></div>
                    </div>
                  </div>
                </div>

                {/* Quick Restock Buttons */}
                <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between gap-2">
                  <span className="text-[10px] font-semibold text-slate-400">
                    Réappro rapide :
                  </span>

                  <div className="flex items-center gap-1.5">
                    <button
                      type="button"
                      onClick={() => handleRestock(product, 10)}
                      className="touch-btn px-2.5 py-1 bg-slate-100 hover:bg-indigo-50 hover:text-indigo-700 text-slate-700 border border-slate-200 rounded-lg text-[11px] font-bold transition-colors cursor-pointer"
                      title="Ajouter 10 unités au stock"
                    >
                      +10
                    </button>
                    <button
                      type="button"
                      onClick={() => handleRestock(product, 50)}
                      className="touch-btn px-2.5 py-1 bg-slate-100 hover:bg-indigo-50 hover:text-indigo-700 text-slate-700 border border-slate-200 rounded-lg text-[11px] font-bold transition-colors cursor-pointer"
                      title="Ajouter 50 unités au stock"
                    >
                      +50
                    </button>
                  </div>
                </div>
              </div>
            );
          })}
        </div>
      )}

      {/* Widget Footer */}
      <div className="pt-2 border-t border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-3 text-xs">
        <div className="text-slate-500 text-[11px]">
          Mise à jour en temps réel à chaque encaissement ou modification de stock.
        </div>
        <button
          type="button"
          onClick={() => setActiveView('catalog')}
          className="font-bold text-indigo-600 hover:text-indigo-800 flex items-center gap-1 cursor-pointer"
        >
          Ouvrir tout le Catalogue des Produits
          <ArrowRight className="w-3.5 h-3.5" />
        </button>
      </div>
    </div>
  );
};
