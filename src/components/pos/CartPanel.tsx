import React, { useState } from 'react';
import { usePos } from '../../context/PosContext';
import {
  ShoppingCart,
  Trash2,
  Plus,
  Minus,
  Percent,
  User,
  CreditCard,
  Banknote,
  Receipt,
  RotateCcw,
  Tag,
  AlertCircle,
  FileText,
  Printer,
  CheckCircle2,
  X,
  Eye,
} from 'lucide-react';
import { PaymentMethod } from '../../types';
import { PrintableReceiptModal } from '../receipt/PrintableReceiptModal';
import { TransactionPrintPreviewModal } from '../receipt/TransactionPrintPreviewModal';

export const CartPanel: React.FC<{
  onOpenCheckout?: () => void;
  isCompact?: boolean;
}> = ({ isCompact = false }) => {
  const {
    cart,
    cartSummary,
    selectedCustomerId,
    setSelectedCustomerId,
    customers,
    globalDiscountPercent,
    setGlobalDiscountPercent,
    orderNote,
    setOrderNote,
    incrementQuantity,
    decrementQuantity,
    updateQuantity,
    setItemDiscount,
    removeFromCart,
    clearCart,
    completeSale,
    lastCompletedSale,
    setLastCompletedSale,
    isCheckoutOpen,
    setIsCheckoutOpen,
    isPrintPreviewOpen,
    setIsPrintPreviewOpen,
    selectedPaymentMethod,
    setSelectedPaymentMethod,
    amountTenderedInput,
    setAmountTenderedInput,
    initiateCheckout,
  } = usePos();

  const [editingItemDiscountId, setEditingItemDiscountId] = useState<number | null>(null);

  // Format currency in DA
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  const currentCustomer = customers.find((c) => c.id === selectedCustomerId);

  // Handle open checkout
  const handleStartCheckout = () => {
    initiateCheckout();
  };

  // Open thermal print preview modal before submission
  const handleOpenPrintPreview = () => {
    if (cart.length === 0) return;
    if (!amountTenderedInput) {
      setAmountTenderedInput(cartSummary.totalTTC.toString());
    }
    setIsPrintPreviewOpen(true);
  };

  // Handle submit checkout
  const handleConfirmPayment = () => {
    const tendered = Number(amountTenderedInput) || cartSummary.totalTTC;
    completeSale(selectedPaymentMethod, tendered);
  };

  const tenderedAmount = Number(amountTenderedInput) || cartSummary.totalTTC;
  const changeToReturn = Math.max(0, tenderedAmount - cartSummary.totalTTC);

  return (
    <div className="sherwood-card flex flex-col h-full overflow-hidden">
      {/* Cart Top Bar */}
      <div className="p-4 bg-[#1f3d29] text-[#fcfbf7] border-b border-[#16311f] flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="p-2 bg-[#8d5732] rounded-xl text-[#fcdbb6] shadow-xs">
            <ShoppingCart className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-sm text-[#fff5ea] font-serif-title">🍃 Panier de Vente</h3>
            <p className="text-[11px] text-[#c5ddc5]">
              {cartSummary.totalItems} articles ({cartSummary.uniqueCount} réf.)
            </p>
          </div>
        </div>

        {cart.length > 0 && (
          <button
            type="button"
            onClick={clearCart}
            className="text-xs text-[#f1a8a2] hover:text-[#fff2f0] flex items-center gap-1 px-2.5 py-1 rounded-lg hover:bg-[#284f35] transition-colors cursor-pointer"
            title="Vider le panier"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            Vider
          </button>
        )}
      </div>

      {/* Customer Selector & Quick Options */}
      <div className="p-3 bg-[#f7f2e7] border-b border-[#e5dcce] space-y-2">
        <div className="flex items-center gap-2">
          <User className="w-4 h-4 text-[#8a7f72] shrink-0" />
          <select
            value={selectedCustomerId}
            onChange={(e) => setSelectedCustomerId(Number(e.target.value))}
            className="flex-1 bg-[#fdfbf7] border border-[#e2d6c1] rounded-xl px-2.5 py-1.5 text-xs font-semibold text-[#233d2a] focus:outline-hidden focus:ring-2 focus:ring-[#234931]/20"
          >
            {customers.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name} {c.company ? `(${c.company})` : ''}
              </option>
            ))}
          </select>
        </div>

        {/* Global Discount toggle */}
        <div className="flex items-center justify-between text-xs">
          <div className="flex items-center gap-1.5">
            <Tag className="w-3.5 h-3.5 text-[#8a7f72]" />
            <span className="text-[#5d5244] font-medium">Remise globale:</span>
          </div>
          <div className="flex items-center gap-1">
            {[0, 5, 10, 15].map((pct) => (
              <button
                key={pct}
                type="button"
                onClick={() => setGlobalDiscountPercent(pct)}
                className={`px-2 py-0.5 rounded-md text-[11px] font-semibold transition-colors cursor-pointer ${
                  globalDiscountPercent === pct
                    ? 'bg-[#234931] text-[#fdfbf7]'
                    : 'bg-[#fdfbf7] border border-[#e2d6c1] text-[#5d5244] hover:bg-[#efe8d8]'
                }`}
              >
                {pct}%
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cart Items Scrollable List */}
      <div className="flex-1 overflow-y-auto divide-y divide-slate-100 p-2 space-y-1">
        {cart.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center p-6 text-center text-slate-400">
            <div className="w-12 h-12 rounded-full bg-slate-100 flex items-center justify-center mb-3 text-slate-300">
              <ShoppingCart className="w-6 h-6" />
            </div>
            <p className="font-semibold text-sm text-slate-700">Le panier est vide</p>
            <p className="text-xs text-slate-400 mt-1 max-w-[200px]">
              Sélectionnez des articles dans le catalogue ou scannez un code-barres.
            </p>
          </div>
        ) : (
          cart.map((item) => {
            const lineOriginalTTC = item.unitPrice * item.quantity;
            const lineNetTTC = lineOriginalTTC * (1 - item.discountPercent / 100);
            const isEditingDiscount = editingItemDiscountId === item.product.id;

            return (
              <div
                key={item.product.id}
                className="p-2.5 rounded-xl hover:bg-slate-50 transition-colors space-y-1.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-xs text-slate-900 truncate">
                      {item.product.name}
                    </div>
                    <div className="flex items-center gap-2 text-[10px] text-slate-400">
                      <span>{item.product.sku}</span>
                      <span>•</span>
                      <span>{formatMoney(item.unitPrice)} / u</span>
                      {item.product.taxRate > 0 && (
                        <span>(TVA {Math.round(item.product.taxRate * 100)}%)</span>
                      )}
                    </div>
                    {item.product.stock <= item.product.lowStockThreshold && (
                      <div className="mt-1">
                        <span className="inline-flex items-center gap-1 text-[9px] font-bold text-amber-800 bg-amber-100/80 px-1.5 py-0.5 rounded-md">
                          ⚠️ Seuil minimal : {item.product.stock} restant(s)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Line Total */}
                  <div className="text-right">
                    <div className="font-bold text-xs text-slate-900">
                      {formatMoney(lineNetTTC)}
                    </div>
                    {item.discountPercent > 0 && (
                      <div className="text-[10px] text-emerald-600 line-through">
                        {formatMoney(lineOriginalTTC)}
                      </div>
                    )}
                  </div>
                </div>

                {/* Controls: Quantity + Discount + Delete */}
                <div className="flex items-center justify-between pt-1">
                  {/* Quantity adjustment buttons */}
                  <div className="inline-flex items-center bg-white border border-slate-200 rounded-lg overflow-hidden shadow-2xs">
                    <button
                      type="button"
                      onClick={() => decrementQuantity(item.product.id)}
                      className="w-6 h-6 flex items-center justify-center text-slate-600 hover:bg-slate-100 font-bold text-xs cursor-pointer"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <input
                      type="number"
                      min="1"
                      value={item.quantity}
                      onChange={(e) =>
                        updateQuantity(item.product.id, Math.max(1, Number(e.target.value)))
                      }
                      className="w-8 text-center text-xs font-bold text-slate-800 border-x border-slate-200 py-0.5 focus:outline-hidden"
                    />
                    <button
                      type="button"
                      onClick={() => incrementQuantity(item.product.id)}
                      disabled={item.quantity >= item.product.stock}
                      className="w-6 h-6 flex items-center justify-center text-slate-600 hover:bg-slate-100 disabled:opacity-30 font-bold text-xs cursor-pointer"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>

                  <div className="flex items-center gap-2">
                    {/* Item Discount Trigger */}
                    {isEditingDiscount ? (
                      <div className="inline-flex items-center gap-1 bg-white border border-indigo-300 rounded-md px-1 py-0.5">
                        <input
                          type="number"
                          min="0"
                          max="100"
                          autoFocus
                          value={item.discountPercent || ''}
                          placeholder="%"
                          onChange={(e) =>
                            setItemDiscount(item.product.id, Number(e.target.value))
                          }
                          onBlur={() => setEditingItemDiscountId(null)}
                          className="w-8 text-[11px] font-semibold text-center focus:outline-hidden"
                        />
                        <span className="text-[10px] text-slate-400">%</span>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setEditingItemDiscountId(item.product.id)}
                        className={`text-[10px] px-1.5 py-0.5 rounded-md font-medium border flex items-center gap-0.5 cursor-pointer ${
                          item.discountPercent > 0
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : 'bg-white text-slate-500 border-slate-200 hover:bg-slate-100'
                        }`}
                        title="Appliquer une remise article"
                      >
                        <Percent className="w-2.5 h-2.5" />
                        {item.discountPercent > 0 ? `-${item.discountPercent}%` : 'Remise'}
                      </button>
                    )}

                    {/* Delete item */}
                    <button
                      type="button"
                      onClick={() => removeFromCart(item.product.id)}
                      className="text-slate-400 hover:text-rose-600 p-1 rounded-md hover:bg-rose-50 transition-colors cursor-pointer"
                      title="Retirer du panier"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              </div>
            );
          })
        )}
      </div>

      {/* Real-time Totals & Checkout Trigger */}
      <div className="p-4 bg-slate-50 border-t border-slate-200/80 space-y-3">
        <div className="space-y-1.5 text-xs">
          <div className="flex justify-between text-slate-500">
            <span>Sous-total (HT):</span>
            <span className="font-medium text-slate-700">{formatMoney(cartSummary.subtotalHT)}</span>
          </div>
          <div className="flex justify-between text-slate-500">
            <span>TVA calculée:</span>
            <span className="font-medium text-slate-700">{formatMoney(cartSummary.totalTax)}</span>
          </div>
          {cartSummary.discountAmount > 0 && (
            <div className="flex justify-between text-emerald-600 font-medium">
              <span>Remise déduite:</span>
              <span>-{formatMoney(cartSummary.discountAmount)}</span>
            </div>
          )}
          <div className="pt-2 border-t border-slate-200 flex justify-between items-baseline">
            <span className="text-sm font-bold text-slate-900">Total Net TTC:</span>
            <span className="text-xl font-extrabold text-indigo-600">
              {formatMoney(cartSummary.totalTTC)}
            </span>
          </div>
        </div>

        {/* Action Buttons: Encaisser + Aperçu 80mm */}
        <div className="flex items-center gap-2">
          <button
            type="button"
            disabled={cart.length === 0}
            onClick={handleOpenPrintPreview}
            className={`py-3 px-3.5 rounded-xl font-bold text-xs border transition-all flex items-center justify-center gap-1.5 cursor-pointer shrink-0 ${
              cart.length === 0
                ? 'bg-[#f7f2e7] text-[#9c9182] border-[#e5dcce] cursor-not-allowed'
                : 'bg-[#fdfbf7] hover:bg-[#f7f2e7] text-[#5d5244] border-[#e2d6c1] shadow-2xs'
            }`}
            title="Aperçu Ticket thermique 80mm avant encaissement"
          >
            <Printer className="w-4 h-4 text-[#8d5732]" />
            <span className="hidden sm:inline">Aperçu 80mm</span>
          </button>

          <button
            type="button"
            disabled={cart.length === 0}
            onClick={handleStartCheckout}
            className={`flex-1 py-3 px-4 rounded-xl font-bold text-sm shadow-md flex items-center justify-center gap-2 transition-all cursor-pointer ${
              cart.length === 0
                ? 'bg-[#ece2d1] text-[#9c9182] cursor-not-allowed shadow-none'
                : 'bg-[#2d563a] hover:bg-[#23442e] active:scale-98 text-[#fdfbf7] shadow-[#2d563a]/20 border border-[#21402b]'
            }`}
          >
            <Receipt className="w-4 h-4 text-[#c5ddc5]" />
            <span>Encaisser {cart.length > 0 && `• ${formatMoney(cartSummary.totalTTC)}`}</span>
            <kbd className="hidden sm:inline-block bg-[#1f3d29] text-[#e8f1e8] text-[10px] px-1.5 py-0.5 rounded-md font-mono">
              F2
            </kbd>
          </button>
        </div>
      </div>

      {/* Checkout Modal */}
      {isCheckoutOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div className="bg-[#fdfbf7] w-full max-w-md rounded-3xl shadow-2xl border border-[#e5dcce] overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="px-5 py-4 bg-[#1f3d29] text-[#fcfbf7] flex items-center justify-between border-b border-[#16311f]">
              <h3 className="font-bold text-sm flex items-center gap-2 font-serif-title">
                <Receipt className="w-4 h-4 text-[#a8d3a8]" />
                🍃 Règlement de la Vente Sherwood
              </h3>
              <button
                type="button"
                onClick={() => setIsCheckoutOpen(false)}
                className="text-[#c5ddc5] hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-5">
              {/* Amount to pay banner */}
              <div className="bg-[#f7f2e7] border border-[#e5dcce] rounded-2xl p-4 text-center">
                <div className="text-xs font-semibold text-[#8d5732] uppercase tracking-wider">
                  Montant Total à Payer
                </div>
                <div className="text-3xl font-black text-[#233d2a] mt-1 font-serif-title">
                  {formatMoney(cartSummary.totalTTC)}
                </div>
                <div className="text-xs text-[#5d5244] mt-1">
                  Client : <span className="font-semibold text-[#233d2a]">{currentCustomer?.name}</span>
                </div>
              </div>

              {/* Payment Method Selector */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-2">
                  Mode de règlement
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CASH')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CASH'
                        ? 'bg-emerald-50 border-emerald-500 text-emerald-800 ring-2 ring-emerald-500/20'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    <Banknote className="w-5 h-5 text-emerald-600" />
                    Espèces
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CARD')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CARD'
                        ? 'bg-blue-50 border-blue-500 text-blue-800 ring-2 ring-blue-500/20'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    <CreditCard className="w-5 h-5 text-blue-600" />
                    Carte bancaire
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CHEQUE')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CHEQUE'
                        ? 'bg-amber-50 border-amber-500 text-amber-800 ring-2 ring-amber-500/20'
                        : 'bg-white border-slate-200 text-slate-700 hover:bg-slate-50'
                    }`}
                  >
                    <FileText className="w-5 h-5 text-amber-600" />
                    Chèque / Vir.
                  </button>
                </div>
              </div>

              {/* Cash Calculator if CASH selected */}
              {selectedPaymentMethod === 'CASH' && (
                <div className="space-y-3 bg-slate-50 p-3.5 rounded-xl border border-slate-200/80">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-semibold text-slate-700">Espèces reçues :</span>
                    <input
                      type="number"
                      min={cartSummary.totalTTC}
                      value={amountTenderedInput}
                      onChange={(e) => setAmountTenderedInput(e.target.value)}
                      className="w-28 px-2 py-1 text-right text-sm font-bold bg-white border border-slate-300 rounded-lg text-slate-900 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30"
                    />
                  </div>

                  {/* Quick cash denomination chips */}
                  <div className="flex items-center gap-1.5 flex-wrap">
                    {[cartSummary.totalTTC, 1000, 2000, 5000, 10000]
                      .filter((val, idx, arr) => val >= cartSummary.totalTTC && arr.indexOf(val) === idx)
                      .slice(0, 4)
                      .map((val) => (
                        <button
                          key={val}
                          type="button"
                          onClick={() => setAmountTenderedInput(val.toString())}
                          className="px-2 py-1 bg-white border border-slate-200 rounded-md text-[11px] font-semibold text-slate-700 hover:bg-slate-100 cursor-pointer"
                        >
                          {val} DA
                        </button>
                      ))}
                  </div>

                  {/* Change returned feedback */}
                  <div className="pt-2 border-t border-slate-200 flex items-center justify-between text-xs">
                    <span className="text-slate-600 font-medium">Monnaie à rendre :</span>
                    <span
                      className={`text-sm font-black ${
                        changeToReturn > 0 ? 'text-emerald-700' : 'text-slate-500'
                      }`}
                    >
                      {formatMoney(changeToReturn)}
                    </span>
                  </div>
                </div>
              )}

              {/* Order note optional */}
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Note ticket / Bon de livraison (optionnel)
                </label>
                <input
                  type="text"
                  value={orderNote}
                  onChange={(e) => setOrderNote(e.target.value)}
                  placeholder="Ex: Commande N°42, livrer après 16h..."
                  className="w-full px-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl"
                />
              </div>

              {/* Actions */}
              <div className="pt-3 border-t border-slate-100 flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setIsCheckoutOpen(false)}
                  className="px-3 py-2.5 border border-slate-200 text-xs font-semibold text-slate-700 hover:bg-slate-50 rounded-xl transition-colors cursor-pointer"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={() => setIsPrintPreviewOpen(true)}
                  className="px-3 py-2.5 bg-slate-100 hover:bg-slate-200 text-slate-800 border border-slate-300 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
                  title="Aperçu ticket 80mm avant validation finale"
                >
                  <Eye className="w-3.5 h-3.5 text-indigo-600" />
                  <span>Aperçu (80mm)</span>
                </button>
                <button
                  type="button"
                  onClick={handleConfirmPayment}
                  className="flex-1 py-2.5 px-4 bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold rounded-xl shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Valider l'Encaissement</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* 80mm Thermal Receipt Print Preview Modal (Before Final Submission) */}
      <TransactionPrintPreviewModal
        isOpen={isPrintPreviewOpen}
        onClose={() => setIsPrintPreviewOpen(false)}
        onConfirmPayment={handleConfirmPayment}
        paymentMethod={selectedPaymentMethod}
        amountTendered={tenderedAmount}
      />

      {/* Sale Success & Printable Receipt Modal */}
      {lastCompletedSale && (
        <PrintableReceiptModal
          sale={lastCompletedSale}
          onClose={() => setLastCompletedSale(null)}
        />
      )}
    </div>
  );
};
