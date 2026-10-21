import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { D3RevenueTrendChart } from './D3RevenueTrendChart';
import { DailyRevenueChart } from './DailyRevenueChart';
import { InventoryAlertWidget } from './InventoryAlertWidget';
import {
  TrendingUp,
  Layers,
  Store,
  Package,
  AlertTriangle,
  Calendar,
} from 'lucide-react';
import type { PaymentMethod } from '../../types';

export type TimePeriod = 'today' | 'week' | 'month';

const PAYMENT_LABELS: Record<PaymentMethod, string> = {
  CASH: 'Espèces',
  CARD: 'Carte',
  TRANSFER: 'Virement',
  CHEQUE: 'Chèque',
};

const PERIOD_CONFIG: Record<
  TimePeriod,
  { label: string; rangeLabel: string; hint: string }
> = {
  today: {
    label: "Aujourd'hui",
    rangeLabel: "Aujourd'hui",
    hint: 'Journée en cours',
  },
  week: {
    label: 'Semaine (7j)',
    rangeLabel: '7 derniers jours',
    hint: 'Semaine glissante',
  },
  month: {
    label: 'Mois (30j)',
    rangeLabel: '30 derniers jours',
    hint: 'Mois glissant',
  },
};

const formatMoney = (val: number) =>
  new Intl.NumberFormat('fr-DZ', { maximumFractionDigits: 0 }).format(val) + ' DA';

const formatSaleDate = (iso: string) =>
  new Date(iso).toLocaleString('fr-FR', {
    day: 'numeric',
    month: 'short',
    hour: '2-digit',
    minute: '2-digit',
  });

const Kpi: React.FC<{
  label: string;
  value: string;
  hint?: string;
  tone?: 'default' | 'warning';
  onClick?: () => void;
}> = ({ label, value, hint, tone = 'default', onClick }) => {
  const body = (
    <>
      <span className="text-xs font-semibold text-ink-600 block">{label}</span>
      <span
        className={`block mt-1 text-2xl font-black font-serif-title ${
          tone === 'warning' ? 'text-wood-600' : 'text-forest-900'
        }`}
      >
        {value}
      </span>
      {hint && <span className="text-xs text-ink-600 block mt-0.5">{hint}</span>}
    </>
  );
  const cls = 'sherwood-card p-4 text-left w-full';
  return onClick ? (
    <button
      type="button"
      onClick={onClick}
      className={`${cls} hover:bg-sand-100 transition-colors cursor-pointer`}
    >
      {body}
    </button>
  ) : (
    <div className={cls}>{body}</div>
  );
};

const CardTitle: React.FC<{
  title: string;
  hint?: string;
  action?: { label: string; onClick: () => void };
}> = ({ title, hint, action }) => (
  <div className="flex items-start justify-between gap-3 pb-2 border-b border-sand-200">
    <div>
      <h3 className="font-bold text-sm text-forest-900 font-serif-title">{title}</h3>
      {hint && <p className="text-xs text-ink-600 mt-0.5">{hint}</p>}
    </div>
    {action && (
      <button
        type="button"
        onClick={action.onClick}
        className="touch-btn text-xs font-bold text-forest-800 hover:underline cursor-pointer shrink-0"
      >
        {action.label}
      </button>
    )}
  </div>
);

const EmptyState: React.FC<{ text: string }> = ({ text }) => (
  <p className="py-6 text-center text-xs text-ink-600">{text}</p>
);

