import React from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  Store,
  LayoutDashboard,
  Package,
  Receipt,
  Users,
  Cloud,
} from 'lucide-react';

export const SherwoodSidebar: React.FC = () => {
  const { activeView, setActiveView } = usePos();

  const navItems: { id: ViewType; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'pos', label: 'Caisse POS', icon: Store },
    { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'catalog', label: 'Catalogue', icon: Package },
    { id: 'sales', label: 'Factures & Ventes', icon: Receipt },
    { id: 'customers', label: 'Clients', icon: Users },
    { id: 'admin', label: 'Admin & Sync', icon: Cloud },
  ];

  return (
    <aside className="w-64 bg-[#1f3d29] text-[#fcfbf7] h-screen sticky top-0 flex flex-col justify-between p-4 border-r border-[#16311f] select-none shadow-xl">
      {/* Top Section: Wooden Signboard + Navigation */}
      <div className="space-y-6">
        {/* Carved Wooden Sherwood Signboard Header */}
        <div className="pt-2 px-1">
          <div className="sherwood-wood-board rounded-2xl p-4 text-center">
            {/* Wooden Nails / Screws in 4 corners */}
            <div className="absolute top-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />

            {/* Wooden Board Typography */}
            <div className="text-xs uppercase tracking-widest text-[#f5d7b5] font-semibold drop-shadow-xs">
              Bienvenue chez
            </div>
            <div className="text-xl sm:text-2xl font-black text-[#fff2e2] font-serif-title tracking-tight drop-shadow-md">
              Sherwood
            </div>
            <div className="text-xs text-[#eed1b0] font-medium tracking-wide">
              Boutique • Caisse POS
            </div>
          </div>
        </div>

        {/* Navigation items */}
        <nav className="space-y-1.5" aria-label="Menu principal">
          {navItems.map((item) => {
            const isActive = activeView === item.id;
            const Icon = item.icon;

            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveView(item.id)}
                aria-current={isActive ? 'page' : undefined}
                className={`w-full min-h-[46px] px-4 py-2.5 rounded-2xl text-sm font-bold flex items-center justify-between transition-all cursor-pointer ${
                  isActive
                    ? 'bg-[#fdfbf7] text-[#1f3d29] shadow-md shadow-black/15 scale-[1.02]'
                    : 'text-[#c7dac7] hover:text-white hover:bg-[#284f35]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-[#1f3d29]' : 'text-[#a6c4a6]'}`} />
                  <span className="text-left leading-tight">{item.label}</span>
                </div>
                {isActive && (
                  <span className="text-xs" title="Actif">
                    🍃
                  </span>
                )}
              </button>
            );
          })}
        </nav>
      </div>
    </aside>
  );
};
