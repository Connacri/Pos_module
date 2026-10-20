import React, { useMemo } from 'react';
import { Sale } from '../../types';
import {
  Printer,
  X,
  CheckCircle2,
  Receipt,
  Download,
  Copy,
  Building2,
  Phone,
  Barcode,
  Calendar,
  User,
} from 'lucide-react';

interface PrintableReceiptModalProps {
  sale: Sale;
  onClose: () => void;
}

export const PrintableReceiptModal: React.FC<PrintableReceiptModalProps> = ({
  sale,
  onClose,
}) => {
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Detailed tax calculation breakdown by VAT rate (19%, 9%, 0%)
  const taxBreakdown = useMemo(() => {
    const map = new Map<number, { baseHT: number; taxAmount: number; totalTTC: number }>();

    sale.items.forEach((item) => {
      const rate = item.taxRate;
      if (!map.has(rate)) {
        map.set(rate, { baseHT: 0, taxAmount: 0, totalTTC: 0 });
      }
      const entry = map.get(rate)!;
      entry.baseHT += item.totalHT;
      entry.taxAmount += item.totalTTC - item.totalHT;
      entry.totalTTC += item.totalTTC;
    });

    return Array.from(map.entries()).map(([rate, vals]) => ({
      rate: Math.round(rate * 100),
      baseHT: Math.round(vals.baseHT * 100) / 100,
      taxAmount: Math.round(vals.taxAmount * 100) / 100,
      totalTTC: Math.round(vals.totalTTC * 100) / 100,
    }));
  }, [sale]);

  const totalQuantity = sale.items.reduce((sum, it) => sum + it.quantity, 0);

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto">
      <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl border border-slate-200 overflow-hidden my-4 flex flex-col max-h-[92vh]">
        {/* Modal Top Bar (Hidden during print) */}
        <div className="no-print px-5 py-3.5 bg-slate-900 text-white flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <Receipt className="w-4 h-4 text-emerald-400" />
            <h3 className="font-bold text-sm">Ticket de Caisse & Facturette</h3>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="touch-btn p-1 text-slate-400 hover:text-white transition-colors cursor-pointer"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Receipt Body */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 bg-slate-50 flex justify-center">
          {/* Printable Ticket Element */}
          <div
            id="printable-receipt"
            className="w-full max-w-[360px] bg-white p-5 rounded-2xl shadow-sm border border-slate-200 font-mono text-xs text-slate-800 space-y-4"
          >
            {/* Store Information Header */}
            <div className="text-center pb-3 border-b border-dashed border-slate-300 space-y-1">
              <div className="font-black text-base text-slate-900 tracking-wider">
                POS MODULE PRO
              </div>
              <div className="text-[11px] text-slate-600 font-medium">
                Supermarché & Commerce Général
              </div>
              <div className="text-[10px] text-slate-500">
                14 Boulevard Zighout Youcef, 16000 Alger
              </div>
              <div className="text-[10px] text-slate-500">
                Tél : +213 (0) 21 73 45 67 • contact@posmodule.dz
              </div>
              <div className="text-[9px] text-slate-400 pt-1">
                NIF: 001916010042879 • RC: 16/00-098234B19
              </div>
            </div>

            {/* Ticket Metadata */}
            <div className="text-[11px] space-y-1 pb-2 border-b border-dashed border-slate-300">
              <div className="flex justify-between font-bold text-slate-900">
                <span>Ticket N° :</span>
                <span className="font-mono">{sale.saleNumber}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Date & Heure :</span>
                <span>
                  {new Date(sale.createdAt).toLocaleDateString('fr-FR', {
                    day: '2-digit',
                    month: '2-digit',
                    year: 'numeric',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                  })}
                </span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Poste Caisse :</span>
                <span>Caisse #01 • Opérateur : Amine K.</span>
              </div>
              <div className="flex justify-between text-slate-700 font-medium pt-0.5">
                <span>Client :</span>
                <span>{sale.customerName || 'Client Comptoir (Passager)'}</span>
              </div>
            </div>

            {/* Items Table */}
            <div className="space-y-1.5 pb-3 border-b border-dashed border-slate-300">
              <div className="flex justify-between text-[10px] text-slate-400 font-bold uppercase pb-1 border-b border-slate-200">
                <span>Désignation</span>
                <span>Total TTC</span>
              </div>

              {sale.items.map((item, idx) => (
                <div key={idx} className="space-y-0.5">
                  <div className="flex justify-between font-semibold text-slate-900 text-[11px]">
                    <span className="truncate pr-2">{item.productName}</span>
                    <span className="shrink-0">{formatMoney(item.totalTTC)}</span>
                  </div>
                  <div className="flex justify-between text-[10px] text-slate-500">
                    <span>
                      {item.quantity} x {formatMoney(item.unitPrice)}
                      {item.taxRate > 0 ? ` (TVA ${Math.round(item.taxRate * 100)}%)` : ' (TVA 0%)'}
                    </span>
                    {item.discountPercent > 0 && (
                      <span className="text-emerald-600 font-bold">
                        Remise -{item.discountPercent}%
                      </span>
                    )}
                  </div>
                </div>
              ))}
            </div>

            {/* Tax Calculation Breakdown (Ventilation TVA) */}
            <div className="text-[10px] space-y-1 pb-2 border-b border-dashed border-slate-300 bg-slate-50/70 p-2 rounded-xl">
              <div className="font-bold text-slate-700 text-[10px] uppercase tracking-wider mb-1">
                Détail des Taxes (TVA)
              </div>
              <div className="grid grid-cols-4 font-semibold text-slate-500 border-b border-slate-200 pb-0.5">
                <span>Taux</span>
                <span className="text-right">Base HT</span>
                <span className="text-right">Montant</span>
                <span className="text-right">Total TTC</span>
              </div>
              {taxBreakdown.map((t, idx) => (
                <div key={idx} className="grid grid-cols-4 text-slate-700">
                  <span className="font-bold">{t.rate}%</span>
                  <span className="text-right">{formatMoney(t.baseHT)}</span>
                  <span className="text-right">{formatMoney(t.taxAmount)}</span>
                  <span className="text-right font-medium">{formatMoney(t.totalTTC)}</span>
                </div>
              ))}
            </div>

            {/* Totals & Payment Breakdown */}
            <div className="space-y-1.5 pt-1 text-xs">
              <div className="flex justify-between text-slate-600">
                <span>Total Brut HT :</span>
                <span>{formatMoney(sale.subtotalHT)}</span>
              </div>
              {sale.discountTotal > 0 && (
                <div className="flex justify-between text-emerald-600 font-bold">
                  <span>Remise accordée :</span>
                  <span>-{formatMoney(sale.discountTotal)}</span>
                </div>
              )}
              <div className="flex justify-between text-slate-600">
                <span>Total TVA :</span>
                <span>{formatMoney(sale.taxTotal)}</span>
              </div>
              <div className="flex justify-between text-slate-800 font-medium">
                <span>Nombre d'articles :</span>
                <span>{totalQuantity} unités ({sale.items.length} réf.)</span>
              </div>

              {/* Big Total TTC */}
              <div className="pt-2 border-t-2 border-slate-900 flex justify-between items-baseline text-sm font-black text-slate-900">
                <span>TOTAL NET TTC :</span>
                <span className="text-lg text-indigo-700">{formatMoney(sale.totalTTC)}</span>
              </div>

              {/* Settlement info */}
              <div className="pt-1.5 text-[11px] space-y-1 border-t border-slate-200">
                <div className="flex justify-between text-slate-700 font-medium">
                  <span>Règlement :</span>
                  <span className="font-bold uppercase">
                    {sale.paymentMethod === 'CASH'
                      ? 'Espèces'
                      : sale.paymentMethod === 'CARD'
                      ? 'Carte CIB / Edahabia'
                      : 'Chèque / Virement'}
                  </span>
                </div>
                {sale.paymentMethod === 'CASH' && sale.amountTendered && (
                  <>
                    <div className="flex justify-between text-slate-600">
                      <span>Espèces reçues :</span>
                      <span>{formatMoney(sale.amountTendered)}</span>
                    </div>
                    {sale.changeGiven ? (
                      <div className="flex justify-between text-emerald-700 font-black">
                        <span>Monnaie rendue :</span>
                        <span>{formatMoney(sale.changeGiven)}</span>
                      </div>
                    ) : null}
                  </>
                )}
              </div>
            </div>

            {/* Barcode & Footer Notice */}
            <div className="pt-3 border-t border-dashed border-slate-300 text-center space-y-2">
              <div className="flex flex-col items-center justify-center">
                <div className="flex items-center gap-0.5 tracking-[4px] font-mono text-base font-black text-slate-800 select-all">
                  ||||| | |||| ||| |||||
                </div>
                <div className="text-[9px] text-slate-400 font-mono mt-0.5">
                  {sale.saleNumber}
                </div>
              </div>
              <div className="text-[10px] text-slate-600 leading-tight">
                Les retours et échanges sont acceptés sous 7 jours sur présentation de ce ticket original.
              </div>
              <div className="text-[10px] font-bold text-slate-800">
                *** MERCI DE VOTRE VISITE ET À BIENTÔT ***
              </div>
            </div>
          </div>
        </div>

        {/* Modal Action Buttons Footer (Hidden during print) */}
        <div className="no-print p-4 bg-white border-t border-slate-200 flex flex-wrap items-center justify-between gap-3 shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="touch-btn px-4 py-2 border border-slate-300 hover:bg-slate-50 text-slate-700 rounded-xl text-xs font-bold transition-colors cursor-pointer"
          >
            Fermer
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="touch-btn px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold shadow-md transition-all flex items-center gap-2 cursor-pointer"
            >
              <Printer className="w-4 h-4" />
              <span>Imprimer Ticket (80mm)</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
