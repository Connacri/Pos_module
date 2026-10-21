import React from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  Store,
  LayoutDashboard,
  Package,
  Receipt,
  Users,
  Cloud,
  Sparkles,
  ShoppingBag,
} from 'lucide-react';

export const SherwoodSidebar: React.FC = () => {
  const { activeView, setActiveView } = usePos();

  const navItems: { id: ViewType; swedishLabel: string; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'pos', swedishLabel: 'Hem', label: 'Caisse POS', icon: Store },
    { id: 'dashboard', swedishLabel: 'Översikt', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'catalog', swedishLabel: 'Uppgifter', label: 'Catalogue', icon: Package },
    { id: 'sales', swedishLabel: 'Samlingar', label: 'Factures & Ventes', icon: Receipt },
    { id: 'customers', swedishLabel: 'Invånare', label: 'Clients', icon: Users },
    { id: 'admin', swedishLabel: 'Moln & Synk', label: 'Cloud Supabase & Synk', icon: Cloud },
  ];

  return (
    <aside className="w-64 bg-[#1f3d29] text-[#e8f1e8] flex flex-col justify-between p-4 shrink-0 shadow-xl border-r border-[#173020] min-h-screen">
      {/* Top Section: Wooden Sign & Nav */}
      <div className="space-y-6">
        {/* Carved Wooden Island Sign */}
        <div className="pt-2">
          <div className="sherwood-wood-board rounded-2xl p-3.5 text-center relative overflow-hidden group cursor-pointer transition-transform hover:scale-[1.02]">
            {/* Top leaf pin */}
            <div className="absolute -top-1 left-1/2 -translate-x-1/2 w-6 h-6 flex items-center justify-center text-emerald-300 drop-shadow-sm text-sm">
              🍃
            </div>

            {/* Corner metal rivets / bolts */}
            <div className="absolute top-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute top-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 left-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />
            <div className="absolute bottom-1.5 right-1.5 w-2 h-2 rounded-full bg-[#30190a] border border-[#5a3217] shadow-inner" />

            {/* Wooden Board Typography */}
            <div className="text-[10px] uppercase tracking-widest text-[#f5d7b5] font-semibold drop-shadow-xs">
              Welcome to
            </div>
            <div className="text-xl sm:text-2xl font-black text-[#fff2e2] font-serif-title tracking-tight drop-shadow-md">
              Sherwood
            </div>
            <div className="text-[11px] text-[#eed1b0] font-medium tracking-wide">
              Island • Boutique POS
            </div>
          </div>
        </div>

        {/* Navigation Items Styled as Cream Pills when active */}
        <nav className="space-y-1.5">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeView === item.id;
            return (
              <button
                key={item.id}
                type="button"
                onClick={() => setActiveView(item.id)}
                className={`w-full min-h-[46px] px-4 py-2.5 rounded-2xl text-xs font-bold flex items-center justify-between transition-all cursor-pointer ${
                  isActive
                    ? 'bg-[#fdfbf7] text-[#1f3d29] shadow-md shadow-black/15 scale-[1.02]'
                    : 'text-[#c7dac7] hover:text-white hover:bg-[#284f35]'
                }`}
              >
                <div className="flex items-center gap-3">
                  <Icon className={`w-4 h-4 ${isActive ? 'text-[#1f3d29]' : 'text-[#a6c4a6]'}`} />
                  <div className="text-left leading-tight">
                    <div className="text-[13px]">{item.swedishLabel}</div>
                    <div className={`text-[10px] font-normal ${isActive ? 'text-[#5d7e63]' : 'text-[#87a987]'}`}>
                      {item.label}
                    </div>
                  </div>
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

      {/* Bottom Section: Friendly Shopkeeper & Daily Tip (Dagens tips) */}
      <div className="pt-4 space-y-3">
        {/* Daily Tip Widget matching the Tom Nook card in the reference */}
        <div className="bg-[#172f20] rounded-2xl p-3 border border-[#264b32] relative overflow-hidden text-left shadow-inner">
          <div className="flex items-center gap-2.5 mb-1.5">
            {/* Friendly shopkeeper avatar with green apron */}
            <div className="w-10 h-10 rounded-full bg-[#3d2716] border-2 border-[#a66a3d] flex items-center justify-center text-lg shadow-sm shrink-0 overflow-hidden">
              🦝
            </div>
            <div>
              <div className="text-[10px] uppercase font-bold tracking-wider text-[#a8d3a8] flex items-center gap-1">
                <span>🍃</span> Dagens tips
              </div>
              <div className="text-xs font-bold text-[#fcfbf7]">
                Conseil du gérant
              </div>
            </div>
          </div>
          <p className="text-[11px] text-[#c5ddc5] leading-relaxed">
            Maintenez vos seuils d'alerte pour réapprovisionner avant la rupture de stock !
          </p>
          <div className="mt-2 pt-2 border-t border-[#264b32] flex items-center justify-between text-[10px] text-[#e0a944] font-semibold">
            <span>⭐ Clochettes & Fidélité</span>
            <span>DA-1234-9101</span>
          </div>
        </div>
      </div>
    </aside>
  );
};
