import React from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  LayoutDashboard,
  Store,
  Package,
  Receipt,
  ShoppingCart,
  Cloud,
} from 'lucide-react';

export const MobileBottomNav: React.FC = () => {
  const { activeView, setActiveView, cartSummary, setIsCartDrawerOpen } = usePos();

  return (
    <nav className="md:hidden fixed bottom-0 left-0 right-0 z-40 bg-white/95 backdrop-blur-xl border-t border-slate-200/80 px-1 py-1 shadow-lg flex items-center justify-around">
      <button
        type="button"
        onClick={() => setActiveView('dashboard')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'dashboard' ? 'text-indigo-600 font-bold' : 'text-slate-500'
        }`}
      >
        <LayoutDashboard className="w-5 h-5" />
        <span className="text-[10px]">Dashboard</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('pos')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'pos' ? 'text-indigo-600 font-bold' : 'text-slate-500'
        }`}
      >
        <Store className="w-5 h-5" />
        <span className="text-[10px]">Caisse</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('catalog')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'catalog' ? 'text-indigo-600 font-bold' : 'text-slate-500'
        }`}
      >
        <Package className="w-5 h-5" />
        <span className="text-[10px]">Catalogue</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('sales')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'sales' ? 'text-indigo-600 font-bold' : 'text-slate-500'
        }`}
      >
        <Receipt className="w-5 h-5" />
        <span className="text-[10px]">Factures</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('admin')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'admin' ? 'text-indigo-600 font-bold' : 'text-slate-500'
        }`}
      >
        <Cloud className="w-5 h-5" />
        <span className="text-[10px]">Sync</span>
      </button>

      <button
        type="button"
        onClick={() => setIsCartDrawerOpen(true)}
        className="touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 relative text-slate-500 rounded-xl transition-colors cursor-pointer hover:text-indigo-600"
      >
        <div className="relative">
          <ShoppingCart className="w-5 h-5" />
          {cartSummary.totalItems > 0 && (
            <span className="absolute -top-1.5 -right-2 bg-indigo-600 text-white font-black text-[9px] w-4 h-4 rounded-full flex items-center justify-center">
              {cartSummary.totalItems}
            </span>
          )}
        </div>
        <span className="text-[10px]">Panier</span>
      </button>
    </nav>
  );
};
