import React from 'react';
import {
  ResponsiveContainer,
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  CartesianGrid,
  Cell,
  Legend,
  Line,
  ComposedChart,
} from 'recharts';
import { usePos } from '../../context/PosContext';
import { ShoppingBag, TrendingUp, Calendar, Zap, CheckCircle2 } from 'lucide-react';

export const DailySalesVolumeChart: React.FC = () => {
  const { dailyStats } = usePos();

  // Exactly the last 7 days of transaction data
  const last7DaysData = dailyStats.slice(-7);

  const totalTransactions7Days = last7DaysData.reduce((acc, curr) => acc + curr.orders, 0);
  const totalUnits7Days = last7DaysData.reduce((acc, curr) => acc + curr.unitsSold, 0);
  const avgTransactionsPerDay = (totalTransactions7Days / Math.max(1, last7DaysData.length)).toFixed(1);

  // Peak transaction day
  const peakDay = last7DaysData.reduce(
    (max, curr) => (curr.orders > max.orders ? curr : max),
    last7DaysData[0] || { orders: 0, formattedDate: '-' }
  );

  return (
    <div className="bg-white/90 backdrop-blur-xl rounded-3xl p-5 sm:p-6 border border-white shadow-xs">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-amber-50 text-amber-600 flex items-center justify-center font-bold shadow-2xs">
            <ShoppingBag className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="text-base sm:text-lg font-extrabold text-slate-800">
                Volume des Ventes (7 Derniers Jours)
              </h3>
              <span className="px-2 py-0.5 rounded-full bg-amber-100 text-amber-800 text-[10px] font-black uppercase tracking-wider">
                7J Trends
              </span>
            </div>
            <p className="text-xs text-slate-500">
              Tendances du flux de transactions et nombre de tickets enregistrés
            </p>
          </div>
        </div>

        {/* Quick KPI stats badge */}
        <div className="flex items-center gap-2">
          <div className="px-3 py-1.5 bg-slate-50 border border-slate-200/80 rounded-2xl flex items-center gap-2">
            <Calendar className="w-4 h-4 text-slate-400" />
            <div className="text-xs">
              <span className="text-slate-400">Total : </span>
              <strong className="text-slate-800 font-extrabold">{totalTransactions7Days} tickets</strong>
            </div>
          </div>
          <div className="px-3 py-1.5 bg-amber-50 border border-amber-200/80 rounded-2xl flex items-center gap-2">
            <Zap className="w-4 h-4 text-amber-600" />
            <div className="text-xs">
              <span className="text-amber-700">Moyenne : </span>
              <strong className="text-amber-900 font-extrabold">{avgTransactionsPerDay} / jour</strong>
            </div>
          </div>
        </div>
      </div>

      {/* Top Insights Row */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3 mb-5">
        <div className="bg-slate-50/80 rounded-2xl p-3 border border-slate-100">
          <div className="text-[11px] text-slate-500 font-semibold">Total Tickets (7j)</div>
          <div className="text-xl font-black text-slate-900 mt-1">{totalTransactions7Days}</div>
          <div className="text-[10px] text-emerald-600 font-medium flex items-center gap-1 mt-0.5">
            <CheckCircle2 className="w-3 h-3" />
            Flux stable
          </div>
        </div>
        <div className="bg-slate-50/80 rounded-2xl p-3 border border-slate-100">
          <div className="text-[11px] text-slate-500 font-semibold">Articles Écoulés</div>
          <div className="text-xl font-black text-slate-900 mt-1">{totalUnits7Days} unités</div>
          <div className="text-[10px] text-slate-400 mt-0.5">Sur 7 jours glissants</div>
        </div>
        <div className="bg-slate-50/80 rounded-2xl p-3 border border-slate-100">
          <div className="text-[11px] text-slate-500 font-semibold">Pic de Fréquentation</div>
          <div className="text-xl font-black text-amber-600 mt-1">{peakDay.orders} tickets</div>
          <div className="text-[10px] text-slate-500 mt-0.5">{peakDay.formattedDate}</div>
        </div>
        <div className="bg-slate-50/80 rounded-2xl p-3 border border-slate-100">
          <div className="text-[11px] text-slate-500 font-semibold">Articles / Ticket</div>
          <div className="text-xl font-black text-indigo-600 mt-1">
            {totalTransactions7Days > 0 ? (totalUnits7Days / totalTransactions7Days).toFixed(1) : '0'}
          </div>
          <div className="text-[10px] text-slate-400 mt-0.5">Taille moyenne panier</div>
        </div>
      </div>

      {/* Recharts Composed Chart for 7 Days Sales Volume */}
      <div className="h-64 sm:h-72 w-full">
        <ResponsiveContainer width="100%" height="100%">
          <ComposedChart data={last7DaysData} margin={{ top: 10, right: 10, left: -20, bottom: 0 }}>
            <CartesianGrid strokeDasharray="3 3" vertical={false} stroke="#f1f5f9" />
            <XAxis
              dataKey="formattedDate"
              tickLine={false}
              axisLine={false}
              tick={{ fill: '#64748b', fontSize: 11, fontWeight: 600 }}
              dy={8}
            />
            <YAxis
              yAxisId="orders"
              tickLine={false}
              axisLine={false}
              tick={{ fill: '#64748b', fontSize: 11 }}
              domain={[0, 'auto']}
              allowDecimals={false}
            />
            <YAxis
              yAxisId="units"
              orientation="right"
              tickLine={false}
              axisLine={false}
              tick={{ fill: '#94a3b8', fontSize: 10 }}
              domain={[0, 'auto']}
              hide={true}
            />
            <Tooltip
              content={({ active, payload }) => {
                if (active && payload && payload.length) {
                  const data = payload[0].payload;
                  return (
                    <div className="bg-slate-900/95 backdrop-blur-md text-white p-3 rounded-2xl shadow-xl border border-slate-800 text-xs min-w-[190px]">
                      <div className="text-slate-400 font-semibold pb-1.5 border-b border-slate-800 flex items-center justify-between">
                        <span>{data.formattedDate}</span>
                        <span className="font-mono text-[10px] text-indigo-300">Transaction Trend</span>
                      </div>
                      <div className="mt-2 space-y-1.5">
                        <div className="flex justify-between items-center">
                          <span className="text-amber-400 font-semibold flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-amber-400 inline-block"></span>
                            Tickets caisse :
                          </span>
                          <span className="font-extrabold text-sm">{data.orders} ventes</span>
                        </div>
                        <div className="flex justify-between items-center text-slate-300">
                          <span className="flex items-center gap-1.5">
                            <span className="w-2 h-2 rounded-full bg-indigo-400 inline-block"></span>
                            Unités vendues :
                          </span>
                          <span className="font-semibold">{data.unitsSold} articles</span>
                        </div>
                        <div className="flex justify-between items-center pt-1 border-t border-slate-800 text-slate-400 text-[10px]">
                          <span>Chiffre d'Affaires :</span>
                          <span className="font-bold text-slate-200">
                            {new Intl.NumberFormat('fr-DZ', { maximumFractionDigits: 0 }).format(data.revenue)} DA
                          </span>
                        </div>
                      </div>
                    </div>
                  );
                }
                return null;
              }}
            />
            <Bar
              yAxisId="orders"
              dataKey="orders"
              name="Nombre de transactions"
              radius={[8, 8, 0, 0]}
              maxBarSize={48}
            >
              {last7DaysData.map((entry, index) => {
                const isToday = index === last7DaysData.length - 1;
                const isPeak = entry.orders === peakDay.orders && peakDay.orders > 0;
                return (
                  <Cell
                    key={`cell-${index}`}
                    fill={isToday ? '#f59e0b' : isPeak ? '#d97706' : '#fbbf24'}
                    className="transition-all duration-300 hover:opacity-80"
                  />
                );
              })}
            </Bar>
            <Line
              yAxisId="orders"
              type="monotone"
              dataKey="orders"
              stroke="#b45309"
              strokeWidth={2}
              dot={{ r: 4, fill: '#b45309', stroke: '#fff', strokeWidth: 2 }}
              activeDot={{ r: 6, fill: '#d97706' }}
            />
          </ComposedChart>
        </ResponsiveContainer>
      </div>

      <div className="flex items-center justify-between text-[11px] text-slate-400 mt-2 pt-2 border-t border-slate-100">
        <div className="flex items-center gap-3">
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-2.5 rounded-sm bg-amber-400 inline-block"></span>
            Transactions quotidiennes
          </span>
          <span className="flex items-center gap-1.5">
            <span className="w-2.5 h-0.5 bg-amber-700 inline-block"></span>
            Courbe de tendance
          </span>
        </div>
        <span className="text-[10px] text-amber-700 font-semibold bg-amber-50 px-2 py-0.5 rounded-md">
          Aujourd'hui : {last7DaysData[last7DaysData.length - 1]?.orders ?? 0} tickets
        </span>
      </div>
    </div>
  );
};
