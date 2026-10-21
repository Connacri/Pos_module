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
  Receipt,
  Banknote,
  CheckCircle2,
  Users,
  ChevronRight,
  Clock,
  ArrowUpRight,
  Tag,
} from 'lucide-react';
import type { PaymentMethod } from '../../types';

export type TimePeriod = 'today' | 'week' | 'month';

const PAYMENT_LABELS: Record<PaymentMethod, { label: string; badgeCls: string }> = {
  CASH: { label: 'Espèces', badgeCls: 'bg-emerald-100 text-emerald-800 border-emerald-200' },
  CARD: { label: 'Carte CIB', badgeCls: 'bg-blue-100 text-blue-800 border-blue-200' },
  TRANSFER: { label: 'Virement', badgeCls: 'bg-purple-100 text-purple-800 border-purple-200' },
  CHEQUE: { label: 'Chèque', badgeCls: 'bg-amber-100 text-amber-800 border-amber-200' },
};

const PERIOD_CONFIG: Record<
  TimePeriod,
  { label: string; rangeLabel: string; hint: string }
> = {
  today: {
    label: "Aujourd'hui",
    rangeLabel: "Aujourd'hui",
    hint: 'Journée en cours (00h–24h)',
  },
  week: {
    label: '7 jours',
    rangeLabel: '7 derniers jours',
    hint: 'Semaine glissante',
  },
  month: {
    label: '30 jours',
    rangeLabel: '30 derniers jours',
    hint: 'Mois glissant complet',
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

interface KpiCardProps {
  label: string;
  value: string;
  periodBadge: string;
  hint: string;
  icon: React.FC<{ className?: string }>;
  iconBg: string;
  iconColor: string;
  tone?: 'default' | 'warning' | 'success';
  onClick?: () => void;
}

const KpiCard: React.FC<KpiCardProps> = ({
  label,
  value,
  periodBadge,
  hint,
  icon: Icon,
  iconBg,
  iconColor,
  tone = 'default',
  onClick,
}) => {
  const content = (
    <div className="flex flex-col h-full justify-between gap-3">
      {/* Top Header of Card: Icon + Period Chip */}
      <div className="flex items-center justify-between gap-2">
        <div
          className={`w-10 h-10 rounded-2xl flex items-center justify-center shrink-0 shadow-2xs ${iconBg} ${iconColor}`}
          aria-hidden="true"
        >
          <Icon className="w-5 h-5" />
        </div>
        <span className="text-[11px] font-bold tracking-tight text-ink-700 bg-sand-200/90 border border-sand-300 px-2.5 py-0.5 rounded-full shrink-0">
          {periodBadge}
        </span>
      </div>

      {/* Middle: Title + Value */}
      <div className="space-y-0.5">
        <span className="text-xs font-bold uppercase tracking-wider text-ink-600 block">
          {label}
        </span>
        <div
          className={`text-2xl sm:text-3xl font-black font-serif-title tracking-tight leading-tight truncate ${
            tone === 'warning'
              ? 'text-amber-800'
              : tone === 'success'
              ? 'text-forest-800'
              : 'text-forest-900'
          }`}
          title={value}
        >
          {value}
        </div>
      </div>

      {/* Bottom Hint */}
      <div className="pt-2 border-t border-sand-200 flex items-center justify-between text-xs text-ink-600 font-medium">
        <span className="truncate">{hint}</span>
        {onClick && (
          <ArrowUpRight className="w-3.5 h-3.5 text-forest-700 shrink-0 opacity-70 group-hover:opacity-100 group-hover:translate-x-0.5 transition-all" />
        )}
      </div>
    </div>
  );

  const containerCls = `sherwood-card p-4 sm:p-5 text-left w-full transition-all duration-200 group ${
    tone === 'warning'
      ? 'border-amber-300 bg-amber-50/40 hover:border-amber-400'
      : 'hover:border-sand-300 hover:shadow-md'
  }`;

  return onClick ? (
    <button
      type="button"
      onClick={onClick}
      className={`${containerCls} cursor-pointer focus-visible:ring-4 focus-visible:ring-forest-700/40`}
      aria-label={`${label} : ${value}, ${hint}`}
    >
      {content}
    </button>
  ) : (
    <div className={containerCls}>{content}</div>
  );
};

const SectionHeader: React.FC<{
  title: string;
  hint?: string;
  icon?: React.FC<{ className?: string }>;
  action?: { label: string; onClick: () => void };
}> = ({ title, hint, icon: Icon, action }) => (
  <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 pb-3 border-b border-sand-200">
    <div className="flex items-center gap-2.5">
      {Icon && (
        <div className="w-7 h-7 rounded-lg bg-sand-200 text-forest-800 flex items-center justify-center shrink-0">
          <Icon className="w-4 h-4" />
        </div>
      )}
      <div>
        <h3 className="font-bold text-sm text-forest-900 font-serif-title leading-tight">
          {title}
        </h3>
        {hint && <p className="text-xs text-ink-600 mt-0.5 leading-snug">{hint}</p>}
      </div>
    </div>
    {action && (
      <button
        type="button"
        onClick={action.onClick}
        className="touch-btn text-xs font-bold text-forest-800 hover:text-forest-900 hover:underline cursor-pointer shrink-0 self-end sm:self-auto flex items-center gap-1"
      >
        <span>{action.label}</span>
        <ChevronRight className="w-3.5 h-3.5" />
      </button>
    )}
  </div>
);

const EmptyState: React.FC<{ text: string }> = ({ text }) => (
  <div className="py-8 text-center text-xs text-ink-600 flex flex-col items-center justify-center gap-2">
    <div className="w-10 h-10 rounded-full bg-sand-100 flex items-center justify-center text-sand-300">
      <Package className="w-5 h-5" />
    </div>
    <p className="max-w-xs">{text}</p>
  </div>
);

export const DashboardView: React.FC = () => {
  const { sales, products, categories, setActiveView } = usePos();
  const [selectedPeriod, setSelectedPeriod] = useState<TimePeriod>('today');
  const [chartTab, setChartTab] = useState<'d3-trend' | 'bar-breakdown'>('d3-trend');

  // Ventes valides (hors ventes annulées), ordonnées de la plus récente à la plus ancienne
  const validSales = useMemo(
    () =>
      sales
        .filter((s) => s.status !== 'CANCELLED')
        .sort((a, b) => b.createdAt.localeCompare(a.createdAt)),
    [sales]
  );

  // Ventes filtrées dynamiquement selon la période sélectionnée
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

  // 4 KPIs calculés en direct sur la période choisie
  const periodStats = useMemo(() => {
    const revenue = periodSales.reduce((sum, s) => sum + s.totalTTC, 0);
    const salesCount = periodSales.length;
    const averageBasket = salesCount > 0 ? Math.round(revenue / salesCount) : 0;
    const itemsSold = periodSales.reduce(
      (sum, s) => sum + s.items.reduce((iSum, it) => iSum + it.quantity, 0),
      0
    );
    // Le stock d'alerte reste l'instantané de l'état actuel de l'inventaire
    const lowStockCount = products.filter((p) => p.stock <= p.lowStockThreshold).length;

    return {
      revenue: Math.round(revenue),
      salesCount,
      averageBasket,
      itemsSold,
      lowStockCount,
    };
  }, [periodSales, products]);

  // Répartition par rayon sur la période
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

  // Top 5 produits les plus vendus sur la période
  const topProducts = useMemo(() => {
    const map = new Map<
      number,
      { name: string; sku: string; units: number; revenue: number; imageUrl?: string }
    >();

    const prodMap = new Map(products.map((p) => [p.id, p]));

    periodSales.forEach((s) =>
      s.items.forEach((it) => {
        const fullProd = prodMap.get(it.productId);
        const cur = map.get(it.productId) ?? {
          name: it.productName,
          sku: it.sku,
          units: 0,
          revenue: 0,
          imageUrl: fullProd?.imageUrl,
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
  }, [periodSales, products]);

  // Top 5 clients sur la période
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
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* ============================================================
          TOP HERO TOOLBAR: Title + Time Period Filter Options
          Responsive Design: stacks gracefully on mobile, inline on desktop
          ============================================================ */}
      <div className="sherwood-card p-4 sm:p-5 flex flex-col md:flex-row md:items-center justify-between gap-4 border border-sand-200">
        <div className="space-y-1">
          <div className="inline-flex items-center gap-2 px-2.5 py-0.5 rounded-full bg-forest-100 text-forest-800 text-xs font-bold border border-forest-200">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
            <span>Données Réelles en Direct</span>
          </div>
          <h2 className="text-2xl sm:text-3xl font-black tracking-tight text-forest-900 font-serif-title">
            Tableau de bord
          </h2>
          <p className="text-xs text-ink-600 font-medium">
            Performances de caisse calculées sur :{' '}
            <strong className="text-forest-900 font-bold">
              {activePeriodConfig.rangeLabel}
            </strong>
          </p>
        </div>

        {/* Filter Toolbar (Loi de Hick : 3 choix évidents, Loi de Fitts : cibles >= 44px) */}
        <div className="flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
          <div
            role="radiogroup"
            aria-label="Période d'analyse des performances"
            className="grid grid-cols-3 p-1 bg-sand-200 rounded-2xl border border-sand-300 shadow-2xs gap-1"
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
                  className={`touch-btn px-3 py-2 rounded-xl text-xs font-bold transition-all cursor-pointer flex items-center justify-center gap-1.5 ${
                    isSelected
                      ? 'bg-forest-800 text-sand-50 shadow-xs'
                      : 'text-ink-700 hover:text-forest-900 hover:bg-sand-100'
                  }`}
                  title={`Analyser pour : ${config.rangeLabel}`}
                >
                  <Calendar className="w-3.5 h-3.5 shrink-0" />
                  <span className="whitespace-nowrap">{config.label}</span>
                </button>
              );
            })}
          </div>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={() => setActiveView('pos')}
              className="touch-btn flex-1 sm:flex-initial px-4 py-2 bg-forest-700 hover:bg-forest-800 text-sand-50 font-bold text-xs rounded-xl shadow-xs flex items-center justify-center gap-2 cursor-pointer transition-colors"
            >
              <Store className="w-4 h-4 shrink-0" />
              <span>Caisse</span>
            </button>
            <button
              type="button"
              onClick={() => setActiveView('catalog')}
              className="touch-btn flex-1 sm:flex-initial px-4 py-2 bg-sand-50 hover:bg-sand-100 text-ink-900 font-bold text-xs rounded-xl border border-sand-300 shadow-2xs flex items-center justify-center gap-2 cursor-pointer transition-colors"
            >
              <Package className="w-4 h-4 shrink-0" />
              <span>Articles</span>
            </button>
          </div>
        </div>
      </div>

      {/* ============================================================
          THE 4 REAL KPI CARDS: Fully Responsive & Perfectly Aligned
          Mobile: 1 column, Tablet: 2 columns, Desktop: 4 columns
          ============================================================ */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4 sm:gap-5">
        {/* KPI 1: Chiffre d'affaires */}
        <KpiCard
          label="Chiffre d'affaires"
          value={formatMoney(periodStats.revenue)}
          periodBadge={activePeriodConfig.label}
          hint={activePeriodConfig.hint}
          icon={Banknote}
          iconBg="bg-forest-100"
          iconColor="text-forest-800"
          tone="default"
          onClick={() => setActiveView('sales')}
        />

        {/* KPI 2: Tickets */}
        <KpiCard
          label="Tickets enregistrés"
          value={String(periodStats.salesCount)}
          periodBadge={activePeriodConfig.label}
          hint={`${periodStats.itemsSold} article${
            periodStats.itemsSold > 1 ? 's' : ''
          } vendu${periodStats.itemsSold > 1 ? 's' : ''}`}
          icon={Receipt}
          iconBg="bg-sand-200"
          iconColor="text-[#85522b]"
          tone="default"
          onClick={() => setActiveView('sales')}
        />

        {/* KPI 3: Panier moyen */}
        <KpiCard
          label="Panier moyen"
          value={formatMoney(periodStats.averageBasket)}
          periodBadge={activePeriodConfig.label}
          hint={
            periodStats.salesCount > 0
              ? `Sur ${periodStats.salesCount} vente${
                  periodStats.salesCount > 1 ? 's' : ''
                }`
              : 'Aucune transaction'
          }
          icon={TrendingUp}
          iconBg="bg-sand-200"
          iconColor="text-forest-800"
          tone="default"
        />

        {/* KPI 4: Stock sous seuil */}
        <KpiCard
          label="Stock à surveiller"
          value={String(periodStats.lowStockCount)}
          periodBadge="En direct"
          hint={
            periodStats.lowStockCount > 0
              ? 'Articles sous seuil minimal'
              : 'Tous les stocks conformes'
          }
          icon={AlertTriangle}
          iconBg={periodStats.lowStockCount > 0 ? 'bg-amber-100' : 'bg-emerald-100'}
          iconColor={periodStats.lowStockCount > 0 ? 'text-amber-800' : 'text-emerald-800'}
          tone={periodStats.lowStockCount > 0 ? 'warning' : 'success'}
          onClick={() => setActiveView('catalog')}
        />
      </div>

      {/* Alerte stock bien visible si des articles sont en rupture/seuil */}
      {periodStats.lowStockCount > 0 && <InventoryAlertWidget />}

      {/* ============================================================
          CHARTS SECTION: D3 Vector Trend (30d or 7d) & Daily Breakdown
          ============================================================ */}
      <div className="space-y-3">
        <div
          className="inline-flex p-1 bg-sand-200 rounded-2xl text-xs font-bold border border-sand-300"
          role="tablist"
          aria-label="Mode de visualisation graphique"
        >
          <button
            type="button"
            role="tab"
            aria-selected={chartTab === 'd3-trend'}
            onClick={() => setChartTab('d3-trend')}
            className={`touch-btn px-4 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
              chartTab === 'd3-trend'
                ? 'bg-forest-800 text-sand-50 font-bold shadow-xs'
                : 'text-ink-700 hover:text-forest-900'
            }`}
          >
            <TrendingUp className="w-4 h-4" />
            <span>
              {selectedPeriod === 'month' ? 'Courbe D3 (30 Jours)' : 'Courbe D3 (7 Jours)'}
            </span>
          </button>
          <button
            type="button"
            role="tab"
            aria-selected={chartTab === 'bar-breakdown'}
            onClick={() => setChartTab('bar-breakdown')}
            className={`touch-btn px-4 py-1.5 rounded-xl transition-all cursor-pointer flex items-center gap-1.5 ${
              chartTab === 'bar-breakdown'
                ? 'bg-forest-800 text-sand-50 font-bold shadow-xs'
                : 'text-ink-700 hover:text-forest-900'
            }`}
          >
            <Layers className="w-4 h-4" />
            <span>Histogramme Journalier</span>
          </button>
        </div>

        {chartTab === 'd3-trend' ? (
          <D3RevenueTrendChart days={selectedPeriod === 'month' ? 30 : 7} />
        ) : (
          <DailyRevenueChart />
        )}
      </div>

      {/* ============================================================
          THE 4 ANALYTIC DATA CARDS: Flawless Typography & Spacing
          ============================================================ */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-5 sm:gap-6">
        {/* Card 1: Dernières ventes */}
        <section className="sherwood-card p-4 sm:p-5 space-y-3">
          <SectionHeader
            title={`Dernières ventes (${activePeriodConfig.label})`}
            hint={activePeriodConfig.rangeLabel}
            icon={Receipt}
            action={{ label: 'Toutes les factures', onClick: () => setActiveView('sales') }}
          />

          {recentSales.length === 0 ? (
            <EmptyState
              text={`Aucune vente enregistrée sur cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ul className="divide-y divide-sand-200">
              {recentSales.map((s) => {
                const payInfo = PAYMENT_LABELS[s.paymentMethod];
                return (
                  <li
                    key={s.id}
                    className="py-3 flex items-center justify-between gap-3 text-xs hover:bg-sand-50/80 rounded-xl px-2 transition-colors"
                  >
                    <div className="min-w-0 space-y-1">
                      <div className="flex items-center gap-2">
                        <span className="font-mono font-bold text-forest-900 text-xs">
                          {s.saleNumber}
                        </span>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-md border ${payInfo.badgeCls}`}
                        >
                          {payInfo.label}
                        </span>
                      </div>
                      <div className="text-[11px] text-ink-600 flex items-center gap-1.5 truncate">
                        <span className="font-semibold text-ink-900">
                          {s.customerName || 'Client comptoir'}
                        </span>
                        <span>•</span>
                        <span className="flex items-center gap-1">
                          <Clock className="w-3 h-3 text-sand-300" />
                          {formatSaleDate(s.createdAt)}
                        </span>
                      </div>
                    </div>

                    <div className="text-right shrink-0">
                      <div className="font-black text-sm text-forest-900 font-mono">
                        {formatMoney(s.totalTTC)}
                      </div>
                      <div className="text-[10px] text-ink-600 font-medium">
                        {s.items.reduce((sum, it) => sum + it.quantity, 0)} article(s)
                      </div>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </section>

        {/* Card 2: Produits les plus vendus */}
        <section className="sherwood-card p-4 sm:p-5 space-y-3">
          <SectionHeader
            title={`Produits les plus vendus (${activePeriodConfig.label})`}
            hint={`Classement par volume (${activePeriodConfig.rangeLabel.toLowerCase()})`}
            icon={Package}
            action={{ label: 'Catalogue', onClick: () => setActiveView('catalog') }}
          />

          {topProducts.length === 0 ? (
            <EmptyState
              text={`Aucun article vendu sur cette période (${activePeriodConfig.rangeLabel.toLowerCase()}).`}
            />
          ) : (
            <ol className="divide-y divide-sand-200">
              {topProducts.map((p, idx) => (
                <li
                  key={p.id}
                  className="py-3 flex items-center justify-between gap-3 text-xs hover:bg-sand-50/80 rounded-xl px-2 transition-colors"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-7 h-7 rounded-xl bg-sand-200 text-forest-900 font-black text-xs flex items-center justify-center shrink-0 shadow-2xs font-mono">
                      {idx + 1}
                    </span>
                    <div className="min-w-0 space-y-0.5">
                      <div className="font-bold text-forest-900 text-xs truncate" title={p.name}>
                        {p.name}
                      </div>
                      <div className="text-[11px] text-ink-600 font-mono flex items-center gap-2">
                        <span>{p.sku}</span>
                        <span>•</span>
                        <span className="font-bold text-forest-800 bg-forest-100 px-1.5 py-0.2 rounded">
                          {p.units} unité{p.units > 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="text-right shrink-0">
                    <div className="font-black text-xs text-forest-900 font-mono">
                      {formatMoney(p.revenue)}
                    </div>
                    <div className="text-[10px] text-ink-600">Total généré</div>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </section>

        {/* Card 3: Ventes par rayon */}
        <section className="sherwood-card p-4 sm:p-5 space-y-3">
          <SectionHeader
            title={`Ventes par rayon (${activePeriodConfig.label})`}
            hint={`Part de chiffre d'affaires (${activePeriodConfig.rangeLabel.toLowerCase()})`}
            icon={Tag}
          />

          {categoryStats.length === 0 ? (
            <EmptyState
              text={`Aucune vente par rayon disponible pour ${activePeriodConfig.rangeLabel.toLowerCase()}.`}
            />
          ) : (
            <ul className="space-y-3.5 pt-1">
              {categoryStats.map((c) => (
                <li key={c.id} className="space-y-1.5 text-xs">
                  <div className="flex items-center justify-between">
                    <span className="font-bold text-forest-900">{c.name}</span>
                    <div className="text-right font-mono flex items-center gap-2">
                      <span className="font-bold text-forest-800">{formatMoney(c.revenue)}</span>
                      <span className="text-[11px] font-bold text-ink-600 bg-sand-200 px-1.5 py-0.2 rounded-md">
                        {c.percentage} %
                      </span>
                    </div>
                  </div>
                  <div
                    className="h-2.5 rounded-full bg-sand-200 overflow-hidden"
                    role="progressbar"
                    aria-valuenow={c.percentage}
                    aria-valuemin={0}
                    aria-valuemax={100}
                    aria-label={`Pourcentage de vente : ${c.name} (${c.percentage}%)`}
                  >
                    <div
                      className="h-full rounded-full bg-forest-700 transition-all duration-300"
                      style={{ width: `${Math.max(4, c.percentage)}%` }}
                    />
                  </div>
                </li>
              ))}
            </ul>
          )}
        </section>

        {/* Card 4: Meilleurs clients */}
        <section className="sherwood-card p-4 sm:p-5 space-y-3">
          <SectionHeader
            title={`Meilleurs clients (${activePeriodConfig.label})`}
            hint={`Fidélité et dépenses (${activePeriodConfig.rangeLabel.toLowerCase()})`}
            icon={Users}
            action={{ label: 'Fichier clients', onClick: () => setActiveView('customers') }}
          />

          {topCustomers.length === 0 ? (
            <EmptyState
              text={`Aucun client associé à une vente pour ${activePeriodConfig.rangeLabel.toLowerCase()}.`}
            />
          ) : (
            <ol className="divide-y divide-sand-200">
              {topCustomers.map((c, idx) => (
                <li
                  key={c.id}
                  className="py-3 flex items-center justify-between gap-3 text-xs hover:bg-sand-50/80 rounded-xl px-2 transition-colors"
                >
                  <div className="flex items-center gap-3 min-w-0">
                    <span className="w-7 h-7 rounded-xl bg-sand-200 text-forest-900 font-black text-xs flex items-center justify-center shrink-0 shadow-2xs font-mono">
                      {idx + 1}
                    </span>
                    <div className="min-w-0 space-y-0.5">
                      <div className="font-bold text-forest-900 text-xs truncate" title={c.name}>
                        {c.name}
                      </div>
                      <div className="text-[11px] text-ink-600">
                        <span className="bg-sand-200 text-ink-800 font-bold px-1.5 py-0.2 rounded-md">
                          {c.tickets} ticket{c.tickets > 1 ? 's' : ''}
                        </span>
                      </div>
                    </div>
                  </div>

                  <div className="text-right shrink-0">
                    <div className="font-black text-xs text-forest-900 font-mono">
                      {formatMoney(c.revenue)}
                    </div>
                    <div className="text-[10px] text-ink-600">Total dépensé</div>
                  </div>
                </li>
              ))}
            </ol>
          )}
        </section>
      </div>

      {periodStats.lowStockCount === 0 && (
        <p className="flex items-center gap-2 text-xs text-ink-600 bg-sand-100/60 p-3 rounded-2xl border border-sand-200">
          <CheckCircle2 className="w-4 h-4 text-emerald-600 shrink-0" aria-hidden="true" />
          <span>
            Tous les stocks de la boutique sont au-dessus de leur seuil minimal de sécurité.
          </span>
        </p>
      )}
    </div>
  );
};
