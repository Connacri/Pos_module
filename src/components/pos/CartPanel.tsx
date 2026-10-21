import React, { useState, useMemo } from 'react';
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
    canUndoClearCart,
    undoClearCart,
    printerSettings,
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

  // Smart realistic Algerian banknote denominations: 200, 500, 1000, 2000 DA
  const cashDenominationOptions = useMemo(() => {
    const total = cartSummary.totalTTC;
    const options: number[] = [total];

    // Common Algerian bank notes
    const algerianNotes = [500, 1000, 2000];

    // Next round notes
    algerianNotes.forEach((note) => {
      if (note >= total && !options.includes(note)) {
        options.push(note);
      }
    });

    // Next rounded amounts for larger baskets (multiples of 1000 or 2000)
    if (total > 2000) {
      const next1000 = Math.ceil(total / 1000) * 1000;
      if (!options.includes(next1000)) options.push(next1000);

      const next2000 = Math.ceil(total / 2000) * 2000;
      if (!options.includes(next2000)) options.push(next2000);
    }

    return options.sort((a, b) => a - b).slice(0, 4);
  }, [cartSummary.totalTTC]);

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
            onClick={() => clearCart(true)}
            className="text-xs text-[#f5c7c2] hover:text-[#fff2f0] flex items-center gap-1 px-2.5 py-1 rounded-lg hover:bg-[#284f35] transition-colors cursor-pointer"
            title="Vider le panier (avec possibilité d'annulation)"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>Vider</span>
          </button>
        )}
      </div>

      {/* Undo Banner if cart was just cleared */}
      {canUndoClearCart && (
        <div className="p-2.5 bg-[#fef4ea] border-b border-[#f5cf9e] text-xs font-semibold text-[#8f521b] flex items-center justify-between animate-in slide-in-from-top-1 duration-200">
          <span>Panier réinitialisé.</span>
          <button
            type="button"
            onClick={undoClearCart}
            className="touch-btn px-2.5 py-1 bg-[#85522b] text-white hover:bg-[#6d3e1d] rounded-lg font-bold flex items-center gap-1 shadow-2xs cursor-pointer"
          >
            <RotateCcw className="w-3 h-3" />
            <span>Annuler (Rétablir)</span>
          </button>
        </div>
      )}

      {/* Customer Selector & Quick Options */}
      <div className="p-3 bg-[#f7f2e7] border-b border-[#e5dcce] space-y-2">
        <div className="flex items-center gap-2">
          <User className="w-4 h-4 text-[#605547] shrink-0" />
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
            <Tag className="w-3.5 h-3.5 text-[#605547]" />
            <span className="text-[#483d31] font-semibold">Remise globale:</span>
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
                    : 'bg-[#fdfbf7] border border-[#e2d6c1] text-[#483d31] hover:bg-[#efe8d8]'
                }`}
              >
                {pct}%
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cart Items Scrollable List */}
      <div className="flex-1 overflow-y-auto divide-y divide-[#ece2d1] p-2 space-y-1">
        {cart.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center p-6 text-center text-[#877a6b]">
            <div className="w-12 h-12 rounded-2xl bg-[#f7f2e7] border border-[#e7ddca] flex items-center justify-center mb-3 text-[#a89984]">
              <ShoppingCart className="w-6 h-6" />
            </div>
            <p className="font-bold text-sm text-[#2c241c]">Le panier est vide</p>
            <p className="text-xs text-[#605547] mt-1 max-w-[210px] font-medium leading-relaxed">
              Sélectionnez des articles dans le catalogue ou scannez un code-barres EAN.
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
                className="p-2.5 rounded-xl hover:bg-[#f7f2e7]/70 transition-colors space-y-1.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="font-bold text-xs text-[#2c241c] line-clamp-2">
                      {item.product.name}
                    </div>
                    <div className="flex items-center gap-2 text-[10px] text-[#605547] mt-0.5 font-mono">
                      <span>{item.product.sku}</span>
                      <span>•</span>
                      <span>{formatMoney(item.unitPrice)} / u</span>
                      {item.product.taxRate > 0 && (
                        <span>(TVA {Math.round(item.product.taxRate * 100)}%)</span>
                      )}
                    </div>
                    {item.product.stock <= item.product.lowStockThreshold && (
                      <div className="mt-1">
                        <span className="inline-flex items-center gap-1 text-[9px] font-bold text-[#92400e] bg-[#fffbeb] border border-[#fde68a] px-1.5 py-0.5 rounded-md">
                          ⚠️ Seuil alerte : {item.product.stock} restant(s)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Line Total */}
                  <div className="text-right shrink-0">
                    <div className="font-black text-xs text-[#234931] font-mono">
                      {formatMoney(lineNetTTC)}
                    </div>
                    {item.discountPercent > 0 && (
                      <div className="text-[10px] text-[#877a6b] line-through font-mono">
                        {formatMoney(lineOriginalTTC)}
                      </div>
                    )}
                  </div>
                </div>

                {/* Controls: Quantity + Discount + Delete */}
                <div className="flex items-center justify-between pt-1">
                  {/* Quantity adjustment buttons with w-14 input */}
                  <div className="inline-flex items-center bg-white border border-[#d8cdba] rounded-xl overflow-hidden shadow-2xs">
                    <button
                      type="button"
                      onClick={() => decrementQuantity(item.product.id)}
                      className="w-7 h-7 flex items-center justify-center text-[#483d31] hover:bg-[#f4efe4] font-bold text-xs cursor-pointer"
                      title="Diminuer"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <input
                      type="number"
                      inputMode="numeric"
                      min="1"
                      value={item.quantity}
                      onChange={(e) =>
                        updateQuantity(item.product.id, Math.max(1, Number(e.target.value)))
                      }
                      className="w-14 text-center text-xs font-mono font-bold text-[#2c241c] border-x border-[#d8cdba] py-0.5 focus:outline-hidden"
                    />
                    <button
                      type="button"
                      onClick={() => incrementQuantity(item.product.id)}
                      disabled={item.quantity >= item.product.stock}
                      className="w-7 h-7 flex items-center justify-center text-[#483d31] hover:bg-[#f4efe4] disabled:opacity-30 font-bold text-xs cursor-pointer"
                      title="Augmenter"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>

                  <div className="flex items-center gap-2">
                    {/* Item Discount Trigger */}
                    {isEditingDiscount ? (
                      <div className="inline-flex items-center gap-1 bg-white border border-[#234931] rounded-lg px-1.5 py-0.5">
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
                          className="w-10 text-[11px] font-semibold text-center focus:outline-hidden"
                        />
                        <span className="text-[10px] text-[#605547]">%</span>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setEditingItemDiscountId(item.product.id)}
                        className={`text-[10px] px-2 py-0.5 rounded-lg font-bold border flex items-center gap-0.5 cursor-pointer ${
                          item.discountPercent > 0
                            ? 'bg-[#eaf2e8] text-[#234931] border-[#cbe0cb]'
                            : 'bg-white text-[#605547] border-[#d8cdba] hover:bg-[#f7f2e7]'
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
                      className="text-[#877a6b] hover:text-[#b91c1c] p-1 rounded-lg hover:bg-[#fee2e2]/60 transition-colors cursor-pointer"
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
      <div className="p-4 bg-[#f7f2e7] border-t border-[#e5dcce] space-y-3">
        <div className="space-y-1.5 text-xs">
          <div className="flex justify-between text-[#605547] font-medium">
            <span>Sous-total (HT):</span>
            <span className="font-mono text-[#2c241c]">{formatMoney(cartSummary.subtotalHT)}</span>
          </div>
          <div className="flex justify-between text-[#605547] font-medium">
            <span>TVA calculée:</span>
            <span className="font-mono text-[#2c241c]">{formatMoney(cartSummary.totalTax)}</span>
          </div>
          {cartSummary.discountAmount > 0 && (
            <div className="flex justify-between text-[#234931] font-bold">
              <span>Remise déduite:</span>
              <span className="font-mono">-{formatMoney(cartSummary.discountAmount)}</span>
            </div>
          )}
          <div className="pt-2 border-t border-[#e2d7c2] flex justify-between items-baseline">
            <span className="text-sm font-black text-[#2c241c] font-serif-title">Total Net TTC:</span>
            <span className="text-xl font-black text-[#234931] font-mono">
              {formatMoney(cartSummary.totalTTC)}
            </span>
          </div>
        </div>

        {/* Action Buttons: Unified Sherwood Tokens */}
        <div className="flex items-center gap-2">
          <button
            type="button"
            disabled={cart.length === 0}
            onClick={handleOpenPrintPreview}
            className={`py-3 px-3.5 rounded-xl font-bold text-xs border transition-all flex items-center justify-center gap-1.5 cursor-pointer shrink-0 ${
              cart.length === 0
                ? 'bg-[#ece2d1] text-[#9c9182] border-[#e5dcce] cursor-not-allowed'
                : 'bg-[#fdfbf7] hover:bg-[#f4efe4] text-[#85522b] border-[#e2d7c2] shadow-2xs'
            }`}
            title={`Aperçu Ticket ${printerSettings.paperWidth}`}
          >
            <Printer className="w-4 h-4 text-[#85522b]" />
            <span className="hidden sm:inline">Aperçu ({printerSettings.paperWidth})</span>
          </button>

          <button
            type="button"
            disabled={cart.length === 0}
            onClick={handleStartCheckout}
            className={`flex-1 py-3 px-4 rounded-xl font-bold text-sm shadow-md flex items-center justify-center gap-2 transition-all cursor-pointer ${
              cart.length === 0
                ? 'bg-[#ece2d1] text-[#9c9182] cursor-not-allowed shadow-none'
                : 'sherwood-btn-forest text-white'
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
                🍃 Règlement de la Vente
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
                <div className="text-xs font-semibold text-[#85522b] uppercase tracking-wider">
                  Montant Total Net à Payer
                </div>
                <div className="text-3xl font-black text-[#234931] mt-1 font-serif-title font-mono">
                  {formatMoney(cartSummary.totalTTC)}
                </div>
                <div className="text-xs text-[#605547] mt-1">
                  Client : <span className="font-bold text-[#2c241c]">{currentCustomer?.name}</span>
                </div>
              </div>

              {/* Payment Method Selector */}
              <div>
                <label className="block text-xs font-bold text-[#2c241c] mb-2">
                  Mode de règlement
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CASH')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CASH'
                        ? 'bg-[#eaf2e8] border-[#234931] text-[#234931] ring-2 ring-[#234931]/20 shadow-xs'
                        : 'bg-white border-[#d8cdba] text-[#483d31] hover:bg-[#f7f2e7]'
                    }`}
                  >
                    <Banknote className="w-5 h-5 text-[#234931]" />
                    Espèces
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CARD')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CARD'
                        ? 'bg-[#eaf2e8] border-[#234931] text-[#234931] ring-2 ring-[#234931]/20 shadow-xs'
                        : 'bg-white border-[#d8cdba] text-[#483d31] hover:bg-[#f7f2e7]'
                    }`}
                  >
                    <CreditCard className="w-5 h-5 text-[#234931]" />
                    Carte / CIB
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CHEQUE')}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-1.5 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CHEQUE'
                        ? 'bg-[#eaf2e8] border-[#234931] text-[#234931] ring-2 ring-[#234931]/20 shadow-xs'
                        : 'bg-white border-[#d8cdba] text-[#483d31] hover:bg-[#f7f2e7]'
                    }`}
                  >
                    <FileText className="w-5 h-5 text-[#234931]" />
                    Chèque / Vir.
                  </button>
                </div>
              </div>

              {/* Cash Calculator if CASH selected */}
              {selectedPaymentMethod === 'CASH' && (
                <div className="space-y-3 bg-[#f7f2e7] p-3.5 rounded-2xl border border-[#e2d7c2]">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-[#2c241c]">Espèces reçues :</span>
                    <input
                      type="number"
                      min={cartSummary.totalTTC}
                      value={amountTenderedInput}
                      onChange={(e) => setAmountTenderedInput(e.target.value)}
                      className="w-32 px-2.5 py-1 text-right text-sm font-mono font-bold bg-white border border-[#d8cdba] rounded-xl text-[#2c241c] focus:outline-hidden focus:ring-2 focus:ring-[#234931]/20"
                    />
                  </div>

                  {/* Realistic Algerian Banknote Denomination Chips (DA) */}
                  <div className="flex items-center gap-1.5 flex-wrap">
                    {cashDenominationOptions.map((val) => (
                      <button
                        key={val}
                        type="button"
                        onClick={() => setAmountTenderedInput(val.toString())}
                        className="px-2.5 py-1 bg-white border border-[#d8cdba] hover:border-[#234931] rounded-lg text-[11px] font-bold font-mono text-[#2c241c] hover:bg-[#eaf2e8] cursor-pointer transition-colors shadow-2xs"
                      >
                        {formatMoney(val)}
                      </button>
                    ))}
                  </div>

                  {/* Change returned feedback */}
                  <div className="pt-2 border-t border-[#d8cdba] flex items-center justify-between text-xs">
                    <span className="text-[#605547] font-semibold">Monnaie à rendre :</span>
                    <span
                      className={`text-sm font-mono font-black ${
                        changeToReturn > 0 ? 'text-[#234931]' : 'text-[#877a6b]'
                      }`}
                    >
                      {formatMoney(changeToReturn)}
                    </span>
                  </div>
                </div>
              )}

              {/* Order note optional */}
              <div>
                <label className="block text-xs font-bold text-[#2c241c] mb-1">
                  Note ticket / Bon de livraison (optionnel)
                </label>
                <input
                  type="text"
                  value={orderNote}
                  onChange={(e) => setOrderNote(e.target.value)}
                  placeholder="Ex: Commande N°42, livrer après 16h..."
                  className="w-full px-3 py-2 text-xs bg-[#f7f2e7] border border-[#d8cdba] rounded-xl text-[#2c241c] focus:outline-hidden focus:border-[#234931]"
                />
              </div>

              {/* Actions */}
              <div className="pt-3 border-t border-[#e5dcce] flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setIsCheckoutOpen(false)}
                  className="px-3.5 py-2.5 sherwood-btn-outline text-xs font-bold"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={() => setIsPrintPreviewOpen(true)}
                  className="px-3.5 py-2.5 sherwood-btn-wood text-xs font-bold flex items-center justify-center gap-1.5"
                  title={`Aperçu ticket ${printerSettings.paperWidth} avant validation`}
                >
                  <Eye className="w-3.5 h-3.5" />
                  <span>Aperçu ({printerSettings.paperWidth})</span>
                </button>
                <button
                  type="button"
                  onClick={handleConfirmPayment}
                  className="flex-1 py-2.5 px-4 sherwood-btn-forest text-xs font-bold flex items-center justify-center gap-2"
                >
                  <CheckCircle2 className="w-4 h-4" />
                  <span>Valider l'Encaissement</span>
                </button>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* Thermal Receipt Print Preview Modal (Before Final Submission) */}
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
