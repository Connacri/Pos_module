import React, { useMemo, useState } from 'react';
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
    printerSettings,
  } = usePos();

  const [activeWidth, setActiveWidth] = useState<'80mm' | '58mm'>(printerSettings.paperWidth || '80mm');

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

  const is58mm = activeWidth === '58mm';

  return (
    <div className="fixed inset-0 z-50 flex items-start sm:items-center justify-center bg-black/60 backdrop-blur-xs p-3 sm:p-4 overflow-y-auto">
      <div className="bg-[#fdfbf7] w-full max-w-lg rounded-3xl shadow-2xl border border-[#e5dcce] overflow-hidden my-4 flex flex-col max-h-[94dvh]">
        {/* Modal Top Bar (Hidden during print) */}
        <div className="no-print px-5 py-3.5 bg-[#1f3d29] text-[#fcfbf7] border-b border-[#16311f] flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2">
            <div className="p-1.5 bg-[#8d5732] rounded-lg text-[#fcdbb6]">
              <Eye className="w-4 h-4" />
            </div>
            <div>
              <h3 className="font-bold text-sm font-serif-title">🍃 Aperçu Ticket Thermique ({activeWidth})</h3>
              <p className="text-[11px] text-[#c5ddc5]">
                Format {activeWidth} ESC/POS • {printerSettings.printerName.split(' ')[0]}
              </p>
            </div>
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
              className="touch-btn p-1 text-[#c5ddc5] hover:text-white transition-colors cursor-pointer rounded-lg hover:bg-[#284f35]"
              aria-label="Fermer"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Format Notice Banner (Hidden during print) */}
        <div className="no-print bg-[#fbf4e8] px-5 py-2.5 border-b border-[#eddabb] flex items-center justify-between text-xs text-[#70481f]">
          <div className="flex items-center gap-2 font-medium">
            <AlertCircle className="w-4 h-4 text-[#8d5732] shrink-0" />
            <span>
              <strong>Gabarit {activeWidth} calibré :</strong> Largeur d'impression {is58mm ? '48-58 mm' : '72-80 mm'} • Imprimante : {printerSettings.printerName}
            </span>
          </div>
          <span className="hidden sm:inline-block font-mono text-[10px] bg-[#eddabb] text-[#5c3713] px-2 py-0.5 rounded-md font-bold">
            {activeWidth} Roll
          </span>
        </div>

        {/* Scrollable Receipt Body */}
        <div className="flex-1 overflow-y-auto p-4 sm:p-6 bg-[#ede6d8] flex justify-center">
          {/* Authentic Thermal Slip Container */}
          <div
            id="thermal-preview-receipt"
            className={`bg-white rounded-xl shadow-md border border-[#d6cbba] font-mono text-slate-800 transition-all ${
              is58mm
                ? 'w-[230px] max-w-full p-3 text-[10px] space-y-2.5'
                : 'w-[320px] max-w-full p-5 text-xs space-y-3.5'
            }`}
          >
            {/* Specimen watermark pill */}
            <div className="text-center pb-2 border-b border-dashed border-slate-300">
              <span className="inline-block bg-[#fbf4e8] text-[#70481f] text-[10px] font-black tracking-widest uppercase px-2.5 py-0.5 rounded-full border border-[#eddabb]">
                ••• PROFORMA / SHERWOOD POS •••
              </span>
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
            <div className="text-center pb-2 border-b border-dashed border-slate-300 space-y-0.5">
              <div className="font-black text-sm tracking-wider uppercase text-slate-900">
                {printerSettings.storeName || 'BOUTIQUE SHERWOOD'}
              </div>
              <div className="text-[10px] text-slate-600 font-medium">
                {printerSettings.storeSubtitle || "Commerce Artisanal & Produits de l'Île"}
              </div>
              <div className="text-[9px] text-slate-500">
                {printerSettings.storeAddress || 'Place du Village, Sherwood Island'}
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
                  })}
                </span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>Poste Caisse :</span>
                <span>Caisse #01 • Robin</span>
              </div>
              <div className="flex justify-between text-slate-700 font-medium pt-0.5">
                <span>Client :</span>
                <span className="truncate max-w-[130px]">{customer?.name || 'Client Passager'}</span>
              </div>
              {orderNote && (
                <div className="flex justify-between text-slate-500 italic text-[9px]">
                  <span>Note :</span>
                  <span className="truncate max-w-[140px]">{orderNote}</span>
                </div>
              )}
            </div>

            {/* Items Table Formatted */}
            <div className="space-y-1 pb-2.5 border-b border-dashed border-slate-300">
              <div className="flex justify-between text-[10px] text-slate-500 font-bold uppercase pb-1 border-b border-slate-200">
                <span>Désignation</span>
                <span>Total TTC</span>
              </div>

              <div className="space-y-1 pt-1">
                {cart.map((item) => {
                  const lineOriginal = item.unitPrice * item.quantity;
                  const lineNet = lineOriginal * (1 - item.discountPercent / 100);
                  return (
                    <div key={item.product.id} className="space-y-0.5">
                      <div className="flex justify-between items-baseline gap-1">
                        <span className="font-semibold text-slate-900 truncate">
                          {item.product.name}
                        </span>
                        <span className="font-bold text-slate-900 shrink-0">
                          {formatMoney(lineNet)}
                        </span>
                      </div>
                      <div className="flex justify-between text-[9px] text-slate-500">
                        <span>
                          {item.quantity} x {formatMoney(item.unitPrice)}
                          {item.discountPercent > 0 && ` (-${item.discountPercent}%)`}
                        </span>
                        <span>TVA {Math.round(item.product.taxRate * 100)}%</span>
                      </div>
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Financial Summary */}
            <div className="space-y-1 pb-3 border-b border-dashed border-slate-300 text-[10px]">
              <div className="flex justify-between text-slate-600">
                <span>Sous-total Brut (HT) :</span>
                <span>{formatMoney(cartSummary.subtotalHT)}</span>
              </div>
              <div className="flex justify-between text-slate-600">
                <span>TVA globale :</span>
                <span>{formatMoney(cartSummary.totalTax)}</span>
              </div>
              {cartSummary.discountAmount > 0 && (
                <div className="flex justify-between text-emerald-700 font-semibold">
                  <span>Remise déduite :</span>
                  <span>-{formatMoney(cartSummary.discountAmount)}</span>
                </div>
              )}
              <div className="flex justify-between text-sm font-black text-slate-900 pt-1.5 border-t border-slate-300">
                <span>TOTAL NET TTC :</span>
                <span>{formatMoney(cartSummary.totalTTC)}</span>
              </div>
            </div>

            {/* Payment & Change Tendered */}
            <div className="space-y-1 pb-2 border-b border-dashed border-slate-300 text-[10px]">
              <div className="flex justify-between text-slate-700 font-bold">
                <span>Mode Règlement :</span>
                <span>
                  {paymentMethod === 'CASH'
                    ? 'ESPÈCES'
                    : paymentMethod === 'CARD'
                    ? 'CARTE BANCAIRE / CIB'
                    : 'CHÈQUE'}
                </span>
              </div>
              {paymentMethod === 'CASH' && (
                <>
                  <div className="flex justify-between text-slate-600">
                    <span>Espèces Reçues :</span>
                    <span>{formatMoney(amountTendered)}</span>
                  </div>
                  {changeToReturn > 0 && (
                    <div className="flex justify-between font-bold text-emerald-800">
                      <span>Monnaie à Rendre :</span>
                      <span>{formatMoney(changeToReturn)}</span>
                    </div>
                  )}
                </>
              )}
            </div>

            {/* Barcode representation */}
            <div className="pt-2 border-t border-dashed border-slate-300 text-center space-y-1.5">
              <div className="flex flex-col items-center justify-center">
                <div className="font-mono text-xs tracking-widest text-slate-700 font-bold">
                  ||||| | |||| ||| |||||
                </div>
                <div className="text-[8px] text-slate-400 font-mono mt-0.5">
                  {previewTicketNumber}
                </div>
              </div>
              <p className="text-[9px] text-slate-600 leading-tight">
                {printerSettings.receiptFooterMessage ||
                  "Gabarit d'impression conforme aux spécifications thermiques ESC/POS."}
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
            Retour / Modifier
          </button>

          <div className="flex items-center gap-2">
            <button
              type="button"
              onClick={handlePrint}
              className="touch-btn px-4 py-2.5 sherwood-btn-wood text-xs font-bold flex items-center gap-2"
              title="Tester l'impression sur imprimante thermique"
            >
              <Printer className="w-4 h-4 text-[#fcdbb6]" />
              <span>Imprimer Ticket Test ({activeWidth})</span>
            </button>

            <button
              type="button"
              onClick={onConfirmPayment}
              className="touch-btn px-5 py-2.5 sherwood-btn-forest text-xs font-bold flex items-center gap-2"
            >
              <CheckCircle2 className="w-4 h-4" />
              <span>Confirmer & Encaisser 🍃</span>
            </button>
          </div>
        </div>
      </div>
    </div>
  );
};
