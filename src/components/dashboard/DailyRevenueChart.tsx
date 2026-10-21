import React, { useState } from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Cell,
} from 'recharts';
import { usePos } from '../../context/PosContext';
import { TrendingUp, Calendar, DollarSign, ShoppingBag, Layers } from 'lucide-react';

export const DailyRevenueChart: React.FC = () => {
  const { dailyStats } = usePos();
  const [metric, setMetric] = useState<'revenue' | 'profit' | 'orders' | 'unitsSold'>('revenue');
  const [daysCount, setDaysCount] = useState<7 | 14>(14);

  const displayedData = dailyStats.slice(-daysCount);

  // Compute total for displayed period
  const totalPeriodRevenue = displayedData.reduce((acc, curr) => acc + curr.revenue, 0);
  const totalPeriodProfit = displayedData.reduce((acc, curr) => acc + curr.profit, 0);
  const totalPeriodOrders = displayedData.reduce((acc, curr) => acc + curr.orders, 0);

  // Format currency in DA (Algerian Dinars)
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  const getMetricColor = (index: number, total: number) => {
    const isToday = index === total - 1;
    if (metric === 'profit') {
      return isToday ? '#6d3e1d' : '#9c663b';
    }
    if (metric === 'orders' || metric === 'unitsSold') {
      return isToday ? '#85522b' : '#b28157';
    }
    // Revenue
    return isToday ? '#1f3d29' : '#3b6f4c';
  };

  return (
    <div className="sherwood-card p-5 sm:p-6 space-y-5">
      {/* Header with Title, Period and Metric selector */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-sand-200">
        <div className="flex items-center gap-3">
          <div className="w-9 h-9 rounded-xl bg-sand-100 text-forest-800 flex items-center justify-center font-bold border border-sand-200">
            <TrendingUp className="w-5 h-5" />
          </div>
          <div>
            <h3 className="text-base font-extrabold text-forest-900 font-serif-title leading-tight">
              Évolution Quotidienne des Ventes
            </h3>
            <p className="text-xs text-ink-600 mt-0.5">
              Historique journalier sur les transactions encaissées
            </p>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Metric tabs */}
          <div className="inline-flex items-center bg-sand-100 p-1 rounded-xl text-xs font-semibold text-ink-700 border border-sand-200">
            <button
              type="button"
              onClick={() => setMetric('revenue')}
              className={`touch-btn px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                metric === 'revenue'
                  ? 'bg-forest-800 text-sand-50 shadow-xs font-bold'
                  : 'hover:text-forest-900'
              }`}
            >
              Chiffre d'Affaires
            </button>
            <button
              type="button"
              onClick={() => setMetric('profit')}
              className={`touch-btn px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                metric === 'profit'
                  ? 'bg-forest-800 text-sand-50 shadow-xs font-bold'
                  : 'hover:text-forest-900'
              }`}
            >
              Marge
            </button>
            <button
              type="button"
              onClick={() => setMetric('orders')}
              className={`touch-btn px-3 py-1.5 rounded-lg transition-all cursor-pointer ${
                metric === 'orders'
                  ? 'bg-forest-800 text-sand-50 shadow-xs font-bold'
                  : 'hover:text-forest-900'
              }`}
            >
              Tickets
            </button>
          </div>

          {/* Time range selector */}
          <div className="inline-flex items-center bg-sand-100 p-1 rounded-xl text-xs font-semibold text-ink-700 border border-sand-200">
            <button
              type="button"
              onClick={() => setDaysCount(7)}
              className={`touch-btn px-2.5 py-1.5 rounded-lg transition-all cursor-pointer ${
                daysCount === 7
                  ? 'bg-forest-800 text-sand-50 shadow-xs font-bold'
                  : 'hover:text-forest-900'
              }`}
            >
              7 j
            </button>
            <button
              type="button"
              onClick={() => setDaysCount(14)}
              className={`touch-btn px-2.5 py-1.5 rounded-lg transition-all cursor-pointer ${
                daysCount === 14
                  ? 'bg-forest-800 text-sand-50 shadow-xs font-bold'
                  : 'hover:text-forest-900'
              }`}
            >
              14 j
            </button>
          </div>
        </div>
      </div>

      {/* Mini Summary Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 p-3.5 bg-sand-50 rounded-xl border border-sand-200/80 text-xs">
        <div className="flex items-center gap-3 min-w-0">
          <div className="p-2 rounded-xl bg-sand-100 text-forest-800 shrink-0 border border-sand-200">
            <DollarSign className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="text-ink-600 text-xs font-medium truncate">Revenu cumulé ({daysCount} j)</div>
            <div className="font-extrabold text-forest-900 text-sm font-mono tabular-nums truncate">
              {formatMoney(totalPeriodRevenue)}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 min-w-0">
          <div className="p-2 rounded-xl bg-sand-100 text-wood-600 shrink-0 border border-sand-200">
            <Layers className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="text-ink-600 text-xs font-medium truncate">Marge brute estimée</div>
            <div className="font-extrabold text-forest-900 text-sm font-mono tabular-nums truncate">
              {formatMoney(totalPeriodProfit)}
            </div>
          </div>
        </div>

        <div className="flex items-center gap-3 min-w-0">
          <div className="p-2 rounded-xl bg-sand-100 text-forest-800 shrink-0 border border-sand-200">
            <ShoppingBag className="w-4 h-4" />
          </div>
          <div className="min-w-0">
            <div className="text-ink-600 text-xs font-medium truncate">Tickets enregistrés</div>
            <div className="font-extrabold text-forest-900 text-sm font-mono tabular-nums truncate">
              {totalPeriodOrders} tickets
            </div>
          </div>
        </div>
      </div>

      {/* Bar Chart Container */}
      <div className="h-[280px] w-full">
        <ResponsiveContainer width="100%" height="100%">
          <BarChart
            data={displayedData}
            margin={{ top: 10, right: 10, left: 0, bottom: 0 }}
          >
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#e7ddca" />
            <XAxis
              dataKey="formattedDate"
              tickLine={false}
              axisLine={{ stroke: '#dfd2be' }}
              tick={{ fill: '#6b5c4c', fontSize: 11 }}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              tick={{ fill: '#6b5c4c', fontSize: 11 }}
              tickFormatter={(val) => {
                if (metric === 'revenue' || metric === 'profit') {
                  return val >= 1000 ? `${Math.round(val / 1000)}k` : `${val}`;
                }
                return `${val}`;
              }}
            />
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const data = payload[0].payload;
                  return (
                    <div className="bg-[#1f3d29] text-[#fdfbf7] px-3.5 py-2.5 rounded-xl shadow-xl text-xs space-y-1 border border-[#2d563a]">
                      <div className="font-semibold text-sand-50 border-b border-forest-800 pb-1 flex items-center justify-between gap-4">
                        <span>{data.formattedDate}</span>
                        <span className="text-[10px] text-emerald-300 font-mono">
                          {data.date}
                        </span>
                      </div>
                      <div className="flex justify-between gap-4 pt-1">
                        <span className="text-sand-200">Chiffre d'Affaires :</span>
                        <span className="font-bold text-white font-mono">{formatMoney(data.revenue)}</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-emerald-300">Marge brute :</span>
                        <span className="font-semibold text-emerald-200 font-mono">{formatMoney(data.profit)}</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-sand-200">Transactions :</span>
                        <span className="font-medium text-white">{data.orders} tickets</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-sand-200">Articles vendus :</span>
                        <span className="font-medium text-white">{data.unitsSold} unités</span>
                      </div>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar
              dataKey={metric}
              radius={[6, 6, 0, 0]}
              animationDuration={800}
            >
              {displayedData.map((_, index) => (
                <Cell
                  key={`cell-${index}`}
                  fill={getMetricColor(index, displayedData.length)}
                  className="transition-opacity hover:opacity-85 cursor-pointer"
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Legend & hint */}
      <div className="mt-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs text-ink-600 pt-3 border-t border-sand-200">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#3b6f4c] inline-block"></span>
            <span>Jours précédents</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-[#1f3d29] inline-block"></span>
            <span className="font-semibold text-forest-900">Aujourd'hui (En direct)</span>
          </div>
        </div>
        <div className="text-xs text-ink-600 flex items-center gap-1">
          <Calendar className="w-3.5 h-3.5 text-sand-300" />
          <span>Synchronisé en temps réel avec les encaissements</span>
        </div>
      </div>
    </div>
  );
};
