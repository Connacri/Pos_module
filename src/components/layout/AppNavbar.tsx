import React from 'react';
import { usePos, ViewType } from '../../context/PosContext';
import {
  LayoutDashboard,
  Store,
  Package,
  Receipt,
  Users,
  ShoppingCart,
  Menu,
  X,
  RefreshCw,
  Wifi,
  WifiOff,
  Cloud,
  Sliders,
} from 'lucide-react';

export const AppNavbar: React.FC = () => {
  const {
    activeView,
    setActiveView,
    cartSummary,
    isMobileMenuOpen,
    setIsMobileMenuOpen,
    isCartDrawerOpen,
    setIsCartDrawerOpen,
    isOffline,
    pendingSyncCount,
    resetDemoData,
  } = usePos();

  const navItems: { id: ViewType; label: string; icon: React.FC<{ className?: string }> }[] = [
    { id: 'dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
    { id: 'pos', label: 'Caisse POS', icon: Store },
    { id: 'catalog', label: 'Catalogue', icon: Package },
    { id: 'sales', label: 'Factures & Ventes', icon: Receipt },
    { id: 'customers', label: 'Clients', icon: Users },
    { id: 'admin', label: 'Admin & Sync', icon: Cloud },
  ];

  return (
    <>
      <header className="sticky top-0 z-40 px-3 sm:px-6 py-2.5 bg-white/70 backdrop-blur-xl border-b border-white/50 shadow-xs">
        <div className="max-w-7xl mx-auto flex items-center justify-between gap-2 sm:gap-4">
          {/* Logo & Brand */}
          <div className="flex items-center gap-2 sm:gap-3">
            <div
              onClick={() => setActiveView('dashboard')}
              className="flex items-center gap-2 cursor-pointer group"
            >
              <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-2xl bg-gradient-to-tr from-indigo-600 to-teal-400 flex items-center justify-center text-white font-black text-lg tracking-tighter shadow-md group-hover:scale-105 transition-transform">
                sf.
              </div>
              <div className="hidden min-[420px]:block">
                <div className="font-extrabold text-sm sm:text-base text-slate-800 tracking-tight leading-none">
                  POS Pro
                </div>
                <div className="text-[10px] text-slate-400 font-medium tracking-wider uppercase mt-0.5">
                  Multi-Postes
                </div>
              </div>
            </div>

            {/* Offline / Online Status Pill with Pending Queue */}
            <button
              type="button"
              onClick={() => setActiveView('admin')}
              className={`touch-btn px-2.5 py-1 rounded-full border text-[11px] font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
                isOffline
                  ? 'bg-amber-50 border-amber-300 text-amber-800 hover:bg-amber-100'
                  : 'bg-emerald-50 border-emerald-200 text-emerald-700 hover:bg-emerald-100'
              }`}
              title="Cliquer pour gérer la synchronisation Supabase"
            >
              {isOffline ? (
                <>
                  <WifiOff className="w-3.5 h-3.5 text-amber-600" />
                  <span className="hidden sm:inline">Hors-Ligne (100% Autonome)</span>
                  <span className="sm:hidden">Hors-Ligne</span>
                  {pendingSyncCount > 0 && (
                    <span className="px-1.5 py-0.5 bg-amber-600 text-white rounded-full text-[10px]">
                      {pendingSyncCount}
                    </span>
                  )}
                </>
              ) : (
                <>
                  <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
                  <Wifi className="w-3.5 h-3.5 text-emerald-600" />
                  <span className="hidden sm:inline">En Ligne • Supabase Cloud</span>
                  <span className="sm:hidden">En Ligne</span>
                </>
              )}
            </button>
          </div>

          {/* Desktop Navigation Links */}
          <nav className="hidden md:flex items-center gap-1 bg-white/80 p-1 rounded-2xl border border-slate-200/70 shadow-2xs">
            {navItems.map((item) => {
              const Icon = item.icon;
              const isActive = activeView === item.id;
              return (
                <button
                  key={item.id}
                  type="button"
                  onClick={() => setActiveView(item.id)}
                  className={`px-3 py-1.5 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-all cursor-pointer ${
                    isActive
                      ? 'bg-slate-900 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100/70'
                  }`}
                >
                  <Icon className="w-3.5 h-3.5" />
                  <span>{item.label}</span>
                </button>
              );
            })}
          </nav>

          {/* Right Header Actions */}
          <div className="flex items-center gap-2">
            {/* Quick Cart Pill (Desktop and Mobile) */}
            <button
              type="button"
              onClick={() => {
                if (window.innerWidth < 1024) {
                  setIsCartDrawerOpen(!isCartDrawerOpen);
                } else {
                  setActiveView('pos');
                }
              }}
              className="touch-btn px-3 py-2 bg-indigo-600 hover:bg-indigo-700 text-white rounded-2xl font-bold text-xs shadow-md shadow-indigo-500/20 flex items-center gap-2 transition-all active:scale-95 cursor-pointer"
            >
              <ShoppingCart className="w-4 h-4 text-emerald-300" />
              <span className="hidden sm:inline">Panier</span>
              <span className="px-1.5 py-0.5 bg-indigo-800 text-white rounded-full text-[11px] font-mono">
                {cartSummary.totalItems}
              </span>
            </button>

            {/* Reset Demo button (desktop) */}
            <button
              type="button"
              onClick={resetDemoData}
              title="Réinitialiser les données de démo"
              className="hidden lg:flex touch-btn p-2 text-slate-400 hover:text-slate-600 hover:bg-white rounded-xl transition-colors cursor-pointer"
            >
              <RefreshCw className="w-4 h-4" />
            </button>

            {/* Mobile Hamburger Toggle */}
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
              className="md:hidden touch-btn p-2 text-slate-700 hover:text-slate-900 bg-white/80 border border-slate-200/80 rounded-2xl flex items-center justify-center transition-colors cursor-pointer"
              aria-label="Menu"
            >
              {isMobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
            </button>
          </div>
        </div>
      </header>

      {/* Mobile Menu Backdrop & Drawer */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 z-50 md:hidden bg-slate-900/40 backdrop-blur-xs flex flex-col justify-end">
          <div className="bg-white rounded-t-3xl p-6 shadow-2xl border-t border-slate-200 max-h-[85dvh] overflow-y-auto animate-in slide-in-from-bottom duration-200">
            {/* Mobile Drawer Header */}
            <div className="flex items-center justify-between pb-4 border-b border-slate-100">
              <div className="flex items-center gap-2">
                <div className="w-8 h-8 rounded-xl bg-indigo-600 text-white flex items-center justify-center font-black text-sm">
                  sf.
                </div>
                <div>
                  <h3 className="font-bold text-sm text-slate-900">Navigation POS Pro</h3>
                  <p className="text-[11px] text-slate-400">Système de caisse & facturation</p>
                </div>
              </div>
              <button
                type="button"
                onClick={() => setIsMobileMenuOpen(false)}
                className="touch-btn p-2 text-slate-400 hover:text-slate-700"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            {/* Mobile Nav Links */}
            <div className="py-4 space-y-1">
              {navItems.map((item) => {
                const Icon = item.icon;
                const isActive = activeView === item.id;
                return (
                  <button
                    key={item.id}
                    type="button"
                    onClick={() => {
                      setActiveView(item.id);
                      setIsMobileMenuOpen(false);
                    }}
                    className={`w-full min-h-[48px] px-4 py-3 rounded-2xl text-sm font-semibold flex items-center gap-3 transition-colors text-left cursor-pointer ${
                      isActive
                        ? 'bg-slate-900 text-white shadow-xs'
                        : 'text-slate-700 hover:bg-slate-100'
                    }`}
                  >
                    <Icon className="w-5 h-5" />
                    <span>{item.label}</span>
                  </button>
                );
              })}
            </div>

            {/* Mobile Drawer Status & Reset */}
            <div className="pt-4 border-t border-slate-100 space-y-3">
              <div className="flex items-center justify-between text-xs text-slate-600 bg-slate-50 p-3 rounded-2xl">
                <span className="flex items-center gap-1.5 font-bold">
                  {isOffline ? (
                    <>
                      <WifiOff className="w-3.5 h-3.5 text-amber-600" />
                      Mode Hors-Ligne
                    </>
                  ) : (
                    <>
                      <span className="w-2 h-2 rounded-full bg-emerald-500"></span>
                      Connecté Cloud Supabase
                    </>
                  )}
                </span>
                <span className="text-[11px] font-mono bg-white px-2 py-0.5 rounded-lg border border-slate-200">
                  {pendingSyncCount} attente(s)
                </span>
              </div>

              <button
                type="button"
                onClick={() => {
                  resetDemoData();
                  setIsMobileMenuOpen(false);
                }}
                className="w-full min-h-[44px] py-2.5 px-4 text-xs font-semibold text-rose-600 bg-rose-50 hover:bg-rose-100 rounded-xl flex items-center justify-center gap-2 cursor-pointer transition-colors"
              >
                <RefreshCw className="w-4 h-4" />
                Réinitialiser les données de démo
              </button>
            </div>
          </div>
        </div>
      )}
    </>
  );
};
