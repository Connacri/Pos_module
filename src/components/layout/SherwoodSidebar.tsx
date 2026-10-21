import React from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  Store,
  LayoutDashboard,
  Package,
  Receipt,
  Users,
  Cloud,
  X,
} from 'lucide-react';

interface SherwoodSidebarProps {
  isMobile?: boolean;
  onClose?: () => void;
}

export const SherwoodSidebar: React.FC<SherwoodSidebarProps> = ({ isMobile = false, onClose }) => {
  const { activeView, setActiveView } = usePos();

  const navItems: { id: ViewType; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'pos', label: 'Caisse POS', icon: Store },
    { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'catalog', label: 'Catalogue', icon: Package },
    { id: 'sales', label: 'Factures & Ventes', icon: Receipt },
    { id: 'customers', label: 'Clients', icon: Users },
    { id: 'admin', label: 'Admin & Sync', icon: Cloud },
  ];

  const handleNavClick = (id: ViewType) => {
    setActiveView(id);
    if (isMobile && onClose) {
      onClose();
    }
  };

  return (
    <aside
      className={`bg-[#1f3d29] text-[#fcfbf7] flex flex-col justify-between p-4 border-r border-[#16311f] select-none shadow-xl ${
        isMobile ? 'w-full h-full overflow-y-auto' : 'w-64 h-screen sticky top-0'
      }`}
    >
      {/* Top Section: Wooden Signboard + Navigation */}
      <div className="space-y-5">
        {/* Mobile Header with dedicated Close Button if isMobile */}
        {isMobile && (
          <div className="flex items-center justify-between pb-3 border-b border-[#2d563a]">
            <div className="flex items-center gap-2">
              <span className="text-xl">🍃</span>
              <span className="font-serif-title font-bold text-sm text-[#fff5ea] tracking-tight">Menu Sherwood</span>
            </div>
            {onClose && (
              <button
                type="button"
                onClick={onClose}
                aria-label="Fermer le menu de navigation"
                className="touch-btn min-h-[44px] min-w-[44px] p-2.5 rounded-2xl bg-white/10 hover:bg-white/20 active:bg-white/30 text-[#fdfbf7] border border-white/20 shadow-xs flex items-center justify-center transition-all cursor-pointer focus:outline-hidden focus:ring-2 focus:ring-[#86efac]"
              >
                <X className="w-5 h-5 text-white" />
              </button>
            )}
          </div>
        )}

        {/* Carved Wooden Sherwood Signboard Header */}
        <div className="pt-1 px-1">
          <div className="sherwood-wood-board rounded-2xl p-4 text-center">
            {/* Wooden Nails / Screws in 4 corners */}
            <div className="absolute top-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />

            {/* Wooden Board Typography */}
            <div className="text-[11px] uppercase tracking-widest text-[#f5d7b5] font-bold drop-shadow-xs">
              Bienvenue chez
            </div>
            <div className="text-xl sm:text-2xl font-black text-[#fff2e2] font-serif-title tracking-tight drop-shadow-md">
              Sherwood
            </div>
            <div className="text-xs text-[#eed1b0] font-semibold tracking-wide">
              Boutique • Caisse POS
            </div>
          </div>
        </div>

        {/* Navigation items (accessible min 44px touch targets) */}
        <nav className="space-y-2" aria-label="Menu principal">
          {navItems.map((item) => {
            const isActive = activeView === item.id;
            const Icon = item.icon;

            return (
              <button
                key={item.id}
                type="button"
                onClick={() => handleNavClick(item.id)}
                aria-current={isActive ? 'page' : undefined}
                className={`touch-btn w-full min-h-[48px] px-4 py-2.5 rounded-2xl text-sm font-bold flex items-center justify-between transition-all cursor-pointer ${
                  isActive
                    ? 'bg-[#fdfbf7] text-[#1f3d29] shadow-md shadow-black/20 scale-[1.01]'
                    : 'text-[#c7dac7] hover:text-white hover:bg-[#284f35] active:bg-[#16311f]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-5 h-5 ${isActive ? 'text-[#1f3d29]' : 'text-[#a6c4a6]'}`} />
                  <span className="text-left leading-tight">{item.label}</span>
                </div>
                {isActive && (
                  <span className="text-xs" title="Vue active">
                    🍃
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Footer info in sidebar */}
      <div className="pt-4 border-t border-[#16311f] text-center text-xs text-[#a6c4a6]/80 font-medium">
        <span>Format Ticket : </span>
        <strong className="text-[#fdfbf7] font-mono">80 mm</strong>
      </div>
    </aside>
  );
};

export default SherwoodSidebar;
