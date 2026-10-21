import React, { useMemo, useState } from 'react';
import { Sale } from '../../types';
import { usePos } from '../../context/PosContext';
import {
  Printer,
  X,
  Receipt,
  Download,
  Copy,
  Building2,
  Phone,
  Barcode,
  Calendar,
  User,
  Sliders,
} from 'lucide-react';

interface PrintableReceiptModalProps {
  sale: Sale;
  onClose: () => void;
}

export const PrintableReceiptModal: React.FC<PrintableReceiptModalProps> = ({
  sale,
  onClose,
}) => {
  const { printerSettings, updatePrinterSettings } = usePos();
  const [activeWidth, setActiveWidth] = useState<'80mm' | '58mm'>(printerSettings.paperWidth || '80mm');

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

  const is58mm = activeWidth === '58mm';

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto">
      <div className="bg-[#fdfbf7] w-full max-w-md rounded-3xl shadow-2xl border border-[#e5dcce] overflow-hidden my-4 flex flex-col max-h-[92vh]">
        {/* Modal Top Bar (Hidden during print) */}
        <div className="no-print px-5 py-3.5 bg-[#1f3d29] text-[#fcfbf7] border-b border-[#16311f] flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <Receipt className="w-4 h-4 text-[#a8d3a8]" />
            <h3 className="font-bold text-sm font-serif-title">🍃 Ticket de Caisse & Facturette</h3>
          </div>

          <div className="flex items-center gap-2">
            {/* Quick 80mm / 58mm switcher */}
            <div className="flex items-center bg-[#172f20] border border-[#2b5437] rounded-lg p-0.5 text-[10px]">
              <button
                type="button"
                onClick={() => setActiveWidth('80mm')}
                className={`px-2 py-0.5 rounded font-mono font-bold transition-colors cursor-pointer ${
                  activeWidth === '80mm'
                    ? 'bg-[#fdfbf7] text-[#1f3d29]'
                    : 'text-[#c5ddc5] hover:text-white'
                }`}
              >
                80mm
              </button>
              <button
                type="button"
                onClick={() => setActiveWidth('58mm')}
                className={`px-2 py-0.5 rounded font-mono font-bold transition-colors cursor-pointer ${
                  activeWidth === '58mm'
                    ? 'bg-[#fdfbf7] text-[#1f3d29]'
                    : 'text-[#c5ddc5] hover:text-white'
                }`}
              >
                58mm
              </button>
            </div>

            <button
              type="button"
              onClick={onClose}
              className="touch-btn p-1 text-[#c5ddc5] hover:text-white transition-colors cursor-pointer rounded-lg"
              aria-label="Fermer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Scrollable Receipt Body */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 bg-[#ede6d8] flex justify-center">
          {/* Printable Ticket Element calibrated to paper width */}
          <div
            id="printable-receipt"
            className={`bg-white rounded-xl shadow-md border border-[#d6cbba] font-mono text-slate-800 transition-all ${
              is58mm
                ? 'w-[230px] p-3 text-[10px] space-y-3'
                : 'w-[320px] p-5 text-xs space-y-4'
            }`}
          >
            {/* Cut line mock */}
            <div className="text-center text-[9px] text-slate-400 border-b border-dashed border-slate-300 pb-1">
              ✂ - - - - DÉCOUPE TICKET {activeWidth} - - - - ✂
            </div>

            {/* Optional Monochromatic Receipt Logo */}
            {printerSettings.printLogo && printerSettings.logoDataUrl && (
              <div className="flex justify-center pb-1">
                <img
                  src={printerSettings.logoDataUrl}
                  alt="Logo Enseigne"
                  className="max-h-14 max-w-[150px] object-contain filter contrast-125 grayscale"
                />
              </div>
            )}

            {/* Store Information Header */}
            <div className="text-center pb-3 border-b border-dashed border-slate-300 space-y-0.5">
              <div className="font-black text-sm tracking-wider uppercase text-slate-900">
                {printerSettings.storeName || 'POS MODULE PRO'}
              </div>
              <div className="text-[10px] text-slate-600 font-medium">
                {printerSettings.storeSubtitle || 'Boutique & Caisse Générale'}
              </div>
              <div className="text-[9px] text-slate-500">
                {printerSettings.storeAddress || '14 Boulevard Zighout Youcef, 16000 Alger'}
              </div>
              <div className="text-[9px] text-slate-500">
                Tél : {printerSettings.storePhone || '+213 (0) 21 73 45 67'}
              </div>
              <div className="text-[8px] text-slate-400 pt-0.5">
                {printerSettings.storeTaxId || 'NIF: 001916010042879 • RC: 16/00-098234B19'}
              </div>
            </div>

            {/* Ticket Metadata */}
            <div className="text-[10px] space-y-1 pb-2 border-b border-dashed border-slate-300">
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
                  })}
                </span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Poste / Opérateur :</span>
                <span>Caisse #01 • Robin</span>
              </div>
              <div className="flex justify-between text-slate-700 font-medium pt-0.5">
                <span>Client :</span>
                <span className="truncate max-w-[130px]">{sale.customerName || 'Passager'}</span>
              </div>
            </div>

            {/* Items Table */}
            <div className="space-y-1 pb-3 border-b border-dashed border-slate-300">
              <div className="flex justify-between text-[10px] text-slate-400 font-bold uppercase pb-1 border-b border-slate-200">
                <span>Désignation</span>
                <span>Total TTC</span>
              </div>

              <div className="space-y-1 pt-1">
                {sale.items.map((item, idx) => (
                  <div key={`${item.productId}-${idx}`} className="space-y-0.5">
                    <div className="flex justify-between items-baseline gap-1">
                      <span className="font-semibold text-slate-900 truncate">
                        {item.productName}
                      </span>
                      <span className="font-bold text-slate-900 shrink-0">
                        {formatMoney(item.totalTTC)}
                      </span>
                    </div>
                    <div className="flex justify-between text-[9px] text-slate-500">
                      <span>
                        {item.quantity} x {formatMoney(item.unitPrice)}
                        {item.discountPercent > 0 && ` (-${item.discountPercent}%)`}
                      </span>
                      <span>TVA {Math.round(item.taxRate * 100)}%</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            {/* Financial Summary */}
            <div className="space-y-1 pb-3 border-b border-dashed border-slate-300 text-[10px]">
              <div className="flex justify-between text-slate-600">
                <span>Total Articles ({totalQuantity} pièces) :</span>
                <span>{formatMoney(sale.subtotalHT + sale.taxTotal)}</span>
              </div>
              {sale.discountTotal > 0 && (
                <div className="flex justify-between text-emerald-700 font-semibold">
                  <span>Remise déduite :</span>
                  <span>-{formatMoney(sale.discountTotal)}</span>
                </div>
              )}
              <div className="flex justify-between text-slate-600">
                <span>Total Hors Taxes (HT) :</span>
                <span>{formatMoney(sale.subtotalHT)}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>TVA globale :</span>
                <span>{formatMoney(sale.taxTotal)}</span>
              </div>
              <div className="flex justify-between text-sm font-black text-slate-900 pt-1.5 border-t border-slate-300">
                <span>TOTAL À PAYER TTC :</span>
                <span>{formatMoney(sale.totalTTC)}</span>
              </div>
            </div>

            {/* Payment Details */}
            <div className="space-y-1 pb-3 border-b border-dashed border-slate-300 text-[10px]">
              <div className="flex justify-between text-slate-700 font-bold">
                <span>Mode de Paiement :</span>
                <span>
                  {sale.paymentMethod === 'CASH'
                    ? 'ESPÈCES'
                    : sale.paymentMethod === 'CARD'
                    ? 'CARTE BANCAIRE / CIB'
                    : 'CHÈQUE'}
                </span>
              </div>
              {sale.paymentMethod === 'CASH' && (
                <>
                  <div className="flex justify-between text-slate-600">
                    <span>Espèces Remises :</span>
                    <span>{formatMoney(sale.amountTendered || sale.totalTTC)}</span>
                  </div>
                  <div className="flex justify-between text-slate-600">
                    <span>Monnaie Rendue :</span>
                    <span className="font-bold text-slate-800">
                      {formatMoney(sale.changeGiven || 0)}
                    </span>
                  </div>
                </>
              )}
            </div>

            {/* Tax Breakdown Grid */}
            <div className="space-y-1 pb-2 border-b border-dashed border-slate-300 text-[9px]">
              <div className="grid grid-cols-4 font-bold text-slate-500 border-b border-slate-200 pb-0.5">
                <span>Taux</span>
                <span className="text-right">Base HT</span>
                <span className="text-right">TVA</span>
                <span className="text-right">TTC</span>
              </div>
              {taxBreakdown.map((t) => (
                <div key={t.rate} className="grid grid-cols-4 text-slate-600">
                  <span>{t.rate}%</span>
                  <span className="text-right">{formatMoney(t.baseHT)}</span>
                  <span className="text-right">{formatMoney(t.taxAmount)}</span>
                  <span className="text-right">{formatMoney(t.totalTTC)}</span>
                </div>
              ))}
            </div>

            {/* Barcode & Footer Notice */}
            <div className="pt-2 border-t border-dashed border-slate-300 text-center space-y-1.5">
              <div className="flex flex-col items-center justify-center">
                <div className="font-mono text-xs tracking-widest text-slate-700 font-bold">
                  ||||| | |||| ||| |||||
                </div>
                <div className="text-[8px] text-slate-400 font-mono mt-0.5">
                  {sale.saleNumber}
                </div>
              </div>
              <p className="text-[9px] text-slate-600 leading-tight">
                {printerSettings.receiptFooterMessage ||
                  'Les retours et échanges sont acceptés sous 7 jours sur présentation de ce ticket original.'}
              </p>
              <div className="text-[9px] font-bold text-[#234931]">
                *** MERCI DE VOTRE VISITE ET À BIENTÔT ***
              </div>
            </div>
          </div>
        </div>

        {/* Modal Action Buttons Footer (Hidden during print) */}
        <div className="no-print p-4 bg-[#fdfbf7] border-t border-[#e5dcce] flex flex-wrap items-center justify-between gap-3 shrink-0">
          <button
            type="button"
            onClick={onClose}
            className="touch-btn px-4 py-2 sherwood-btn-outline text-xs font-bold"
          >
            Fermer
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="touch-btn px-5 py-2.5 sherwood-btn-forest text-xs font-bold flex items-center gap-2"
            >
              <Printer className="w-4 h-4" />
              <span>Imprimer Ticket ({activeWidth})</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
