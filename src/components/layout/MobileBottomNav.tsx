import React from 'react';
import { usePos } from '../../context/PosContext';
import {
  Store,
  LayoutDashboard,
  Package,
  Receipt,
  ShoppingCart,
  Cloud,
} from 'lucide-react';

export const MobileBottomNav: React.FC = () => {
  const { activeView, setActiveView, cartSummary, setIsCartDrawerOpen } = usePos();

  return (
    <nav className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-[#fdfbf7]/95 backdrop-blur-xl border-t border-[#e5dcce] px-2 py-1.5 shadow-lg flex items-center justify-around">
      <button
        type="button"
        onClick={() => setActiveView('pos')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'pos' ? 'text-[#1f3d29] font-bold' : 'text-[#7d7061]'
        }`}
      >
        <Store className="w-5 h-5" />
        <span className="text-[10px]">Caisse</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('dashboard')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'dashboard' ? 'text-[#1f3d29] font-bold' : 'text-[#7d7061]'
        }`}
      >
        <LayoutDashboard className="w-5 h-5" />
        <span className="text-[10px]">Aperçu</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('catalog')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'catalog' ? 'text-[#1f3d29] font-bold' : 'text-[#7d7061]'
        }`}
      >
        <Package className="w-5 h-5" />
        <span className="text-[10px]">Catalogue</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('sales')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'sales' ? 'text-[#1f3d29] font-bold' : 'text-[#7d7061]'
        }`}
      >
        <Receipt className="w-5 h-5" />
        <span className="text-[10px]">Factures</span>
      </button>

      <button
        type="button"
        onClick={() => setActiveView('admin')}
        className={`touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
          activeView === 'admin' ? 'text-[#1f3d29] font-bold' : 'text-[#7d7061]'
        }`}
      >
        <Cloud className="w-5 h-5" />
        <span className="text-[10px]">Sync</span>
      </button>

      <button
        type="button"
        onClick={() => setIsCartDrawerOpen(true)}
        className="touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 relative text-[#7d7061] rounded-xl transition-colors cursor-pointer hover:text-[#1f3d29]"
      >
        <div className="relative">
          <ShoppingCart className="w-5 h-5" />
          {cartSummary.totalItems > 0 && (
            <span className="absolute -top-1.5 -right-2 bg-[#8d5732] text-[#fff2e2] font-black text-[9px] w-4 h-4 rounded-full flex items-center justify-center">
              {cartSummary.totalItems}
            </span>
          )}
        </div>
        <span className="text-[10px]">Panier</span>
      </button>
    </nav>
  );
};
