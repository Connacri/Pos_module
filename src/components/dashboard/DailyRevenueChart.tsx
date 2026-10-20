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
      style: 'currency',
      currency: 'DZD',
      maximumFractionDigits: 0,
    }).format(val).replace('DZD', 'DA');
  };

  const getMetricColor = (index: number, total: number) => {
    // Highlight the latest bar (today)
    if (index === total - 1) return '#2563eb'; // blue-600
    if (metric === 'profit') return '#10b981'; // emerald-500
    if (metric === 'orders') return '#f59e0b'; // amber-500
    return '#60a5fa'; // blue-400
  };

  return (
    <div className="bg-white/90 backdrop-blur-xl rounded-3xl p-5 sm:p-6 border border-white shadow-xs">
      {/* Header with Title, Period and Metric selector */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-6">
        <div>
          <div className="flex items-center gap-2.5">
            <div className="w-9 h-9 rounded-2xl bg-blue-50 text-blue-600 flex items-center justify-center font-bold">
              <TrendingUp className="w-5 h-5" />
            </div>
            <div>
              <h3 className="text-base sm:text-lg font-extrabold text-slate-800">
                Évolution Quotidienne des Revenus
              </h3>
              <p className="text-xs text-slate-500">
                Analyse des ventes journalières et performance de la caisse
              </p>
            </div>
          </div>
        </div>

        <div className="flex flex-wrap items-center gap-2">
          {/* Metric tabs */}
          <div className="inline-flex items-center bg-slate-100 p-1 rounded-2xl text-xs font-semibold text-slate-600">
            <button
              type="button"
              onClick={() => setMetric('revenue')}
              className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                metric === 'revenue'
                  ? 'bg-white text-blue-600 shadow-2xs font-bold'
                  : 'hover:text-slate-900'
              }`}
            >
              Chiffre d'Affaires
            </button>
            <button
              type="button"
              onClick={() => setMetric('profit')}
              className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                metric === 'profit'
                  ? 'bg-white text-emerald-600 shadow-2xs font-bold'
                  : 'hover:text-slate-900'
              }`}
            >
              Marge
            </button>
            <button
              type="button"
              onClick={() => setMetric('orders')}
              className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                metric === 'orders'
                  ? 'bg-white text-amber-600 shadow-2xs font-bold'
                  : 'hover:text-slate-900'
              }`}
            >
              Ventes
            </button>
          </div>

          {/* Time range selector */}
          <div className="inline-flex items-center bg-slate-100 p-1 rounded-2xl text-xs font-semibold text-slate-600">
            <button
              type="button"
              onClick={() => setDaysCount(7)}
              className={`px-2.5 py-1.5 rounded-xl transition-all cursor-pointer ${
                daysCount === 7
                  ? 'bg-white text-slate-900 shadow-2xs font-bold'
                  : 'hover:text-slate-900'
              }`}
            >
              7 j
            </button>
            <button
              type="button"
              onClick={() => setDaysCount(14)}
              className={`px-2.5 py-1.5 rounded-xl transition-all cursor-pointer ${
                daysCount === 14
                  ? 'bg-white text-slate-900 shadow-2xs font-bold'
                  : 'hover:text-slate-900'
              }`}
            >
              14 j
            </button>
          </div>
        </div>
      </div>

      {/* Mini Summary Row */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 mb-6 p-3 bg-slate-50/80 rounded-2xl border border-slate-100 text-xs">
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-blue-100 text-blue-700">
            <DollarSign className="w-4 h-4" />
          </div>
          <div>
            <div className="text-slate-500 text-[11px] font-medium">Revenu sur {daysCount} jours</div>
            <div className="font-extrabold text-slate-900 text-sm">
              {formatMoney(totalPeriodRevenue)}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-emerald-100 text-emerald-700">
            <Layers className="w-4 h-4" />
          </div>
          <div>
            <div className="text-slate-500 text-[11px] font-medium">Marge brute estimée</div>
            <div className="font-extrabold text-slate-900 text-sm">
              {formatMoney(totalPeriodProfit)}
            </div>
          </div>
        </div>
        <div className="flex items-center gap-2.5">
          <div className="p-2 rounded-xl bg-amber-100 text-amber-700">
            <ShoppingBag className="w-4 h-4" />
          </div>
          <div>
            <div className="text-slate-500 text-[11px] font-medium">Transactions enregistrées</div>
            <div className="font-extrabold text-slate-900 text-sm">
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
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
            <XAxis
              dataKey="formattedDate"
              tickLine={false}
              axisLine={{ stroke: '#e2e8f0' }}
              tick={{ fill: '#64748b', fontSize: 11 }}
            />
            <YAxis
              tickLine={false}
              axisLine={false}
              tick={{ fill: '#64748b', fontSize: 11 }}
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
                    <div className="bg-slate-900 text-white px-3.5 py-2.5 rounded-2xl shadow-xl text-xs space-y-1 border border-slate-700">
                      <div className="font-semibold text-slate-200 border-b border-slate-700 pb-1 flex items-center justify-between gap-4">
                        <span>{data.formattedDate}</span>
                        <span className="text-[10px] text-blue-400 uppercase font-mono tracking-wider">
                          {data.date}
                        </span>
                      </div>
                      <div className="flex justify-between gap-4 pt-1">
                        <span className="text-slate-400">Chiffre d'Affaires:</span>
                        <span className="font-bold text-white">{formatMoney(data.revenue)}</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-emerald-400">Marge brute:</span>
                        <span className="font-semibold text-emerald-300">{formatMoney(data.profit)}</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-amber-400">Transactions:</span>
                        <span className="font-medium text-white">{data.orders} tickets</span>
                      </div>
                      <div className="flex justify-between gap-4">
                        <span className="text-blue-300">Articles vendus:</span>
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
                  className="transition-opacity hover:opacity-80 cursor-pointer"
                />
              ))}
            </Bar>
          </BarChart>
        </ResponsiveContainer>
      </div>

      {/* Legend & hint */}
      <div className="mt-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs text-slate-500 pt-3 border-t border-slate-100">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-blue-400 inline-block"></span>
            <span>Jours précédents</span>
          </div>
          <div className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-full bg-blue-600 inline-block"></span>
            <span className="font-semibold text-slate-700">Aujourd'hui (En direct)</span>
          </div>
        </div>
        <div className="text-[11px] text-slate-400 flex items-center gap-1">
          <Calendar className="w-3.5 h-3.5" />
          Synchronisé en temps réel avec les encaissements
        </div>
      </div>
    </div>
  );
};
