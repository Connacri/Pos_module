import React, { useEffect, useRef, useState, useMemo } from 'react';
import * as d3 from 'd3';
import { usePos } from '../../context/PosContext';
import { DailyRevenueStat } from '../../types';
import {
  TrendingUp,
  Calendar,
  Sparkles,
  ArrowUpRight,
  ArrowDownRight,
  Zap,
  DollarSign,
  Activity,
  Layers,
} from 'lucide-react';

interface D3RevenueTrendChartProps {
  days?: number;
}

export const D3RevenueTrendChart: React.FC<D3RevenueTrendChartProps> = ({ days = 7 }) => {
  const { dailyStats } = usePos();
  const svgRef = useRef<SVGSVGElement | null>(null);
  const containerRef = useRef<HTMLDivElement | null>(null);

  const [activeMetric, setActiveMetric] = useState<'revenue' | 'profit'>('revenue');
  const [selectedPoint, setSelectedPoint] = useState<DailyRevenueStat | null>(null);

  // Take the last 7 days of daily stats
  const data = useMemo(() => {
    return dailyStats.slice(-days);
  }, [dailyStats, days]);

  // Compute 7-day summary metrics
  const summary = useMemo(() => {
    const total = data.reduce((sum, d) => sum + (activeMetric === 'revenue' ? d.revenue : d.profit), 0);
    const average = data.length > 0 ? Math.round(total / data.length) : 0;
    const peak = [...data].sort((a, b) => (activeMetric === 'revenue' ? b.revenue - a.revenue : b.profit - a.profit))[0];

    const first = data[0] ? (activeMetric === 'revenue' ? data[0].revenue : data[0].profit) : 0;
    const last = data[data.length - 1] ? (activeMetric === 'revenue' ? data[data.length - 1].revenue : data[data.length - 1].profit) : 0;
    const growthPercent = first > 0 ? Math.round(((last - first) / first) * 100) : 0;

    return { total, average, peak, growthPercent };
  }, [data, activeMetric]);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Render D3 Line Chart
  useEffect(() => {
    if (!svgRef.current || !containerRef.current || data.length === 0) return;

    // Get container dimensions
    const containerWidth = containerRef.current.clientWidth || 600;
    const height = 260;
    const margin = { top: 25, right: 30, bottom: 35, left: 55 };
    const width = containerWidth;
    const innerWidth = width - margin.left - margin.right;
    const innerHeight = height - margin.top - margin.bottom;

    // Clear previous SVG contents
    const svg = d3.select(svgRef.current);
    svg.selectAll('*').remove();

    svg.attr('viewBox', `0 0 ${width} ${height}`);

    const g = svg.append('g').attr('transform', `translate(${margin.left},${margin.top})`);

    // Define X & Y scales
    const x = d3
      .scalePoint<string>()
      .domain(data.map((d) => d.formattedDate))
      .range([0, innerWidth])
      .padding(0.2);

    const maxY = d3.max(data, (d) => (activeMetric === 'revenue' ? d.revenue : d.profit)) || 1000;
    const y = d3
      .scaleLinear()
      .domain([0, maxY * 1.15])
      .range([innerHeight, 0])
      .nice();

    // Subtle Horizontal Gridlines
    const yAxisGrid = d3
      .axisLeft(y)
      .tickSize(-innerWidth)
      .tickFormat(() => '')
      .ticks(5);

    g.append('g')
      .attr('class', 'grid')
      .call(yAxisGrid)
      .selectAll('line')
      .attr('stroke', '#f1f5f9')
      .attr('stroke-dasharray', '3 3');

    g.select('.grid .domain').remove();

    // Defs: Gradients and drop-shadow filter
    const defs = svg.append('defs');

    // Area Gradient
    const gradientId = `d3-revenue-area-gradient-${activeMetric}`;
    const areaGradient = defs
      .append('linearGradient')
      .attr('id', gradientId)
      .attr('x1', '0%')
      .attr('y1', '0%')
      .attr('x2', '0%')
      .attr('y2', '100%');

    const primaryColor = activeMetric === 'revenue' ? '#6366f1' : '#10b981';
    const secondaryColor = activeMetric === 'revenue' ? '#4f46e5' : '#059669';

    areaGradient
      .append('stop')
      .attr('offset', '0%')
      .attr('stop-color', primaryColor)
      .attr('stop-opacity', 0.38);

    areaGradient
      .append('stop')
      .attr('offset', '100%')
      .attr('stop-color', primaryColor)
      .attr('stop-opacity', 0.0);

    // Glow Filter
    const filter = defs.append('filter').attr('id', 'glow').attr('x', '-20%').attr('y', '-20%').attr('width', '140%').attr('height', '140%');
    filter.append('feDropShadow').attr('dx', '0').attr('dy', '4').attr('stdDeviation', '4').attr('flood-color', primaryColor).attr('flood-opacity', '0.25');

    // Area Generator
    const area = d3
      .area<DailyRevenueStat>()
      .x((d) => x(d.formattedDate) || 0)
      .y0(innerHeight)
      .y1((d) => y(activeMetric === 'revenue' ? d.revenue : d.profit))
      .curve(d3.curveMonotoneX);

    // Render Filled Area
    g.append('path')
      .datum(data)
      .attr('fill', `url(#${gradientId})`)
      .attr('d', area);

    // Line Generator
    const line = d3
      .line<DailyRevenueStat>()
      .x((d) => x(d.formattedDate) || 0)
      .y((d) => y(activeMetric === 'revenue' ? d.revenue : d.profit))
      .curve(d3.curveMonotoneX);

    // Render Line Path with glow
    const path = g
      .append('path')
      .datum(data)
      .attr('fill', 'none')
      .attr('stroke', primaryColor)
      .attr('stroke-width', 3)
      .attr('filter', 'url(#glow)')
      .attr('d', line);

    // Animate line stroke drawing
    const pathLength = (path.node() as SVGPathElement)?.getTotalLength?.() || 1000;
    path
      .attr('stroke-dasharray', `${pathLength} ${pathLength}`)
      .attr('stroke-dashoffset', pathLength)
      .transition()
      .duration(900)
      .ease(d3.easeCubicOut)
      .attr('stroke-dashoffset', 0);

    // Render Data Circles (Points)
    const pointsGroup = g.append('g').attr('class', 'points');

    data.forEach((d, i) => {
      const cx = x(d.formattedDate) || 0;
      const cy = y(activeMetric === 'revenue' ? d.revenue : d.profit);
      const isLatest = i === data.length - 1;

      // Outer aura ring for today / latest point
      if (isLatest) {
        pointsGroup
          .append('circle')
          .attr('cx', cx)
          .attr('cy', cy)
          .attr('r', 9)
          .attr('fill', primaryColor)
          .attr('opacity', 0.25);
      }

      // Point circle
      const circle = pointsGroup
        .append('circle')
        .attr('cx', cx)
        .attr('cy', cy)
        .attr('r', isLatest ? 5.5 : 4)
        .attr('fill', '#ffffff')
        .attr('stroke', isLatest ? secondaryColor : primaryColor)
        .attr('stroke-width', 2.5)
        .attr('class', 'cursor-pointer transition-all')
        .on('mouseenter', () => {
          setSelectedPoint(d);
          circle.attr('r', 7).attr('fill', primaryColor);
        })
        .on('mouseleave', () => {
          circle.attr('r', isLatest ? 5.5 : 4).attr('fill', '#ffffff');
        });
    });

    // X Axis
    const xAxis = d3.axisBottom(x).tickSize(0).tickPadding(12);
    const xAxisGroup = g
      .append('g')
      .attr('transform', `translate(0,${innerHeight})`)
      .call(xAxis);

    xAxisGroup.select('.domain').attr('stroke', '#cbd5e1');
    xAxisGroup
      .selectAll('text')
      .attr('fill', '#64748b')
      .attr('font-size', '11px')
      .attr('font-weight', '600')
      .attr('font-family', 'inherit');

    // Y Axis
    const yAxis = d3
      .axisLeft(y)
      .ticks(5)
      .tickSize(0)
      .tickPadding(10)
      .tickFormat((d) => {
        const val = Number(d);
        if (val >= 1000) {
          return `${Math.round(val / 1000)}k`;
        }
        return `${val}`;
      });

    const yAxisGroup = g.append('g').call(yAxis);
    yAxisGroup.select('.domain').remove();
    yAxisGroup
      .selectAll('text')
      .attr('fill', '#64748b')
      .attr('font-size', '10px')
      .attr('font-weight', '600')
      .attr('font-family', 'inherit');
  }, [data, activeMetric]);

  // Handle auto-resize using ResizeObserver
  useEffect(() => {
    if (!containerRef.current) return;
    const observer = new ResizeObserver(() => {
      // Re-trigger D3 draw on resize
      if (svgRef.current && containerRef.current && data.length > 0) {
        const width = containerRef.current.clientWidth || 600;
        d3.select(svgRef.current).attr('viewBox', `0 0 ${width} 260`);
      }
    });

    observer.observe(containerRef.current);
    return () => observer.disconnect();
  }, [data]);

  return (
    <div className="bg-white rounded-3xl p-5 sm:p-6 border border-slate-200/80 shadow-xs space-y-5">
      {/* Chart Top Header & Metric Selector */}
      <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-4 border-b border-slate-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-2xl bg-indigo-50 text-indigo-600 flex items-center justify-center font-bold shrink-0">
            <Activity className="w-5 h-5" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-base sm:text-lg text-slate-900">
                Tendance du Chiffre d'Affaires (D3.js)
              </h3>
              <span className="bg-indigo-100 text-indigo-800 text-[10px] font-bold px-2 py-0.5 rounded-full border border-indigo-200">
                7 Derniers Jours
              </span>
            </div>
            <p className="text-xs text-slate-500 mt-0.5">
              Visualisation vectorielle haute précision des revenus quotidiens et de la vitesse de vente
            </p>
          </div>
        </div>

        {/* Metric Selector Tabs */}
        <div className="flex items-center gap-1.5 self-start md:self-auto bg-slate-100 p-1 rounded-2xl text-xs font-semibold">
          <button
            type="button"
            onClick={() => {
              setActiveMetric('revenue');
              setSelectedPoint(null);
            }}
            className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
              activeMetric === 'revenue'
                ? 'bg-white text-indigo-600 shadow-2xs font-bold'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Chiffre d'Affaires
          </button>
          <button
            type="button"
            onClick={() => {
              setActiveMetric('profit');
              setSelectedPoint(null);
            }}
            className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
              activeMetric === 'profit'
                ? 'bg-white text-emerald-600 shadow-2xs font-bold'
                : 'text-slate-600 hover:text-slate-900'
            }`}
          >
            Marge Brute
          </button>
        </div>
      </div>

      {/* 7-Day Performance Insight KPI Cards */}
      <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
        {/* Total 7 Days */}
        <div className="p-3.5 bg-slate-50/80 rounded-2xl border border-slate-200/70 space-y-1">
          <span className="text-[11px] font-semibold text-slate-500">
            Total {days} Jours
          </span>
          <div className="text-base sm:text-lg font-black text-slate-900">
            {formatMoney(summary.total)}
          </div>
          <div className="text-[10px] text-slate-400">
            Période courante
          </div>
        </div>

        {/* Daily Average */}
        <div className="p-3.5 bg-slate-50/80 rounded-2xl border border-slate-200/70 space-y-1">
          <span className="text-[11px] font-semibold text-slate-500">
            Moyenne Quotidienne
          </span>
          <div className="text-base sm:text-lg font-black text-indigo-600">
            {formatMoney(summary.average)}
          </div>
          <div className="text-[10px] text-slate-400">
            Par jour sur 7 jours
          </div>
        </div>

        {/* Growth Velocity */}
        <div className="p-3.5 bg-slate-50/80 rounded-2xl border border-slate-200/70 space-y-1">
          <span className="text-[11px] font-semibold text-slate-500">
            Progression 7J
          </span>
          <div
            className={`text-base sm:text-lg font-black flex items-center gap-1 ${
              summary.growthPercent >= 0 ? 'text-emerald-600' : 'text-rose-600'
            }`}
          >
            {summary.growthPercent >= 0 ? (
              <ArrowUpRight className="w-4 h-4" />
            ) : (
              <ArrowDownRight className="w-4 h-4" />
            )}
            <span>{summary.growthPercent > 0 ? `+${summary.growthPercent}%` : `${summary.growthPercent}%`}</span>
          </div>
          <div className="text-[10px] text-slate-400">
            J-7 vs Aujourd'hui
          </div>
        </div>

        {/* Peak Day */}
        <div className="p-3.5 bg-slate-50/80 rounded-2xl border border-slate-200/70 space-y-1">
          <span className="text-[11px] font-semibold text-slate-500">
            Pic de Vente
          </span>
          <div className="text-base sm:text-lg font-black text-slate-900 truncate">
            {summary.peak ? summary.peak.formattedDate : '—'}
          </div>
          <div className="text-[10px] text-emerald-600 font-semibold truncate">
            {summary.peak ? formatMoney(activeMetric === 'revenue' ? summary.peak.revenue : summary.peak.profit) : ''}
          </div>
        </div>
      </div>

      {/* D3 SVG Chart Container */}
      <div ref={containerRef} className="w-full relative">
        <svg ref={svgRef} className="w-full h-[260px] overflow-visible" />

        {/* Hover / Selected Point Tooltip Banner */}
        {selectedPoint && (
          <div className="absolute top-2 right-2 bg-slate-900/95 text-white p-3 rounded-2xl shadow-xl border border-slate-700 text-xs space-y-1 animate-in fade-in zoom-in-95 duration-150 backdrop-blur-xs">
            <div className="flex items-center justify-between gap-4 border-b border-slate-700 pb-1">
              <span className="font-bold text-slate-200">{selectedPoint.formattedDate}</span>
              <span className="font-mono text-[10px] text-indigo-400">{selectedPoint.date}</span>
            </div>
            <div className="flex justify-between gap-4 pt-0.5">
              <span className="text-slate-400">Chiffre d'Affaires :</span>
              <span className="font-bold text-white">{formatMoney(selectedPoint.revenue)}</span>
            </div>
            <div className="flex justify-between gap-4">
              <span className="text-emerald-400">Marge brute :</span>
              <span className="font-semibold text-emerald-300">{formatMoney(selectedPoint.profit)}</span>
            </div>
            <div className="flex justify-between gap-4">
              <span className="text-amber-400">Transactions :</span>
              <span className="font-medium text-white">{selectedPoint.orders} tickets</span>
            </div>
          </div>
        )}
      </div>

      {/* Chart Footer with D3 Info and Legend */}
      <div className="pt-3 border-t border-slate-100 flex flex-col sm:flex-row sm:items-center justify-between gap-2 text-xs text-slate-500">
        <div className="flex items-center gap-4">
          <div className="flex items-center gap-1.5">
            <span
              className="w-2.5 h-2.5 rounded-full inline-block"
              style={{ backgroundColor: activeMetric === 'revenue' ? '#6366f1' : '#10b981' }}
            ></span>
            <span className="font-medium text-slate-700">
              {activeMetric === 'revenue' ? "Courbe CA (DA)" : "Courbe Marge (DA)"}
            </span>
          </div>
          <div className="flex items-center gap-1.5 text-slate-400">
            <span className="w-2 h-2 rounded-full border border-slate-400 inline-block bg-white"></span>
            <span>Survolez un point pour le détail</span>
          </div>
        </div>

        <div className="text-[11px] text-slate-400 flex items-center gap-1">
          <Calendar className="w-3.5 h-3.5 text-slate-400" />
          <span>Données calculées en temps réel sur les 7 derniers jours</span>
        </div>
      </div>
    </div>
  );
};
