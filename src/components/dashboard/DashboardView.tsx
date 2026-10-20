import React, { useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { DailyRevenueChart } from './DailyRevenueChart';
import {
  TrendingUp,
  CreditCard,
  ShoppingBag,
  Package,
  AlertTriangle,
  ArrowRight,
  Wifi,
  Receipt,
  Store,
  Layers,
  Sparkles,
} from 'lucide-react';

export const DashboardView: React.FC = () => {
  const { todayStats, sales, products, categories, setActiveView } = usePos();

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Compute category sales distribution
  const categoryStats = useMemo(() => {
    const map = new Map<number, { count: number; revenue: number }>();
    categories.forEach((c) => map.set(c.id, { count: 0, revenue: 0 }));

    sales.slice(0, 50).forEach((sale) => {
      sale.items.forEach((item) => {
        const prod = products.find((p) => p.id === item.productId);
        if (prod && map.has(prod.categoryId)) {
          const entry = map.get(prod.categoryId)!;
          entry.count += item.quantity;
          entry.revenue += item.totalTTC;
        }
      });
    });

    const totalCatRevenue = Array.from(map.values()).reduce((sum, v) => sum + v.revenue, 0) || 1;

    return categories.map((cat) => {
      const data = map.get(cat.id) || { count: 0, revenue: 0 };
      const percentage = Math.round((data.revenue / totalCatRevenue) * 100);
      return {
        ...cat,
        soldUnits: data.count,
        revenue: data.revenue,
        percentage,
      };
    }).sort((a, b) => b.revenue - a.revenue);
  }, [categories, products, sales]);

  // Top 5 selling products
  const topProducts = useMemo(() => {
    const map = new Map<number, { name: string; sku: string; units: number; revenue: number }>();

    sales.forEach((s) => {
      s.items.forEach((it) => {
        if (!map.has(it.productId)) {
          map.set(it.productId, { name: it.productName, sku: it.sku, units: 0, revenue: 0 });
        }
        const cur = map.get(it.productId)!;
        cur.units += it.quantity;
        cur.revenue += it.totalTTC;
      });
    });

    return Array.from(map.values())
      .sort((a, b) => b.units - a.units)
      .slice(0, 5);
  }, [sales]);

  // Recent 6 sales
  const recentSales = sales.slice(0, 6);

  return (
    <div className="space-y-6">
      {/* Welcome & Shift Overview Header */}
      <div className="bg-gradient-to-r from-slate-900 via-indigo-950 to-slate-900 text-white rounded-3xl p-6 shadow-lg border border-slate-800 flex flex-col md:flex-row items-start md:items-center justify-between gap-6">
        <div>
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/20 text-emerald-300 text-xs font-semibold mb-2 border border-emerald-500/30">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Caisse Ouverte • Session active
          </div>
          <h2 className="text-2xl font-black tracking-tight text-white flex items-center gap-2">
            Tableau de Bord Caisse & Performance
          </h2>
          <p className="text-xs text-slate-300 mt-1 max-w-xl">
            Suivi en temps réel de votre chiffre d'affaires, transactions enregistrées et alertes stock.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={() => setActiveView('pos')}
            className="px-4 py-2.5 bg-indigo-500 hover:bg-indigo-600 text-white font-bold text-xs rounded-xl shadow-lg transition-all flex items-center gap-2 cursor-pointer active:scale-95"
          >
            <Store className="w-4 h-4" />
            Ouvrir la Caisse POS
          </button>
          <button
            type="button"
            onClick={() => setActiveView('catalog')}
            className="px-4 py-2.5 bg-slate-800 hover:bg-slate-700 text-slate-200 font-semibold text-xs rounded-xl border border-slate-700 transition-all flex items-center gap-2 cursor-pointer"
          >
            <Package className="w-4 h-4" />
            Catalogue
          </button>
        </div>
      </div>

      {/* Primary KPI Grid */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-4">
        {/* KPI 1: Today Revenue */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              Revenu du Jour
            </span>
            <div className="w-8 h-8 rounded-xl bg-blue-50 text-blue-600 flex items-center justify-center">
              <TrendingUp className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-slate-900">
              {formatMoney(todayStats.revenue)}
            </div>
            <div className="text-[11px] text-emerald-600 font-semibold flex items-center gap-1 mt-1">
              <span>+12.4%</span>
              <span className="text-slate-400 font-normal">vs moyenne hebdomadaire</span>
            </div>
          </div>
        </div>

        {/* KPI 2: Sales count */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              Transactions
            </span>
            <div className="w-8 h-8 rounded-xl bg-indigo-50 text-indigo-600 flex items-center justify-center">
              <ShoppingBag className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-slate-900">
              {todayStats.salesCount} tickets
            </div>
            <div className="text-[11px] text-slate-500 mt-1">
              {todayStats.itemsSold} articles vendus au total
            </div>
          </div>
        </div>

        {/* KPI 3: Average Basket */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              Panier Moyen
            </span>
            <div className="w-8 h-8 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <CreditCard className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-slate-900">
              {formatMoney(todayStats.averageBasket)}
            </div>
            <div className="text-[11px] text-slate-500 mt-1">
              Par transaction enregistrée
            </div>
          </div>
        </div>

        {/* KPI 4: Stock Alerts */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              Alertes Stock
            </span>
            <div className="w-8 h-8 rounded-xl bg-amber-50 text-amber-600 flex items-center justify-center">
              <AlertTriangle className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="text-2xl font-extrabold text-amber-600">
              {todayStats.lowStockCount} réf.
            </div>
            <div className="text-[11px] text-slate-500 mt-1 flex items-center gap-1">
              <button
                type="button"
                onClick={() => setActiveView('catalog')}
                className="text-indigo-600 hover:underline font-semibold cursor-pointer"
              >
                Vérifier le catalogue →
              </button>
            </div>
          </div>
        </div>

        {/* KPI 5: P2P Network Sync */}
        <div className="bg-white p-5 rounded-2xl border border-slate-200/80 shadow-xs flex flex-col justify-between">
          <div className="flex items-center justify-between">
            <span className="text-xs font-bold text-slate-500 uppercase tracking-wider">
              Synchro Multi-Postes
            </span>
            <div className="w-8 h-8 rounded-xl bg-teal-50 text-teal-600 flex items-center justify-center">
              <Wifi className="w-4 h-4" />
            </div>
          </div>
          <div className="mt-4">
            <div className="flex items-center gap-1.5 text-sm font-bold text-teal-700">
              <span className="w-2 h-2 rounded-full bg-teal-500"></span>
              P2P Connecté
            </div>
            <div className="text-[10px] text-slate-400 mt-1">
              ObjectBox LAN • Port 8080 actif
            </div>
          </div>
        </div>
      </div>

      {/* Main Section: Daily Revenue Trends (Recharts) */}
      <DailyRevenueChart />

      {/* Secondary Analytics Row: Category breakdown + Top selling products */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        {/* Category Breakdown */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold">
                <Layers className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-sm text-slate-800">
                  Répartition des Ventes par Rayon
                </h3>
                <p className="text-[11px] text-slate-500">
                  Performance relative des catégories de produits
                </p>
              </div>
            </div>
          </div>

          <div className="space-y-3.5">
            {categoryStats.map((cat) => (
              <div key={cat.id} className="space-y-1.5">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-slate-700 flex items-center gap-2">
                    <span
                      className="w-2.5 h-2.5 rounded-full inline-block"
                      style={{ backgroundColor: cat.color || '#6366f1' }}
                    ></span>
                    {cat.name}
                  </span>
                  <div className="flex items-center gap-2">
                    <span className="text-slate-500 text-[11px]">{cat.soldUnits} unités</span>
                    <span className="font-bold text-slate-900">{formatMoney(cat.revenue)}</span>
                    <span className="text-[10px] text-slate-400 font-mono w-8 text-right">
                      {cat.percentage}%
                    </span>
                  </div>
                </div>
                <div className="w-full bg-slate-100 rounded-full h-2 overflow-hidden">
                  <div
                    className="h-full rounded-full transition-all duration-500"
                    style={{
                      width: `${Math.max(5, cat.percentage)}%`,
                      backgroundColor: cat.color || '#6366f1',
                    }}
                  ></div>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Top 5 Best Sellers */}
        <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs">
          <div className="flex items-center justify-between mb-4">
            <div className="flex items-center gap-2">
              <div className="w-8 h-8 rounded-lg bg-amber-50 text-amber-600 flex items-center justify-center font-bold">
                <Sparkles className="w-4 h-4" />
              </div>
              <div>
                <h3 className="font-bold text-sm text-slate-800">
                  Top 5 Articles les Plus Vendus
                </h3>
                <p className="text-[11px] text-slate-500">
                  Classement par volume d'unités écoulées
                </p>
              </div>
            </div>
          </div>

          <div className="divide-y divide-slate-100">
            {topProducts.map((p, index) => (
              <div key={p.sku} className="py-2.5 flex items-center justify-between gap-3">
                <div className="flex items-center gap-3">
                  <span className="w-6 h-6 rounded-full bg-slate-100 text-slate-700 font-bold text-xs flex items-center justify-center shrink-0">
                    {index + 1}
                  </span>
                  <div>
                    <div className="font-semibold text-xs text-slate-800">{p.name}</div>
                    <div className="text-[10px] text-slate-400 font-mono">{p.sku}</div>
                  </div>
                </div>
                <div className="text-right">
                  <div className="font-bold text-xs text-slate-900">{p.units} vendus</div>
                  <div className="text-[10px] text-emerald-600 font-medium">
                    {formatMoney(p.revenue)}
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Recent Transactions List */}
      <div className="bg-white rounded-2xl p-6 border border-slate-200/80 shadow-xs">
        <div className="flex items-center justify-between mb-4">
          <div className="flex items-center gap-2">
            <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center font-bold">
              <Receipt className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-sm text-slate-800">
                Dernières Ventes Enregistrées
              </h3>
              <p className="text-[11px] text-slate-500">
                Tickets de caisse validés récemment
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setActiveView('sales')}
            className="text-xs font-semibold text-indigo-600 hover:text-indigo-800 flex items-center gap-1 cursor-pointer"
          >
            Consulter tout le journal
            <ArrowRight className="w-3.5 h-3.5" />
          </button>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left text-xs">
            <thead>
              <tr className="border-b border-slate-200/80 text-slate-400 text-[11px] uppercase tracking-wider">
                <th className="py-2.5 px-3 font-semibold">N° Ticket</th>
                <th className="py-2.5 px-3 font-semibold">Date & Heure</th>
                <th className="py-2.5 px-3 font-semibold">Client</th>
                <th className="py-2.5 px-3 font-semibold">Articles</th>
                <th className="py-2.5 px-3 font-semibold">Règlement</th>
                <th className="py-2.5 px-3 font-semibold text-right">Montant TTC</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-slate-100">
              {recentSales.map((sale) => (
                <tr key={sale.id} className="hover:bg-slate-50 transition-colors">
                  <td className="py-3 px-3 font-mono font-bold text-indigo-600">
                    {sale.saleNumber}
                  </td>
                  <td className="py-3 px-3 text-slate-500">
                    {new Date(sale.createdAt).toLocaleDateString('fr-FR', {
                      day: '2-digit',
                      month: 'short',
                      hour: '2-digit',
                      minute: '2-digit',
                    })}
                  </td>
                  <td className="py-3 px-3 font-medium text-slate-800">
                    {sale.customerName || 'Client Comptoir'}
                  </td>
                  <td className="py-3 px-3 text-slate-600">
                    {sale.items.reduce((sum, it) => sum + it.quantity, 0)} articles
                  </td>
                  <td className="py-3 px-3">
                    <span className="inline-flex items-center px-2 py-0.5 rounded-md text-[10px] font-semibold bg-slate-100 text-slate-700">
                      {sale.paymentMethod === 'CASH'
                        ? 'Espèces'
                        : sale.paymentMethod === 'CARD'
                        ? 'Carte Bancaire'
                        : 'Chèque / Autre'}
                    </span>
                  </td>
                  <td className="py-3 px-3 font-extrabold text-slate-900 text-right">
                    {formatMoney(sale.totalTTC)}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
};
