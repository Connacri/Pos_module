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
  Sparkles,
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
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="sherwood-panel flex flex-col sm:flex-row sm:items-center justify-between gap-4">
        <div>
          <div className="sherwood-badge-forest mb-2">
            <Receipt className="w-3.5 h-3.5 text-[#234931]" />
            <span>Samlingar • Registre des Transactions</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-[#234931] font-serif-title tracking-tight flex items-center gap-2">
            <span>🍃</span>
            <span>Journal des Ventes & Factures</span>
          </h2>
          <p className="text-xs sm:text-sm text-[#605547] mt-1 font-medium">
            Historique complet des transactions, tickets de caisse et factures émises sur Sherwood POS
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="sherwood-panel-subtle px-4 py-2 text-right">
            <div className="text-[10px] text-[#877a6b] font-bold uppercase tracking-wider">Total Facturé</div>
            <div className="text-lg font-black text-[#234931] font-mono">
              {formatMoney(sales.reduce((sum, s) => sum + s.totalTTC, 0))}
            </div>
          </div>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="sherwood-panel p-4 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#877a6b] absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher par N° ticket (INV-...), ou nom du client..."
            className="w-full pl-10 pr-4 py-2.5 sherwood-input text-xs sm:text-sm font-medium"
          />
        </div>

        {/* Payment filter pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 text-xs font-bold">
          <button
            type="button"
            onClick={() => setPaymentFilter('ALL')}
            className={`touch-btn px-3.5 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap ${
              paymentFilter === 'ALL'
                ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                : 'sherwood-btn-outline'
            }`}
          >
            Tous
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CASH')}
            className={`touch-btn px-3.5 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5 ${
              paymentFilter === 'CASH'
                ? 'bg-[#234931] text-[#fdfbf7] shadow-xs'
                : 'sherwood-btn-outline text-[#234931]'
            }`}
          >
            <Banknote className="w-3.5 h-3.5" />
            <span>Espèces</span>
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CARD')}
            className={`touch-btn px-3.5 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5 ${
              paymentFilter === 'CARD'
                ? 'bg-[#85522b] text-white shadow-xs'
                : 'sherwood-btn-outline text-[#85522b]'
            }`}
          >
            <CreditCard className="w-3.5 h-3.5" />
            <span>Carte</span>
          </button>
          <button
            type="button"
            onClick={() => setPaymentFilter('CHEQUE')}
            className={`touch-btn px-3.5 py-1.5 rounded-xl transition-all cursor-pointer whitespace-nowrap flex items-center gap-1.5 ${
              paymentFilter === 'CHEQUE'
                ? 'bg-[#b45309] text-white shadow-xs'
                : 'sherwood-btn-outline text-[#b45309]'
            }`}
          >
            <FileText className="w-3.5 h-3.5" />
            <span>Chèque / Autre</span>
          </button>
        </div>
      </div>

      {/* Sales Table / Cards */}
      <div className="sherwood-panel p-0 overflow-hidden">
        {filteredSales.length === 0 ? (
          <div className="p-12 text-center text-[#877a6b]">
            <Receipt className="w-12 h-12 mx-auto mb-2 text-[#c7baa3]" />
            <p className="font-bold text-sm text-[#483d31]">Aucune vente ne correspond aux critères.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full text-left text-xs">
              <thead>
                <tr className="border-b border-[#e7ddca] bg-[#f7f2e7] text-[#605547] text-[11px] uppercase tracking-wider font-bold">
                  <th className="py-3 px-4">N° Facture</th>
                  <th className="py-3 px-4">Date / Heure</th>
                  <th className="py-3 px-4">Client</th>
                  <th className="py-3 px-4">Articles</th>
                  <th className="py-3 px-4">Paiement</th>
                  <th className="py-3 px-4 text-right">Montant TTC</th>
                  <th className="py-3 px-4 text-center">Action</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#e7ddca]">
                {filteredSales.map((sale) => (
                  <tr
                    key={sale.id}
                    onClick={() => setSelectedInvoice(sale)}
                    className="hover:bg-[#f7f2e7]/80 transition-colors cursor-pointer group"
                  >
                    <td className="py-3.5 px-4 font-mono font-bold text-[#234931] group-hover:underline">
                      {sale.saleNumber}
                    </td>
                    <td className="py-3.5 px-4 text-[#605547] whitespace-nowrap font-medium">
                      {new Date(sale.createdAt).toLocaleDateString('fr-FR', {
                        day: '2-digit',
                        month: 'short',
                        year: 'numeric',
                        hour: '2-digit',
                        minute: '2-digit',
                      })}
                    </td>
                    <td className="py-3.5 px-4 font-bold text-[#2c241c]">
                      {sale.customerName || 'Client Comptoir'}
                    </td>
                    <td className="py-3.5 px-4 text-[#605547] font-medium">
                      {sale.items.reduce((sum, it) => sum + it.quantity, 0)} unités ({sale.items.length} réf.)
                    </td>
                    <td className="py-3.5 px-4">
                      <span className="inline-flex items-center px-2.5 py-1 rounded-lg text-[10px] font-bold bg-[#faeee2] text-[#85522b] border border-[#f0d4ba]">
                        {sale.paymentMethod === 'CASH'
                          ? 'Espèces'
                          : sale.paymentMethod === 'CARD'
                          ? 'Carte Bancaire'
                          : 'Chèque / Virement'}
                      </span>
                    </td>
                    <td className="py-3.5 px-4 font-black text-[#234931] font-mono text-right whitespace-nowrap text-sm">
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
                          className="touch-btn px-2.5 py-1 sherwood-btn-outline text-[11px] font-bold inline-flex items-center gap-1"
                        >
                          <Eye className="w-3.5 h-3.5 text-[#234931]" />
                          <span>Détails</span>
                        </button>
                        <button
                          type="button"
                          onClick={(e) => {
                            e.stopPropagation();
                            setReceiptToPrint(sale);
                          }}
                          className="touch-btn px-2.5 py-1 sherwood-btn-forest text-[11px] font-bold inline-flex items-center gap-1"
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
