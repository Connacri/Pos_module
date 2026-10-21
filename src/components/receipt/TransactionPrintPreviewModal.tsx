import React, { useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import {
  Printer,
  X,
  Receipt,
  CheckCircle2,
  Building2,
  Phone,
  Barcode,
  Calendar,
  User,
  AlertCircle,
  Eye,
  Sliders,
} from 'lucide-react';
import { PaymentMethod } from '../../types';

interface TransactionPrintPreviewModalProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirmPayment: () => void;
  paymentMethod: PaymentMethod;
  amountTendered: number;
}

export const TransactionPrintPreviewModal: React.FC<TransactionPrintPreviewModalProps> = ({
  isOpen,
  onClose,
  onConfirmPayment,
  paymentMethod,
  amountTendered,
}) => {
  const {
    cart,
    cartSummary,
    selectedCustomerId,
    customers,
    orderNote,
  } = usePos();

  const customer = customers.find((c) => c.id === selectedCustomerId);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Detailed tax calculation breakdown by VAT rate (19%, 9%, 0%)
  const taxBreakdown = useMemo(() => {
    const map = new Map<number, { baseHT: number; taxAmount: number; totalTTC: number }>();

    cart.forEach((item) => {
      const rate = item.product.taxRate;
      if (!map.has(rate)) {
        map.set(rate, { baseHT: 0, taxAmount: 0, totalTTC: 0 });
      }
      const entry = map.get(rate)!;
      const lineOriginal = item.unitPrice * item.quantity;
      const lineNet = lineOriginal * (1 - item.discountPercent / 100);
      const lineHT = lineNet / (1 + rate);
      const lineTax = lineNet - lineHT;

      entry.baseHT += lineHT;
      entry.taxAmount += lineTax;
      entry.totalTTC += lineNet;
    });

    return Array.from(map.entries()).map(([rate, vals]) => ({
      rate: Math.round(rate * 100),
      baseHT: Math.round(vals.baseHT * 100) / 100,
      taxAmount: Math.round(vals.taxAmount * 100) / 100,
      totalTTC: Math.round(vals.totalTTC * 100) / 100,
    }));
  }, [cart]);

  if (!isOpen) return null;

  const changeToReturn = Math.max(0, amountTendered - cartSummary.totalTTC);
  const now = new Date();
  const previewTicketNumber = `PREV-${now.getFullYear()}${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}-${String(Math.floor(1000 + Math.random() * 9000))}`;

  const handlePrint = () => {
    window.print();
  };

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto">
      <div className="bg-[#fdfbf7] w-full max-w-lg rounded-3xl shadow-2xl border border-[#e5dcce] overflow-hidden my-4 flex flex-col max-h-[94vh]">
        {/* Modal Top Bar (Hidden during print) */}
        <div className="no-print px-5 py-3.5 bg-[#1f3d29] text-[#fcfbf7] border-b border-[#16311f] flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-[#8d5732] rounded-lg text-[#fcdbb6]">
              <Eye className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-sm font-serif-title">🍃 Aperçu Ticket Thermique 80mm</h3>
              <p className="text-[11px] text-[#c5ddc5]">
                Format Rouleau Thermique 80mm • Boutique Sherwood
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="touch-btn p-1 text-[#c5ddc5] hover:text-white transition-colors cursor-pointer rounded-lg hover:bg-[#284f35]"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* 80mm Format Notice Banner (Hidden during print) */}
        <div className="no-print bg-[#fbf4e8] px-5 py-2.5 border-b border-[#eddabb] flex items-center justify-between text-xs text-[#70481f]">
          <div className="flex items-center gap-2 font-medium">
            <AlertCircle className="w-4 h-4 text-[#8d5732] shrink-0" />
            <span>
              <strong>Gabarit 80mm calibré :</strong> Largeur d'impression 72-80 mm. Ticket de la boutique Sherwood.
            </span>
          </div>
          <span className="hidden sm:inline-block font-mono text-[10px] bg-[#eddabb] text-[#5c3713] px-2 py-0.5 rounded-md font-bold">
            80mm Roll
          </span>
        </div>

        {/* Scrollable Receipt Body */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 bg-[#ede6d8] flex justify-center">
          {/* Authentic 80mm Thermal Slip Container */}
          <div
            id="thermal-preview-receipt"
            className="w-full max-w-[340px] bg-white p-5 rounded-xl shadow-md border border-[#d6cbba] font-mono text-xs text-slate-800 space-y-3.5 relative"
            style={{ width: '80mm' }}
          >
            {/* Specimen watermark pill */}
            <div className="text-center pb-2 border-b border-dashed border-slate-300">
              <span className="inline-block bg-[#fbf4e8] text-[#70481f] text-[10px] font-black tracking-widest uppercase px-2.5 py-0.5 rounded-full border border-[#eddabb]">
                ••• PROFORMA / SHERWOOD POS •••
              </span>
            </div>

            {/* Store Information Header */}
            <div className="text-center pb-2 border-b border-dashed border-slate-300 space-y-1">
              <div className="font-black text-base text-slate-900 tracking-wider font-serif-title">
                BOUTIQUE SHERWOOD
              </div>
              <div className="text-[11px] text-slate-600 font-medium">
                Commerce Artisanal & Produits de l'Île
              </div>
              <div className="text-[10px] text-slate-500">
                Place du Village, Sherwood Island
              </div>
              <div className="text-[10px] text-slate-500">
                Tél : +213 (0) 21 73 45 67 • DA-1234-9101
              </div>
              <div className="text-[9px] text-slate-400 pt-0.5">
                NIF: 001916010042879 • RC: 16/00-098234B19
              </div>
            </div>

            {/* Ticket Metadata */}
            <div className="text-[11px] space-y-1 pb-2 border-b border-dashed border-slate-300">
              <div className="flex justify-between font-bold text-slate-900">
                <span>Réf. Projetée :</span>
                <span className="font-mono">{previewTicketNumber}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Date & Heure :</span>
                <span>
                  {now.toLocaleDateString('fr-FR', {
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
                <span>Caisse #01 • Amine K.</span>
              </div>
              <div className="flex justify-between text-slate-700 font-medium pt-0.5">
                <span>Client :</span>
                <span>{customer?.name || 'Client Passager (Comptoir)'}</span>
              </div>
              {orderNote && (
                <div className="flex justify-between text-slate-500 italic text-[10px]">
                  <span>Note :</span>
                  <span>{orderNote}</span>
                </div>
              )}
            </div>

            {/* Items Table Formatted for 80mm */}
            <div className="space-y-1.5 pb-2.5 border-b border-dashed border-slate-300">
              <div className="flex justify-between text-[10px] text-slate-500 font-bold uppercase pb-1 border-b border-slate-200">
                <span>Désignation</span>
                <span>Total TTC</span>
              </div>

              {cart.map((item, idx) => {
                const lineOriginal = item.unitPrice * item.quantity;
                const lineNet = lineOriginal * (1 - item.discountPercent / 100);

                return (
                  <div key={idx} className="space-y-0.5">
                    <div className="flex justify-between font-semibold text-slate-900 text-[11px]">
                      <span className="truncate pr-2">{item.product.name}</span>
                      <span className="shrink-0 font-bold">{formatMoney(lineNet)}</span>
                    </div>
                    <div className="flex justify-between text-[10px] text-slate-500">
                      <span>
                        {item.quantity} x {formatMoney(item.unitPrice)}
                        {item.product.taxRate > 0
                          ? ` (TVA ${Math.round(item.product.taxRate * 100)}%)`
                          : ' (TVA 0%)'}
                      </span>
                      {item.discountPercent > 0 && (
                        <span className="text-emerald-700 font-bold">
                          Remise -{item.discountPercent}%
                        </span>
                      )}
                    </div>
                  </div>
                );
              })}
            </div>

            {/* Tax Calculation Breakdown (Ventilation TVA) */}
            <div className="text-[10px] space-y-1 pb-2 border-b border-dashed border-slate-300 bg-slate-50 p-2 rounded-xl">
              <div className="font-bold text-slate-700 text-[10px] uppercase tracking-wider mb-1">
                Ventilation Taxes (TVA 80mm)
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

            {/* Totals & Payment Method */}
            <div className="space-y-1.5 pt-1 text-xs">
              <div className="flex justify-between text-slate-600">
                <span>Total Brut HT :</span>
                <span>{formatMoney(cartSummary.subtotalHT)}</span>
              </div>
              {cartSummary.discountAmount > 0 && (
                <div className="flex justify-between text-emerald-700 font-bold">
                  <span>Remise accordée :</span>
                  <span>-{formatMoney(cartSummary.discountAmount)}</span>
                </div>
              )}
              <div className="flex justify-between text-slate-600">
                <span>Total TVA :</span>
                <span>{formatMoney(cartSummary.totalTax)}</span>
              </div>
              <div className="flex justify-between text-slate-700 font-medium">
                <span>Articles :</span>
                <span>{cartSummary.totalItems} unité(s) ({cart.length} réf.)</span>
              </div>

              {/* Big Total TTC */}
              <div className="pt-2 border-t-2 border-slate-900 flex justify-between items-baseline text-sm font-black text-slate-900">
                <span>TOTAL NET TTC :</span>
                <span className="text-lg text-indigo-700">{formatMoney(cartSummary.totalTTC)}</span>
              </div>

              {/* Planned Settlement Breakdown */}
              <div className="pt-2 text-[11px] space-y-1 border-t border-slate-200">
                <div className="flex justify-between text-slate-800 font-medium">
                  <span>Règlement prévu :</span>
                  <span className="font-bold uppercase">
                    {paymentMethod === 'CASH'
                      ? 'Espèces'
                      : paymentMethod === 'CARD'
                      ? 'Carte CIB / Edahabia'
                      : 'Chèque / Virement'}
                  </span>
                </div>
                {paymentMethod === 'CASH' && (
                  <>
                    <div className="flex justify-between text-slate-600">
                      <span>Espèces remises :</span>
                      <span>{formatMoney(amountTendered || cartSummary.totalTTC)}</span>
                    </div>
                    {changeToReturn > 0 && (
                      <div className="flex justify-between text-emerald-700 font-black">
                        <span>Monnaie à rendre :</span>
                        <span>{formatMoney(changeToReturn)}</span>
                      </div>
                    )}
                  </>
                )}
              </div>
            </div>

            {/* Barcode representation */}
            <div className="pt-3 border-t border-dashed border-slate-300 text-center space-y-2">
              <div className="flex flex-col items-center justify-center">
                <div className="flex items-center gap-0.5 tracking-[4px] font-mono text-base font-black text-slate-800 select-all">
                  ||||| | |||| ||| |||||
                </div>
                <div className="text-[9px] text-slate-400 font-mono mt-0.5">
                  {previewTicketNumber}
                </div>
              </div>
              <div className="text-[10px] text-slate-500 leading-tight">
                Gabarit d'impression conforme aux spécifications thermiques 80mm (ESC/POS).
              </div>
              <div className="text-[10px] font-bold text-slate-800">
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
            className="touch-btn px-4 py-2 border border-[#e2d6c1] bg-[#f7f2e7] hover:bg-[#ede4d4] text-[#5d5244] rounded-xl text-xs font-bold transition-colors cursor-pointer"
          >
            Retour / Modifier
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="touch-btn px-4 py-2.5 bg-[#8d5732] hover:bg-[#784624] text-[#fff6ec] border border-[#6d3e1d] rounded-xl text-xs font-bold transition-all flex items-center gap-2 cursor-pointer shadow-xs"
              title="Tester l'impression sur imprimante thermique"
            >
              <Printer className="w-4 h-4 text-[#fcdbb6]" />
              <span>Imprimer Ticket Test (80mm)</span>
            </button>

            <button
              type="button"
              onClick={onConfirmPayment}
              className="touch-btn px-5 py-2.5 bg-[#2d563a] hover:bg-[#23442e] text-[#fdfbf7] rounded-xl text-xs font-bold shadow-md transition-all flex items-center gap-2 cursor-pointer border border-[#21402b]"
            >
              <CheckCircle2 className="w-4 h-4 text-[#a8d3a8]" />
              <span>Confirmer & Encaisser 🍃</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