export const DashboardView: React.FC = () => {
  const { sales, products, categories, setActiveView } = usePos();
  const [selectedPeriod, setSelectedPeriod] = useState<TimePeriod>('today');
  const [chartTab, setChartTab] = useState<'d3-trend' | 'bar-breakdown'>('d3-trend');

  // Ventes valides, de la plus récente à la plus ancienne (hors ventes annulées)
  const validSales = useMemo(
    () =>
      sales
        .filter((s) => s.status !== 'CANCELLED')
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
    [sales]
  );

  // Ventes filtrées selon la période sélectionnée (Aujourd'hui, 7 jours, 30 jours)
  const periodSales = useMemo(() => {
    const now = new Date();
    const todayYear = now.getFullYear();
    const todayMonth = now.getMonth();
    const todayDate = now.getDate();

    if (selectedPeriod === 'today') {
      return validSales.filter((s) => {
        const d = new Date(s.createdAt);
        return (
          d.getFullYear() === todayYear &&
          d.getMonth() === todayMonth &&
          d.getDate() === todayDate
        );
      });
    }

    const cutoff = new Date(now);
    if (selectedPeriod === 'week') {
      cutoff.setDate(cutoff.getDate() - 7);
    } else {
      cutoff.setDate(cutoff.getDate() - 30);
    }
    cutoff.setHours(0, 0, 0, 0);

    return validSales.filter((s) => new Date(s.createdAt) >= cutoff);
  }, [validSales, selectedPeriod]);

  // 4 KPIs réels calculés en direct sur la période choisie
  const periodStats = useMemo(() => {
    const revenue = periodSales.reduce((sum, s) => sum + s.totalTTC, 0);
    const salesCount = periodSales.length;
    const averageBasket = salesCount > 0 ? Math.round(revenue / salesCount) : 0;
    const itemsSold = periodSales.reduce(
      (sum, s) => sum + s.items.reduce((iSum, it) => iSum + it.quantity, 0),
      0
    );
    // Le stock sous seuil d'alerte reste l'état réel et actuel de l'inventaire
    const lowStockCount = products.filter((p) => p.stock <= p.lowStockThreshold).length;

    return {
      revenue: Math.round(revenue),
      salesCount,
      averageBasket,
      itemsSold,
      lowStockCount,
    };
  }, [periodSales, products]);

  // Répartition des ventes par catégorie sur la période sélectionnée
  const categoryStats = useMemo(() => {
    const productCategory = new Map(products.map((p) => [p.id, p.categoryId]));
    const revenueByCat = new Map<number, number>();

    periodSales.slice(0, 100).forEach((sale) =>
      sale.items.forEach((item) => {
        const catId = productCategory.get(item.productId);
        if (catId !== undefined) {
          revenueByCat.set(catId, (revenueByCat.get(catId) ?? 0) + item.totalTTC);
        }
      })
    );

    const total = Array.from(revenueByCat.values()).reduce((a, b) => a + b, 0);
    return categories
      .map((cat) => {
        const revenue = revenueByCat.get(cat.id) ?? 0;
        return {
          id: cat.id,
          name: cat.name,
          revenue,
          percentage: total > 0 ? Math.round((revenue / total) * 100) : 0,
        };
      })
      .filter((c) => c.revenue > 0)
      .sort((a, b) => b.revenue - a.revenue);
  }, [categories, products, periodSales]);

  // Top 5 produits les plus vendus sur la période sélectionnée
  const topProducts = useMemo(() => {
    const map = new Map<number, { name: string; sku: string; units: number; revenue: number }>();
    periodSales.forEach((s) =>
      s.items.forEach((it) => {
        const cur = map.get(it.productId) ?? {
          name: it.productName,
          sku: it.sku,
          units: 0,
          revenue: 0,
        };
        cur.units += it.quantity;
        cur.revenue += it.totalTTC;
        map.set(it.productId, cur);
      })
    );
    return Array.from(map.entries())
      .map(([id, v]) => ({ id, ...v }))
      .sort((a, b) => b.units - a.units)
      .slice(0, 5);
  }, [periodSales]);

  // Top 5 clients sur la période sélectionnée
  const topCustomers = useMemo(() => {
    const map = new Map<string, { name: string; tickets: number; revenue: number }>();
    periodSales.forEach((s) => {
      if (s.customerId === undefined || !s.customerName) return;
      const key = String(s.customerId);
      const cur = map.get(key) ?? { name: s.customerName, tickets: 0, revenue: 0 };
      cur.tickets += 1;
      cur.revenue += s.totalTTC;
      map.set(key, cur);
    });
    return Array.from(map.entries())
      .map(([id, v]) => ({ id, ...v }))
      .sort((a, b) => b.revenue - a.revenue)
      .slice(0, 5);
  }, [periodSales]);

  const recentSales = periodSales.slice(0, 5);
  const activePeriodConfig = PERIOD_CONFIG[selectedPeriod];

  return (
    <div className="space-y-6">
      {/* Header avec sélecteur temporel (Loi de Hick : 3 choix clairs, Loi de Fitts : cibles 44px) */}
      <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4">
        <div>
          <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-forest-900 font-serif-title">
            Tableau de bord
          </h2>
          <p className="text-xs text-ink-600 mt-0.5">
            Performance réelle de la caisse • Période :{' '}
            <strong className="text-forest-900 font-bold">
              {activePeriodConfig.rangeLabel}
            </strong>
          </p>
        </div>

        <div className="flex flex-wrap items-center gap-3">
          {/* Options de filtrage temporel : Aujourd'hui, Semaine, Mois */}
          <div
            role="radiogroup"
            aria-label="Période d'analyse"
            className="inline-flex p-1 bg-sand-200 rounded-2xl text-xs font-bold border border-sand-300 shadow-2xs"
          >
            {(['today', 'week', 'month'] as TimePeriod[]).map((periodKey) => {
              const isSelected = selectedPeriod === periodKey;
              const config = PERIOD_CONFIG[periodKey];

              return (
                <button
                  key={periodKey}
                  type="button"
                  role="radio"
                  aria-checked={isSelected}
                  onClick={() => setSelectedPeriod(periodKey)}
                  className={`touch-btn px-3.5 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
                    isSelected
                      ? 'bg-forest-800 text-sand-50 font-bold shadow-xs'
                      : 'text-ink-700 hover:text-forest-900 hover:bg-sand-100'
                  }`}
                  title={`Filtrer par : ${config.rangeLabel}`}
                >
                  <Calendar className="w-3.5 h-3.5" />
                  <span>{config.label}</span>
                </button>
              );
            })}
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setActiveView('pos')}
              className="touch-btn px-4 bg-forest-700 hover:bg-forest-800 text-sand-50 font-bold text-sm rounded-2xl shadow-md flex items-center gap-2 cursor-pointer"
            >
              <Store className="w-4 h-4" />
              <span>Ouvrir la caisse</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveView('catalog')}
              className="touch-btn px-4 bg-sand-50 hover:bg-sand-100 text-ink-900 font-semibold text-sm rounded-2xl border border-sand-300 flex items-center gap-2 cursor-pointer"
            >
              <Package className="w-4 h-4" />
              <span>Catalogue</span>
            </button>
          </div>
        </div>
      </div>

      {/* 4 Cartes de chiffres réels : adaptées à la période sélectionnée */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        <Kpi
          label={`Chiffre d'affaires (${activePeriodConfig.label})`}
          value={formatMoney(periodStats.revenue)}
          hint={activePeriodConfig.rangeLabel}
          onClick={() => setActiveView('sales')}
        />
        <Kpi
          label={`Tickets (${activePeriodConfig.label})`}
          value={String(periodStats.salesCount)}
          hint={`${periodStats.itemsSold} article${
            periodStats.itemsSold > 1 ? 's' : ''
          } vendu${periodStats.itemsSold > 1 ? 's' : ''}`}
          onClick={() => setActiveView('sales')}
        />
        <Kpi
          label="Panier moyen"
          value={formatMoney(periodStats.averageBasket)}
          hint={
            periodStats.salesCount > 0
              ? `Sur ${periodStats.salesCount} ticket${
                  periodStats.salesCount > 1 ? 's' : ''
                }`
              : 'Aucun ticket'
          }
        />
        <Kpi
          label="Stock à surveiller"
          value={String(periodStats.lowStockCount)}
          hint={
            periodStats.lowStockCount > 0
              ? 'Produits sous le seuil d’alerte'
              : 'Aucune alerte'
          }
          tone={periodStats.lowStockCount > 0 ? 'warning' : 'default'}
          onClick={() => setActiveView('catalog')}
        />
      </div>

      {/* Alerte de stock si nécessaire */}
      {periodStats.lowStockCount > 0 && <InventoryAlertWidget />}

      {/* Graphiques interactifs */}
      <div className="space-y-3">
        <div
          className="inline-flex p-1 bg-sand-200 rounded-2xl text-sm font-semibold"
          role="tablist"
          aria-label="Type de graphique"
        >
          <button
            type="button"
            role="tab"
            aria-selected={chartTab === 'd3-trend'}
            onClick={() => setChartTab('d3-trend')}
            className={`touch-btn px-4 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
              chartTab === 'd3-trend'
                ? 'bg-forest-800 text-sand-50 font-bold shadow-xs'
                : 'text-ink-700 hover:text-forest-900'
            }`}
          >
            <TrendingUp className="w-4 h-4" />
            <span>
              {selectedPeriod === 'month' ? 'Tendance 30 jours' : 'Tendance 7 jours'}
            </span>
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={chartTab === 'bar-breakdown'}
            onClick={() => setChartTab('bar-breakdown')}
            className={`touch-btn px-4 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
              chartTab === 'bar-breakdown'
                ? 'bg-forest-800 text-sand-50 font-bold shadow-xs'
                : 'text-ink-700 hover:text-forest-900'
            }`}
          >
            <Layers className="w-4 h-4" />
            <span>Détail journalier</span>
          </button>
        </div>

        {chartTab === 'd3-trend' ? (
          <D3RevenueTrendChart days={selectedPeriod === 'month' ? 30 : 7} />
        ) : (
          <DailyRevenueChart />
        )}
      </div>

      {/* 4 Blocs d'analyse par période */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5">
        {/* Dernières ventes de la période */}
        <section className="sherwood-card p-5 space-y-3">
          <CardTitle
            title={`Dernières ventes (${activePeriodConfig.label})`}
            hint={activePeriodConfig.rangeLabel}
            action={{ label: 'Tout voir', onClick: () => setActiveView('sales') }}
          />
          {recentSales.length === 0 ? (
            <EmptyState
              text={`Aucune vente enregistrée sur cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ul className="divide-y divide-sand-200">
              {recentSales.map((s) => (
                <li
                  key={s.id}
                  className="py-2.5 flex items-center justify-between gap-3 text-sm"
                >
                  <div className="min-w-0">
                    <div className="font-bold text-forest-900 truncate">
                      {s.saleNumber}
                    </div>
                    <div className="text-xs text-ink-600 truncate">
                      {s.customerName || 'Client comptoir'} ·{' '}
                      {PAYMENT_LABELS[s.paymentMethod]} · {formatSaleDate(s.createdAt)}
                    </div>
                  </div>
                  <div className="font-bold text-forest-900 shrink-0 font-mono">
                    {formatMoney(s.totalTTC)}
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Produits les plus vendus de la période */}
        <section className="sherwood-card p-5 space-y-3">
          <CardTitle
            title={`Produits les plus vendus (${activePeriodConfig.label})`}
            hint={activePeriodConfig.rangeLabel}
            action={{ label: 'Catalogue', onClick: () => setActiveView('catalog') }}
          />
          {topProducts.length === 0 ? (
            <EmptyState
              text={`Aucun produit vendu sur cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ol className="divide-y divide-sand-200">
              {topProducts.map((p, idx) => (
                <li
                  key={p.id}
                  className="py-2.5 flex items-center justify-between gap-3 text-sm"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-6 h-6 rounded-full bg-sand-200 text-ink-700 font-bold text-xs flex items-center justify-center shrink-0">
                      {idx + 1}
                    </span>
                    <div className="min-w-0">
                      <div className="font-bold text-forest-900 truncate">{p.name}</div>
                      <div className="text-xs text-ink-600 font-mono">{p.sku}</div>
                    </div>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="font-bold text-forest-900">
                      {p.units} vendu{p.units > 1 ? 's' : ''}
                    </div>
                    <div className="text-xs text-ink-600 font-mono">
                      {formatMoney(p.revenue)}
                    </div>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </section>

        {/* Ventes par rayon sur la période */}
        <section className="sherwood-card p-5 space-y-3">
          <CardTitle
            title={`Ventes par rayon (${activePeriodConfig.label})`}
            hint={`Répartition du chiffre d'affaires (${activePeriodConfig.rangeLabel.toLowerCase()})`}
          />
          {categoryStats.length === 0 ? (
            <EmptyState
              text={`Aucune répartition disponible pour cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ul className="space-y-3 pt-1">
              {categoryStats.map((c) => (
                <li key={c.id} className="text-sm">
                  <div className="flex items-center justify-between">
                    <span className="font-semibold text-forest-900">{c.name}</span>
                    <span className="text-ink-700 font-mono text-xs">
                      {formatMoney(c.revenue)} · {c.percentage} %
                    </span>
                  </div>
                  <div
                    className="mt-1 h-2 rounded-full bg-sand-200 overflow-hidden"
                    role="presentation"
                  >
                    <div
                      className="h-full rounded-full bg-forest-700 transition-all duration-300"
                      style={{ width: `${c.percentage}%` }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Meilleurs clients sur la période */}
        <section className="sherwood-card p-5 space-y-3">
          <CardTitle
            title={`Meilleurs clients (${activePeriodConfig.label})`}
            hint={activePeriodConfig.rangeLabel}
            action={{ label: 'Clients', onClick: () => setActiveView('customers') }}
          />
          {topCustomers.length === 0 ? (
            <EmptyState
              text={`Aucun client associé à une vente sur cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ol className="divide-y divide-sand-200">
              {topCustomers.map((c, idx) => (
                <li
                  key={c.id}
                  className="py-2.5 flex items-center justify-between gap-3 text-sm"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-6 h-6 rounded-full bg-sand-200 text-ink-700 font-bold text-xs flex items-center justify-center shrink-0">
                      {idx + 1}
                    </span>
                    <span className="font-bold text-forest-900 truncate">{c.name}</span>
                  </div>
                  <div className="text-right shrink-0">
                    <div className="font-bold text-forest-900 font-mono">
                      {formatMoney(c.revenue)}
                    </div>
                    <div className="text-xs text-ink-600">
                      {c.tickets} ticket{c.tickets > 1 ? 's' : ''}
                    </div>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </section>
      </div>

      {periodStats.lowStockCount === 0 && (
        <p className="flex items-center gap-2 text-xs text-ink-600">
          <AlertTriangle className="w-3.5 h-3.5" aria-hidden="true" />
          <span>
            Aucune alerte de stock : tous les produits sont au-dessus de leur seuil minimal.
          </span>
        </p>
      )}
    </div>
  );
};
