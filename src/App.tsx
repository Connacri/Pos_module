import React from 'react';
import { PosProvider, usePos } from './context/PosContext';
import { AppNavbar } from './components/layout/AppNavbar';
import { MobileBottomNav } from './components/layout/MobileBottomNav';
import { DashboardView } from './components/dashboard/DashboardView';
import { PosRegisterView } from './components/pos/PosRegisterView';
import { ProductCatalogView } from './components/catalog/ProductCatalogView';
import { SalesHistoryView } from './components/sales/SalesHistoryView';
import { CustomersView } from './components/customers/CustomersView';
import { AdminSyncView } from './components/admin/AdminSyncView';

const MainContent: React.FC = () => {
  const { activeView } = usePos();

  return (
    <main className="max-w-7xl mx-auto px-3 sm:px-6 py-4 sm:py-6 pb-24 md:pb-8">
      {activeView === 'dashboard' && <DashboardView />}
      {activeView === 'pos' && <PosRegisterView />}
      {activeView === 'catalog' && <ProductCatalogView />}
      {activeView === 'sales' && <SalesHistoryView />}
      {activeView === 'customers' && <CustomersView />}
      {activeView === 'admin' && <AdminSyncView />}
    </main>
  );
};

export const App: React.FC = () => {
  return (
    <PosProvider>
      <div className="min-h-screen bg-gradient-to-br from-[#daf0e7] via-[#e4ecfb] to-[#eedef7] text-slate-800 antialiased flex flex-col selection:bg-indigo-600 selection:text-white">
        <AppNavbar />
        <div className="flex-1">
          <MainContent />
        </div>
        <MobileBottomNav />
      </div>
    </PosProvider>
  );
};

export default App;
