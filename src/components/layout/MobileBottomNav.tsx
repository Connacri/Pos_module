import React, { useEffect, useState } from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  Store,
  Package,
  Receipt,
  ShoppingCart,
  MoreHorizontal,
  LayoutDashboard,
  Users,
  Cloud,
} from 'lucide-react';

type NavEntry = { id: ViewType; label: string; icon: React.FC<{ className?: string }> };

const LEFT: NavEntry[] = [
  { id: 'pos', label: 'Caisse', icon: Store },
  { id: 'catalog', label: 'Catalogue', icon: Package },
];
const RIGHT: NavEntry[] = [{ id: 'sales', label: 'Factures', icon: Receipt }];
const MORE: NavEntry[] = [
  { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
  { id: 'customers', label: 'Clients', icon: Users },
  { id: 'admin', label: 'Admin & Sync', icon: Cloud },
];

const tabClass = (active: boolean) =>
  `touch-btn flex-1 py-1 flex flex-col items-center justify-center gap-0.5 rounded-xl transition-colors cursor-pointer ${
    active ? 'text-forest-900 font-bold' : 'text-ink-600 hover:text-forest-900'
  }`;

export const MobileBottomNav: React.FC = () => {
  const { activeView, setActiveView, cartSummary, setIsCartDrawerOpen } = usePos();
  const [moreOpen, setMoreOpen] = useState(false);

  useEffect(() => {
    if (!moreOpen) return;
    const onKeyDown = (e: KeyboardEvent) => e.key === 'Escape' && setMoreOpen(false);
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [moreOpen]);

  const renderTab = ({ id, label, icon: Icon }: NavEntry) => (
    <button
      key={id}
      type="button"
      onClick={() => setActiveView(id)}
      aria-current={activeView === id ? 'page' : undefined}
      className={tabClass(activeView === id)}
    >
      <Icon className="w-5 h-5" />
      <span className="text-xs">{label}</span>
    </button>
  );

  const moreActive = MORE.some((m) => m.id === activeView);

  return (
    <>
      {moreOpen && (
        <button
          type="button"
          aria-label="Fermer le menu"
          className="lg:hidden fixed inset-0 z-30 cursor-default"
          onClick={() => setMoreOpen(false)}
        />
      )}

      <nav
        aria-label="Navigation principale"
        className="lg:hidden fixed bottom-0 left-0 right-0 z-40 bg-sand-50/95 backdrop-blur-xl border-t border-sand-200 px-2 pt-1.5 pb-[max(0.375rem,env(safe-area-inset-bottom))] shadow-lg flex items-center justify-around"
      >
        {LEFT.map(renderTab)}

        <button
          type="button"
          onClick={() => setIsCartDrawerOpen(true)}
          className={tabClass(false)}
          aria-label={`Panier, ${cartSummary.totalItems} article${cartSummary.totalItems > 1 ? 's' : ''}`}
        >
          <div className="relative">
            <ShoppingCart className="w-5 h-5" />
            {cartSummary.totalItems > 0 && (
              <span
                aria-hidden="true"
                className="absolute -top-1.5 -right-2.5 bg-wood-600 text-sand-50 font-black text-xs min-w-4 h-4 px-1 rounded-full flex items-center justify-center font-mono"
              >
                {cartSummary.totalItems}
              </span>
            )}
          </div>
          <span className="text-xs">Panier</span>
        </button>

        {RIGHT.map(renderTab)}

        <div className="relative flex-1 flex">
          <button
            type="button"
            onClick={() => setMoreOpen((o) => !o)}
            aria-expanded={moreOpen}
            aria-controls="mobile-more-menu"
            className={`${tabClass(moreActive || moreOpen)} w-full`}
          >
            <MoreHorizontal className="w-5 h-5" />
            <span className="text-xs">Plus</span>
          </button>

          {moreOpen && (
            <div
              id="mobile-more-menu"
              className="absolute bottom-full right-0 mb-2 w-56 sherwood-card p-1.5 shadow-xl animate-in fade-in slide-in-from-bottom-2 duration-150"
            >
              {MORE.map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  type="button"
                  aria-current={activeView === id ? 'page' : undefined}
                  onClick={() => {
                    setActiveView(id);
                    setMoreOpen(false);
                  }}
                  className={`touch-btn w-full px-3 py-2 rounded-xl flex items-center gap-3 text-sm cursor-pointer ${
                    activeView === id
                      ? 'bg-forest-800 text-sand-50 font-bold'
                      : 'text-ink-900 hover:bg-sand-100'
                  }`}
                >
                  <Icon className="w-4 h-4" />
                  <span>{label}</span>
                </button>
              ))}
            </div>
          )}
        </div>
      </nav>
    </>
  );
};
