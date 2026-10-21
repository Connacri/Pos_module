import React, { useMemo, useState } from 'react';
import { usePos } from '../../context/PosContext';
import { D3RevenueTrendChart } from './D3RevenueTrendChart';
import { DailyRevenueChart } from './DailyRevenueChart';
import { InventoryAlertWidget } from './InventoryAlertWidget';
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
  Star,
  Users,
  Calendar,
  CheckCircle2,
  Gift,
  HelpCircle,
} from 'lucide-react';

export const DashboardView: React.FC = () => {
  const { todayStats, sales, products, categories, setActiveView } = usePos();
  const [chartTab, setChartTab] = useState<'d3-trend' | 'bar-breakdown'>('d3-trend');

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

  // Top selling products
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

  // Recent 5 sales
  const recentSales = sales.slice(0, 5);

  // Villagers / VIP customers matching the Sherwood theme
  const villagers = [
    { name: 'Beau', emoji: '🦌', badge: 'Client VIP', points: '1 450' },
    { name: 'Fauna', emoji: '🦌', badge: 'Passionnée', points: '2 100' },
    { name: 'Merengue', emoji: '🦏', badge: 'Gourmande', points: '890' },
    { name: 'Marshal', emoji: '🐿️', badge: 'Platinum', points: '3 400' },
    { name: 'Filbert', emoji: '🐿️', badge: 'Fidèle', points: '420' },
    { name: 'Zucker', emoji: '🐙', badge: 'En-cas', points: '760' },
    { name: 'Erik', emoji: '🦌', badge: 'Régulier', points: '1 850' },
    { name: 'Bunnie', emoji: '🐰', badge: 'Rayonnante', points: '980' },
  ];

  return (
    <div className="space-y-6">
      {/* Sherwood Hero Banner */}
      <div className="bg-[#1f3d29] text-[#fcfbf7] rounded-3xl p-5 sm:p-6 shadow-lg border border-[#16311f] flex flex-col md:flex-row items-start md:items-center justify-between gap-6 relative overflow-hidden">
        {/* Subtle decorative leaf watermark in background */}
        <div className="absolute right-0 top-0 text-[#295137] text-9xl font-black select-none pointer-events-none -mr-8 -mt-8 opacity-40">
          🍃
        </div>

        <div className="relative z-10">
          <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-[#2a5438] text-[#c7e5c7] text-xs font-bold mb-2 border border-[#3b6f4c]">
            <span className="w-2 h-2 rounded-full bg-emerald-400 animate-pulse"></span>
            Session de Caisse Ouverte • Boutique Sherwood
          </div>
          <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-[#fff5ea] font-serif-title flex items-center gap-2">
            Tableau de Bord & Activité de l'Île
          </h2>
          <p className="text-xs text-[#c5ddc5] mt-1 max-w-xl">
            Suivez vos ventes en temps réel, l'évolution du chiffre d'affaires, les objectifs quotidiens et les stocks.
          </p>
        </div>

        <div className="flex items-center gap-3 relative z-10">
          <button
            type="button"
            onClick={() => setActiveView('pos')}
            className="px-4 py-2.5 bg-[#8d5732] hover:bg-[#784624] text-[#fff6ec] font-bold text-xs rounded-2xl shadow-md transition-all flex items-center gap-2 cursor-pointer active:scale-95 border border-[#6d3e1d]"
          >
            <Store className="w-4 h-4 text-[#fcdbb6]" />
            Ouvrir la Caisse POS
          </button>
          <button
            type="button"
            onClick={() => setActiveView('catalog')}
            className="px-4 py-2.5 bg-[#2a5036] hover:bg-[#346042] text-[#e3eee3] font-semibold text-xs rounded-2xl border border-[#3e6f4d] transition-all flex items-center gap-2 cursor-pointer"
          >
            <Package className="w-4 h-4" />
            Catalogue
          </button>
        </div>
      </div>

      {/* TOP ROW: 3 Primary Cards matching the Sherwood reference image */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
        {/* Card 1: Översikt (Overview & Rating & Mini Calendar) */}
        <div className="sherwood-card p-5 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-[#ece2d1]">
              <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title">
                <span>🍃</span> Översikt
              </div>
              <span className="text-[11px] font-bold text-[#8d5732] bg-[#fbf4e8] px-2 py-0.5 rounded-full border border-[#eddabb]">
                DA-1234-9101
              </span>
            </div>

            {/* Island Rating & Score */}
            <div className="mt-3 bg-[#f7f2e7] p-3 rounded-2xl border border-[#e5dcce] flex items-center justify-between">
              <div>
                <span className="text-[10px] uppercase font-bold text-[#6e6354] tracking-wider block">
                  Ö-betyg (Note Magasin)
                </span>
                <div className="flex items-center gap-1 text-amber-500 mt-0.5">
                  <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
                  <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
                  <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
                  <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
                  <Star className="w-4 h-4 text-amber-400" />
                  <span className="text-xs font-black text-[#233d2a] ml-1">4.8 / 5</span>
                </div>
              </div>
              <div className="text-right">
                <span className="text-[10px] uppercase font-bold text-[#6e6354] tracking-wider block">
                  Caissiers
                </span>
                <span className="text-xs font-black text-[#234931]">2 / 2 en poste</span>
              </div>
            </div>

            {/* Mini Monthly Calendar */}
            <div className="mt-3 p-3 bg-[#fdfbf7] rounded-2xl border border-[#ece3d3]">
              <div className="flex items-center justify-between text-xs font-bold text-[#233d2a] mb-2 px-1">
                <span>Octobre 2026</span>
                <span className="text-[10px] text-[#6e6354]">Semaine 43</span>
              </div>
              {/* Day headers */}
              <div className="grid grid-cols-7 gap-1 text-center text-[10px] font-semibold text-[#8a7f72] mb-1">
                <span>L</span><span>M</span><span>M</span><span>J</span><span>V</span><span>S</span><span>D</span>
              </div>
              {/* Day numbers */}
              <div className="grid grid-cols-7 gap-1 text-center text-[11px] font-medium text-[#483d31]">
                <span className="text-slate-300">28</span>
                <span className="text-slate-300">29</span>
                <span className="text-slate-300">30</span>
                <span>1</span>
                <span>2</span>
                <span>3</span>
                <span>4</span>
                <span>5</span>
                <span>6</span>
                <span>7</span>
                <span>8</span>
                <span>9</span>
                <span>10</span>
                <span>11</span>
                <span>12</span>
                <span>13</span>
                <span>14</span>
                <span>15</span>
                <span>16</span>
                <span>17</span>
                <span>18</span>
                <span>19</span>
                {/* Active Day Circled in Forest Green */}
                <span className="w-6 h-6 rounded-full bg-[#234931] text-[#fff6ec] font-bold mx-auto flex items-center justify-center shadow-xs">
                  20
                </span>
                <span>21</span>
                <span>22</span>
                <span>23</span>
                <span>24</span>
                <span>25</span>
              </div>
            </div>
          </div>

          {/* Daily Special Event Card */}
          <div className="bg-[#f5ece0] p-2.5 rounded-2xl border border-[#e5d5c0] flex items-center gap-2 text-xs text-[#523e2d]">
            <span className="text-base">🎸</span>
            <div>
              <span className="font-bold">K.K. Slider anime la boutique</span>
              <p className="text-[10px] text-[#735c48]">Ambiance guitare acoustique ce soir à 18h00 !</p>
            </div>
          </div>
        </div>

        {/* Card 2: Uppgifter (Daily Goals & Tasks) */}
        <div className="sherwood-card p-5 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-[#ece2d1]">
              <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title">
                <span>🍃</span> Uppgifter (Objectifs)
              </div>
              <button
                type="button"
                onClick={() => setActiveView('sales')}
                className="text-[11px] font-bold text-[#234931] hover:underline"
              >
                Visa alla
              </button>
            </div>

            <div className="space-y-3 mt-3">
              {/* Task 1 */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#3a3024] flex items-center gap-1.5">
                    <span>⭐</span> Atteindre 5 étoiles de service
                  </span>
                  <span className="font-bold text-[#234931] text-[11px]">4 / 5</span>
                </div>
                <div className="w-full bg-[#ece2d1] rounded-full h-1.5 overflow-hidden">
                  <div className="bg-[#2d563a] h-full rounded-full" style={{ width: '80%' }}></div>
                </div>
              </div>

              {/* Task 2 */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#3a3024] flex items-center gap-1.5">
                    <span>💰</span> CA Objectif (100 000 DA)
                  </span>
                  <span className="font-bold text-[#234931] text-[11px]">
                    {Math.min(100, Math.round((todayStats.revenue / 100000) * 100))}%
                  </span>
                </div>
                <div className="w-full bg-[#ece2d1] rounded-full h-1.5 overflow-hidden">
                  <div
                    className="bg-[#2d563a] h-full rounded-full"
                    style={{ width: `${Math.min(100, (todayStats.revenue / 100000) * 100)}%` }}
                  ></div>
                </div>
                <div className="text-[10px] text-[#6e6354] text-right font-mono">
                  {formatMoney(todayStats.revenue)} / 100 000 DA
                </div>
              </div>

              {/* Task 3 */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#3a3024] flex items-center gap-1.5">
                    <span>📦</span> Encaisser 100 articles
                  </span>
                  <span className="font-bold text-[#234931] text-[11px]">
                    {todayStats.itemsSold} / 100
                  </span>
                </div>
                <div className="w-full bg-[#ece2d1] rounded-full h-1.5 overflow-hidden">
                  <div
                    className="bg-[#2d563a] h-full rounded-full"
                    style={{ width: `${Math.min(100, (todayStats.itemsSold / 100) * 100)}%` }}
                  ></div>
                </div>
              </div>

              {/* Task 4 */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#3a3024] flex items-center gap-1.5">
                    <span>👥</span> Servir 10 clients avec fidélité
                  </span>
                  <span className="font-bold text-[#234931] text-[11px]">8 / 10</span>
                </div>
                <div className="w-full bg-[#ece2d1] rounded-full h-1.5 overflow-hidden">
                  <div className="bg-[#2d563a] h-full rounded-full" style={{ width: '80%' }}></div>
                </div>
              </div>

              {/* Task 5 */}
              <div className="space-y-1">
                <div className="flex items-center justify-between text-xs">
                  <span className="font-semibold text-[#3a3024] flex items-center gap-1.5">
                    <span>⚠️</span> Alertes stock traitées
                  </span>
                  <span className="font-bold text-[#8d5732] text-[11px]">
                    {todayStats.lowStockCount} restant(s)
                  </span>
                </div>
                <div className="w-full bg-[#ece2d1] rounded-full h-1.5 overflow-hidden">
                  <div className="bg-[#8d5732] h-full rounded-full" style={{ width: '65%' }}></div>
                </div>
              </div>
            </div>
          </div>

          <div className="pt-2 border-t border-[#ece2d1] flex items-center justify-between text-[11px] text-[#6e6354]">
            <span>Progression globale du jour</span>
            <span className="font-bold text-[#234931]">76% complété</span>
          </div>
        </div>

        {/* Card 3: Senaste trenden (D3 Revenue Trend Preview) */}
        <div className="sherwood-card p-5 space-y-4 flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-2 border-b border-[#ece2d1]">
              <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title">
                <span>🍃</span> Senaste trenden (Ventes 7J)
              </div>
              <button
                type="button"
                onClick={() => setChartTab('d3-trend')}
                className="text-[11px] font-bold text-[#234931] hover:underline"
              >
                Graphique D3
              </button>
            </div>

            {/* Quick KPI stats */}
            <div className="grid grid-cols-2 gap-2 mt-3">
              <div className="bg-[#f7f2e7] p-2.5 rounded-2xl border border-[#e5dcce]">
                <span className="text-[10px] font-bold text-[#6e6354] uppercase tracking-wider block">
                  Revenu Aujourd'hui
                </span>
                <span className="text-base font-black text-[#233d2a]">
                  {formatMoney(todayStats.revenue)}
                </span>
                <span className="text-[10px] text-emerald-700 font-semibold block mt-0.5">
                  +12.4% vs hebdo
                </span>
              </div>

              <div className="bg-[#f7f2e7] p-2.5 rounded-2xl border border-[#e5dcce]">
                <span className="text-[10px] font-bold text-[#6e6354] uppercase tracking-wider block">
                  Panier Moyen
                </span>
                <span className="text-base font-black text-[#233d2a]">
                  {formatMoney(todayStats.averageBasket)}
                </span>
                <span className="text-[10px] text-[#6e6354] block mt-0.5">
                  {todayStats.salesCount} tickets
                </span>
              </div>
            </div>

            {/* Visual preview card with gentle organic curve / mini illustration */}
            <div className="mt-3 p-3 bg-gradient-to-b from-[#edf5ed] to-[#e4efe4] rounded-2xl border border-[#cbe0cb] text-center space-y-1">
              <div className="text-2xl">🌲 ⛺ 🛶</div>
              <div className="text-xs font-bold text-[#234931]">
                Boutique du Sherwood Forest
              </div>
              <p className="text-[11px] text-[#557855]">
                Le graphique haute fidélité D3.js ci-dessous analyse les tendances de vente journalières en temps réel.
              </p>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setActiveView('pos')}
            className="w-full py-2 bg-[#2d563a] hover:bg-[#23442e] text-[#fdfbf7] text-xs font-bold rounded-xl transition-colors flex items-center justify-center gap-1.5 cursor-pointer shadow-xs"
          >
            <Store className="w-3.5 h-3.5" />
            Encaisser une vente immédiate
          </button>
        </div>
      </div>

      {/* D3 REVENUE TREND CHART (Vectorial D3 7-day Line Chart) */}
      <div className="space-y-3">
        <div className="flex items-center justify-between flex-wrap gap-2 px-1">
          <div className="flex items-center gap-2">
            <span className="text-xs font-bold text-[#6e6354] uppercase tracking-wider">
              Analyse Visuelle de la Boutique :
            </span>
            <div className="inline-flex p-1 bg-[#ede4d4] rounded-2xl text-xs font-semibold">
              <button
                type="button"
                onClick={() => setChartTab('d3-trend')}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
                  chartTab === 'd3-trend'
                    ? 'bg-[#234931] text-[#fdfbf7] shadow-xs font-bold'
                    : 'text-[#5d5244] hover:text-[#233d2a]'
                }`}
              >
                <TrendingUp className="w-3.5 h-3.5" />
                <span>Courbe Tendance D3 (7 Jours)</span>
              </button>
              <button
                type="button"
                onClick={() => setChartTab('bar-breakdown')}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
                  chartTab === 'bar-breakdown'
                    ? 'bg-[#234931] text-[#fdfbf7] shadow-xs font-bold'
                    : 'text-[#5d5244] hover:text-[#233d2a]'
                }`}
              >
                <Layers className="w-3.5 h-3.5" />
                <span>Histogramme Détaillé</span>
              </button>
            </div>
          </div>
          <span className="text-[11px] text-[#6e6354] font-medium hidden sm:inline">
            Données synchronisées en direct avec la caisse POS
          </span>
        </div>

        {chartTab === 'd3-trend' ? (
          <D3RevenueTrendChart days={7} />
        ) : (
          <DailyRevenueChart />
        )}
      </div>

      {/* MIDDLE ROW: Samlingar (Collections) + Invånare (Villagers / VIP Customers) */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* Samlingar (Rayons & Collections) */}
        <div className="sherwood-card p-5 space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-[#ece2d1]">
            <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title">
              <span>🍃</span> Samlingar (Rayons de la boutique)
            </div>
            <button
              type="button"
              onClick={() => setActiveView('catalog')}
              className="text-[11px] font-bold text-[#234931] hover:underline"
            >
              Visa alla
            </button>
          </div>

          {/* Cute Collection Stamps matching the reference */}
          <div className="grid grid-cols-5 gap-2 text-center">
            <div className="p-2.5 bg-[#f7f2e7] rounded-2xl border border-[#e5dcce]">
              <div className="text-xl">🐟</div>
              <div className="text-[10px] font-bold text-[#44382b] mt-1">Frais</div>
              <div className="text-[9px] text-[#786b5c] font-mono">43 / 80</div>
            </div>
            <div className="p-2.5 bg-[#f7f2e7] rounded-2xl border border-[#e5dcce]">
              <div className="text-xl">🦋</div>
              <div className="text-[10px] font-bold text-[#44382b] mt-1">Épicerie</div>
              <div className="text-[9px] text-[#786b5c] font-mono">38 / 80</div>
            </div>
            <div className="p-2.5 bg-[#f7f2e7] rounded-2xl border border-[#e5dcce]">
              <div className="text-xl">🐚</div>
              <div className="text-[10px] font-bold text-[#44382b] mt-1">Maison</div>
              <div className="text-[9px] text-[#786b5c] font-mono">24 / 40</div>
            </div>
            <div className="p-2.5 bg-[#f7f2e7] rounded-2xl border border-[#e5dcce]">
              <div className="text-xl">🖼️</div>
              <div className="text-[10px] font-bold text-[#44382b] mt-1">Déco</div>
              <div className="text-[9px] text-[#786b5c] font-mono">12 / 43</div>
            </div>
            <div className="p-2.5 bg-[#f7f2e7] rounded-2xl border border-[#e5dcce]">
              <div className="text-xl">🔨</div>
              <div className="text-[10px] font-bold text-[#44382b] mt-1">Bricolage</div>
              <div className="text-[9px] text-[#786b5c] font-mono">210 / 602</div>
            </div>
          </div>

          {/* Goal banner */}
          <div className="p-3 bg-[#edf5ed] rounded-2xl border border-[#cde3cd] flex items-center gap-3">
            <span className="text-xl">🐟</span>
            <div className="flex-1">
              <div className="flex items-center justify-between text-xs font-bold text-[#234931]">
                <span>Mål : Rayon Frais & Boissons en vedette</span>
                <span>43 / 80</span>
              </div>
              <div className="w-full bg-[#cbe0cb] rounded-full h-1.5 mt-1 overflow-hidden">
                <div className="bg-[#2d563a] h-full rounded-full" style={{ width: '54%' }}></div>
              </div>
              <div className="text-[10px] text-[#567a56] mt-0.5">Vous êtes à mi-chemin de l'objectif !</div>
            </div>
          </div>

          {/* Top Selling Products List */}
          <div className="divide-y divide-[#ece2d1] pt-1">
            {topProducts.map((p, idx) => (
              <div key={p.sku} className="py-2 flex items-center justify-between text-xs">
                <div className="flex items-center gap-2">
                  <span className="w-5 h-5 rounded-full bg-[#f2e9db] text-[#5a4c3d] font-bold text-[10px] flex items-center justify-center">
                    {idx + 1}
                  </span>
                  <div>
                    <span className="font-bold text-[#233d2a]">{p.name}</span>
                    <span className="text-[10px] text-[#8a7e71] font-mono ml-2">{p.sku}</span>
                  </div>
                </div>
                <div className="text-right">
                  <span className="font-bold text-[#234931]">{p.units} vendus</span>
                  <span className="text-[10px] text-[#6e6354] block">{formatMoney(p.revenue)}</span>
                </div>
              </div>
            ))}
          </div>
        </div>

        {/* Invånare (Clients VIP & Équipe du Magasin) */}
        <div className="sherwood-card p-5 space-y-4">
          <div className="flex items-center justify-between pb-2 border-b border-[#ece2d1]">
            <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title">
              <span>🍃</span> Invånare (Clients Fidèles & Équipe)
            </div>
            <button
              type="button"
              onClick={() => setActiveView('customers')}
              className="text-[11px] font-bold text-[#234931] hover:underline"
            >
              Visa alla
            </button>
          </div>

          {/* Villagers grid with circular avatars matching the reference */}
          <div className="grid grid-cols-4 gap-3 text-center">
            {villagers.map((v) => (
              <div
                key={v.name}
                className="p-2 bg-[#fdfbf7] hover:bg-[#f7f2e7] rounded-2xl border border-[#ece2d1] transition-all cursor-pointer group"
                onClick={() => setActiveView('customers')}
              >
                <div className="w-12 h-12 rounded-full bg-[#f4ebe0] border-2 border-[#8d5732] flex items-center justify-center text-2xl mx-auto shadow-xs group-hover:scale-105 transition-transform">
                  {v.emoji}
                </div>
                <div className="text-xs font-bold text-[#233d2a] mt-1.5">{v.name}</div>
                <div className="text-[9px] text-[#8d5732] font-semibold">{v.badge}</div>
                <div className="text-[9px] text-[#706456] font-mono">{v.points} pts</div>
              </div>
            ))}
          </div>

          {/* Invite More Villagers / Add Customer Button */}
          <button
            type="button"
            onClick={() => setActiveView('customers')}
            className="w-full py-2.5 bg-[#2d563a] hover:bg-[#23442e] text-[#fdfbf7] text-xs font-bold rounded-2xl transition-colors flex items-center justify-center gap-2 cursor-pointer shadow-xs border border-[#21402b]"
          >
            <span>🍃</span>
            <span>Bjud in fler invånare (Nouveau Client)</span>
          </button>
        </div>
      </div>

      {/* INVENTORY SURVEILLANCE & REORDER THRESHOLD WIDGET */}
      <InventoryAlertWidget />

      {/* BOTTOM ROW: Anteckningar (Cozy Sticky Notes matching reference) */}
      <div className="sherwood-card p-5 space-y-3">
        <div className="flex items-center gap-1.5 font-bold text-sm text-[#233d2a] font-serif-title pb-2 border-b border-[#ece2d1]">
          <span>🍃</span> Anteckningar & Idéer (Notes de la boutique Sherwood)
        </div>

        <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
          {/* Note 1: Idéer */}
          <div className="bg-[#fef8ed] p-3.5 rounded-2xl border border-[#f5dfb8] space-y-1 relative">
            <div className="flex items-center justify-between text-xs font-bold text-[#7a4e1d]">
              <span>💡 Idéer</span>
              <span>🌿</span>
            </div>
            <ul className="text-xs text-[#5c3e1e] space-y-1 pt-1 list-disc list-inside">
              <li>Créer un comptoir dégustation de produits locaux.</li>
              <li>Mettre en avant le nouveau lot d'huiles artisanales.</li>
            </ul>
          </div>

          {/* Note 2: Ranka upp Nook's Cranny */}
          <div className="bg-[#fef8ed] p-3.5 rounded-2xl border border-[#f5dfb8] space-y-1 relative">
            <div className="flex items-center justify-between text-xs font-bold text-[#7a4e1d]">
              <span>💰 Ranka upp butiken</span>
              <span>🔔</span>
            </div>
            <p className="text-xs text-[#5c3e1e] pt-1">
              Atteindre 150 000 DA de ventes ce week-end pour débloquer l'agrandissement de la boutique !
            </p>
          </div>

          {/* Note 3: Dröm om... */}
          <div className="bg-[#fef8ed] p-3.5 rounded-2xl border border-[#f5dfb8] space-y-1 relative">
            <div className="flex items-center justify-between text-xs font-bold text-[#7a4e1d]">
              <span>🎨 Dröm om...</span>
              <span>🪶</span>
            </div>
            <p className="text-xs text-[#5c3e1e] pt-1">
              Une boutique chaleureuse au cœur de la forêt avec le meilleur accueil et un encaissement ultra fluide.
            </p>
          </div>
        </div>
      </div>
    </div>
  );
};
