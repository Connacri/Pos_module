import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Sale } from '../../types';
import { InvoiceDetailView } from './InvoiceDetailView';
import { PrintableReceiptModal } from '../receipt/PrintableReceiptModal';
import {
  Search,
  Filter,
  Receipt,
  Eye,
  Calendar,
  CreditCard,
  Banknote,
  FileText,
  ArrowRight,
  TrendingUp,
  Printer,
} from 'lucide-react';

export const SalesHistoryView: React.FC = () => {
  const { sales, selectedInvoice, setSelectedInvoice } = usePos();
  const [searchQuery, setSearchQuery] = useState('');
  const [paymentFilter, setPaymentFilter] = useState<'ALL' | 'CASH' | 'CARD' | 'CHEQUE'>('ALL');
  const [receiptToPrint, setReceiptToPrint] = useState<Sale | null>(null);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  const filteredSales = useMemo(() => {
    return sales.filter((s) => {
      const matchesSearch =
        s.saleNumber.toLowerCase().includes(searchQuery.toLowerCase()) ||
        (s.customerName && s.customerName.toLowerCase().includes(searchQuery.toLowerCase()));

      const matchesPayment = paymentFilter === 'ALL' || s.paymentMethod === paymentFilter;

      return matchesSearch && matchesPayment;
    });
  }, [sales, searchQuery, paymentFilter]);

  if (selectedInvoice) {
    return (
      <InvoiceDetailView
        sale={selectedInvoice}
        onBack={() => setSelectedInvoice(null)}
      />
    );
  }

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 border border-white shadow-xs flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <h2 className="text-xl font-extrabold text-slate-900 flex items-center gap-2">
            <Receipt className="w-6 h-6 text-indigo-600" />
            Journal des Ventes & Factures
          </h2>
          <p className="text-xs text-slate-500 mt-1">
            Historique complet des transactions, tickets de caisse et factures émises
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-slate-50 border border-slate-200/80 rounded-2xl px-3.5 py-2 text-right">
            <div className="text-[10px] text-slate-400 font-semibold uppercase">Total Facturé</div>
            <div className="text-base font-black text-slate-900">
              {formatMoney(sales.reduce((sum, s) => sum + s.totalTTC, 0))}
            </div>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="bg-white/80 backdrop-blur-xl rounded-2xl p-4 border border-white shadow-xs flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher par N° ticket (INV-...), ou nom du client..."
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20"
          />
        </div>

        {/* Payment filter pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setPaymentFilter('ALL')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap ${
              paymentFilter === 'ALL'
                ? 'bg-slate-900 text-white border-slate-900 shadow-2xs'
                : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
            }`}
          >
            Tous
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CASH')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              paymentFilter === 'CASH'
                ? 'bg-emerald-600 text-white border-emerald-600 shadow-2xs'
                : 'bg-white text-emerald-700 border-emerald-200 hover:bg-emerald-50'
            }`}
          >
            <Banknote className="w-3.5 h-3.5" />
            Espèces
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CARD')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              paymentFilter === 'CARD'
                ? 'bg-blue-600 text-white border-blue-600 shadow-2xs'
                : 'bg-white text-blue-700 border-blue-200 hover:bg-blue-50'
            }`}
          >
            <CreditCard className="w-3.5 h-3.5" />
            Carte
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CHEQUE')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              paymentFilter === 'CHEQUE'
                ? 'bg-amber-600 text-white border-amber-600 shadow-2xs'
                : 'bg-white text-amber-700 border-amber-200 hover:bg-amber-50'
            }`}
          >
            <FileText className="w-3.5 h-3.5" />
            Chèque
          </button>
        </div>
      </div>

      {/* Sales Table / Cards */}
      <div className="bg-white/80 backdrop-blur-xl rounded-3xl border border-white shadow-xs overflow-hidden">
        {filteredSales.length === 0 ? (
          <div className="p-12 text-center text-slate-400">
            <Receipt className="w-12 h-12 mx-auto mb-2 text-slate-300" />
            <p className="font-semibold text-sm">Aucune vente ne correspond aux critères.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/60 text-slate-500 text-[11px] uppercase tracking-wider font-semibold">
                  <th className="py-3 px-4">N° Facture</th>
                  <th className="py-3 px-4">Date / Heure</th>
                  <th className="py-3 px-4">Client</th>
                  <th className="py-3 px-4">Nb Articles</th>
                  <th className="py-3 px-4">Paiement</th>
                  <th className="py-3 px-4 text-right">Montant TTC</th>
                  <th className="py-3 px-4 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {filteredSales.map((sale) => (
                  <tr
                    key={sale.id}
                    onClick={() => setSelectedInvoice(sale)}
                    className="hover:bg-slate-50/80 transition-colors cursor-pointer group"
                  >
                    <td className="py-3.5 px-4 font-mono font-bold text-indigo-600 group-hover:underline">
                      {sale.saleNumber}
                    </td>
                    <td className="py-3.5 px-4 text-slate-500 whitespace-nowrap">
                      {new Date(sale.createdAt).toLocaleDateString('fr-FR', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="py-3.5 px-4 font-medium text-slate-800">
                      {sale.customerName || 'Client Comptoir'}
                    </td>
                    <td className="py-3.5 px-4 text-slate-600">
                      {sale.items.reduce((sum, it) => sum + it.quantity, 0)} unités ({sale.items.length} réf.)
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="inline-flex items-center px-2 py-0.5 rounded-lg text-[10px] font-semibold bg-slate-100 text-slate-700">
                        {sale.paymentMethod === 'CASH'
                          ? 'Espèces'
                          : sale.paymentMethod === 'CARD'
                          ? 'Carte Bancaire'
                          : 'Chèque / Virement'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-extrabold text-slate-900 text-right whitespace-nowrap">
                      {formatMoney(sale.totalTTC)}
                    </td>
                    <td className="py-3.5 px-4 text-center">
                      <div className="inline-flex items-center gap-1.5">
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setSelectedInvoice(sale);
                          }}
                          className="touch-btn px-2.5 py-1 bg-white hover:bg-slate-100 border border-slate-200 text-slate-700 rounded-xl text-[11px] font-semibold inline-flex items-center gap-1 shadow-2xs transition-colors cursor-pointer"
                        >
                          <Eye className="w-3.5 h-3.5 text-indigo-600" />
                          <span>Détails</span>
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setReceiptToPrint(sale);
                          }}
                          className="touch-btn px-2.5 py-1 bg-indigo-50 hover:bg-indigo-100 border border-indigo-200 text-indigo-700 rounded-xl text-[11px] font-semibold inline-flex items-center gap-1 shadow-2xs transition-colors cursor-pointer"
                          title="Imprimer le ticket de caisse"
                        >
                          <Printer className="w-3.5 h-3.5" />
                          <span>Ticket</span>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Printable Receipt Modal */}
      {receiptToPrint && (
        <PrintableReceiptModal
          sale={receiptToPrint}
          onClose={() => setReceiptToPrint(null)}
        />
      )}
    </div>
  );
};
