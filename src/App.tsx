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
    <main className="p-3 sm:p-6 pb-24 lg:pb-8 flex-1 overflow-x-hidden">
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

  return (
    <div className="min-h-screen bg-[#f4efe4] text-[#2c241c] flex flex-row antialiased">
      {/* Desktop Sherwood Forest Sidebar */}
      <div className="hidden lg:flex shrink-0">
        <SherwoodSidebar />
      </div>

      {/* Mobile Slide-out Drawer */}
      {isMobileMenuOpen && (
        <div className="fixed inset-0 z-50 lg:hidden flex">
          <div
            className="fixed inset-0 bg-black/50 backdrop-blur-xs transition-opacity"
            onClick={() => setIsMobileMenuOpen(false)}
          />
          <div className="relative z-10 w-72 max-w-[85vw] h-full shadow-2xl flex flex-col">
            <button
              type="button"
              onClick={() => setIsMobileMenuOpen(false)}
              className="absolute top-3 right-3 p-2 text-[#c7dac7] hover:text-white z-20"
              aria-label="Fermer le menu"
            >
              <X className="w-5 h-5" />
            </button>
            <SherwoodSidebar />
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
        className="fixed top-20 right-4 sm:right-6 z-50 pointer-events-none space-y-2 max-w-sm w-full"
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
