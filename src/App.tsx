import React from 'react';
import { PosProvider, usePos } from './context/PosContext';
import { SherwoodSidebar } from './components/layout/SherwoodSidebar';
import { SherwoodHeader } from './components/layout/SherwoodHeader';
import { MobileBottomNav } from './components/layout/MobileBottomNav';
import { DashboardView } from './components/dashboard/DashboardView';
import { PosRegisterView } from './components/pos/PosRegisterView';
import { ProductCatalogView } from './components/catalog/ProductCatalogView';
import { SalesHistoryView } from './components/sales/SalesHistoryView';
import { CustomersView } from './components/customers/CustomersView';
import { AdminSyncView } from './components/admin/AdminSyncView';
import { CartDrawer } from './components/pos/CartDrawer';
import { X, CheckCircle2, AlertTriangle, XCircle, Info } from 'lucide-react';

const MainContent: React.FC = () => {
  const { activeView } = usePos();

  return (
    <main className="p-3 sm:p-6 pb-[calc(var(--bottom-nav-h)+1.5rem+env(safe-area-inset-bottom))] lg:pb-8 flex-1 w-full max-w-[1760px] mx-auto overflow-x-hidden">
      {activeView === 'dashboard' && <DashboardView />}
      {activeView === 'pos' && <PosRegisterView />}
      {activeView === 'catalog' && <ProductCatalogView />}
      {activeView === 'sales' && <SalesHistoryView />}
      {activeView === 'customers' && <CustomersView />}
      {activeView === 'admin' && <AdminSyncView />}
    </main>
  );
};

export const AppLayout: React.FC = () => {
  const { isMobileMenuOpen, setIsMobileMenuOpen, globalToast, dismissToast } = usePos();

  // Handle escape key to close mobile drawer (WCAG accessibility)
  React.useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isMobileMenuOpen) {
        setIsMobileMenuOpen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isMobileMenuOpen, setIsMobileMenuOpen]);

  return (
    <div className="min-h-dvh bg-[#f4efe4] text-[#2c241c] flex flex-row antialiased">
      {/* Desktop Sherwood Forest Sidebar */}
      <div className="hidden lg:flex shrink-0">
        <SherwoodSidebar />
      </div>

      {/* Mobile Slide-out Drawer */}
      {isMobileMenuOpen && (
        <div
          role="dialog"
          aria-modal="true"
          aria-label="Menu principal de navigation"
          className="fixed inset-0 z-50 lg:hidden flex"
        >
          {/* Backdrop with dark blur and tactile dismissal */}
          <div
            className="fixed inset-0 bg-black/70 backdrop-blur-xs transition-opacity animate-in fade-in duration-200 cursor-pointer"
            onClick={() => setIsMobileMenuOpen(false)}
            aria-hidden="true"
          />
          {/* Slide-out Drawer Container */}
          <div className="relative z-10 w-80 max-w-[85vw] h-full shadow-2xl flex flex-col bg-[#1f3d29] border-r border-[#16311f] animate-in slide-in-from-left duration-250">
            <SherwoodSidebar isMobile onClose={() => setIsMobileMenuOpen(false)} />
          </div>
        </div>
      )}

      {/* Main Right Area: Top Header + View Content */}
      <div className="flex-1 flex flex-col min-w-0">
        <SherwoodHeader />
        <MainContent />
      </div>

      {/* Mobile Bottom Navigation */}
      <MobileBottomNav />

      {/* Tiroir panier mobile : disponible depuis toutes les vues */}
      <CartDrawer />

      {/* Conteneur principal des toasts et messages de feedback avec aria-live='polite' */}
      <div
        id="app-global-feedback-region"
        role="region"
        aria-label="Messages de notification et alertes"
        aria-live="polite"
        aria-atomic="false"
        className="fixed inset-x-4 top-[calc(var(--header-h)+0.5rem+env(safe-area-inset-top))] sm:inset-x-auto sm:right-6 sm:w-96 z-50 pointer-events-none space-y-2"
      >
        {globalToast && (
          <div
            role="status"
            aria-live="polite"
            className={`p-3.5 rounded-2xl text-xs sm:text-sm font-semibold shadow-xl border flex items-center justify-between gap-3 pointer-events-auto transition-all animate-in fade-in slide-in-from-top-2 duration-200 ${
              globalToast.type === 'success'
                ? 'bg-[#1f3d29] text-[#fdfbf7] border-[#2d563a]'
                : globalToast.type === 'warning'
                ? 'bg-[#fffbeb] text-[#92400e] border-[#fde68a]'
                : globalToast.type === 'error'
                ? 'bg-[#fef2f2] text-[#991b1b] border-[#fecaca]'
                : 'bg-[#2c241c] text-[#fdfbf7] border-[#4a3e31]'
            }`}
          >
            <div className="flex items-center gap-2.5 min-w-0">
              {globalToast.type === 'success' && (
                <CheckCircle2 className="w-5 h-5 text-[#86efac] shrink-0" aria-hidden="true" />
              )}
              {globalToast.type === 'warning' && (
                <AlertTriangle className="w-5 h-5 text-[#d97706] shrink-0" aria-hidden="true" />
              )}
              {globalToast.type === 'error' && (
                <XCircle className="w-5 h-5 text-[#dc2626] shrink-0" aria-hidden="true" />
              )}
              {(!globalToast.type || globalToast.type === 'info') && (
                <Info className="w-5 h-5 text-[#93c5fd] shrink-0" aria-hidden="true" />
              )}
              <span className="truncate">{globalToast.message}</span>
            </div>
            <button
              type="button"
              onClick={dismissToast}
              aria-label="Fermer la notification"
              className="touch-btn p-1 rounded-lg hover:bg-black/10 transition-colors cursor-pointer shrink-0"
            >
              <X className="w-4 h-4" />
            </button>
          </div>
        )}
      </div>
    </div>
  );
};

export const App: React.FC = () => {
  return (
    <PosProvider>
      <AppLayout />
    </PosProvider>
  );
};

export default App;
