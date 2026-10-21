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
import { X } from 'lucide-react';

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
  const { isMobileMenuOpen, setIsMobileMenuOpen } = usePos();

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
