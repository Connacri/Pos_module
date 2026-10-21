import React, { useEffect, useState } from 'react';
import { usePos } from '../../context/PosContext';
import {
  ShoppingCart,
  Trash2,
  Plus,
  Minus,
  Percent,
  Receipt,
  User,
  Tag,
  RotateCcw,
  CreditCard,
  Banknote,
  FileText,
  X,
  CheckCircle2,
  Printer,
  Eye,
} from 'lucide-react';
import { TransactionPrintPreviewModal } from '../receipt/TransactionPrintPreviewModal';
import { PrintableReceiptModal } from '../receipt/PrintableReceiptModal';

export const CartPanel: React.FC = () => {
  const {
    cart,
    cartSummary,
    customers,
    selectedCustomerId,
    setSelectedCustomerId,
    globalDiscountPercent,
    setGlobalDiscountPercent,
    orderNote,
    setOrderNote,
    updateQuantity,
    incrementQuantity,
    decrementQuantity,
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
  const [confirmClear, setConfirmClear] = useState(false);

  // Vidage en deux temps : un premier appui arme, un second confirme (annulé après 4 s)
  useEffect(() => {
    if (!confirmClear) return;
    const t = setTimeout(() => setConfirmClear(false), 4000);
    return () => clearTimeout(t);
  }, [confirmClear]);

  const handleClearClick = () => {
    if (confirmClear) {
      clearCart();
      setConfirmClear(false);
    } else {
      setConfirmClear(true);
    }
  };

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

  // Montant exact, puis arrondis au 500 / 1000 / 2000 DA supérieur (plus gros billet en circulation : 2000 DA)
  const cashSuggestions = Array.from(
    new Set([
      cartSummary.totalTTC,
      ...[500, 1000, 2000].map((step) => Math.ceil(cartSummary.totalTTC / step) * step),
    ])
  )
    .filter((v) => v > 0 && v >= cartSummary.totalTTC)
    .slice(0, 4);

  return (
    <div className="sherwood-card flex flex-col h-full overflow-hidden">
      {/* Cart Top Bar */}
      <div className="p-4 bg-forest-900 text-[#fcfbf7] border-b border-[#16311f] flex items-center justify-between">
        <div className="flex items-center gap-2.5">
          <div className="p-2 bg-[#8d5732] rounded-xl text-[#fcdbb6] shadow-xs">
            <ShoppingCart className="w-4 h-4" />
          </div>
          <div>
            <h3 className="font-bold text-sm text-[#fff5ea] font-serif-title">🍃 Panier de Vente</h3>
            <p className="text-xs text-[#c5ddc5]">
              {cartSummary.totalItems} articles ({cartSummary.uniqueCount} réf.)
            </p>
          </div>
        </div>

        {cart.length > 0 && (
          <button
            type="button"
            onClick={handleClearClick}
            className={`touch-btn text-xs flex items-center gap-1 px-3 rounded-lg transition-colors cursor-pointer ${
              confirmClear
                ? 'bg-rose-700 text-white font-bold'
                : 'text-[#f1a8a2] hover:text-[#fff2f0] hover:bg-[#284f35]'
            }`}
            title="Vider le panier"
          >
            <RotateCcw className="w-3.5 h-3.5" />
            <span>{confirmClear ? 'Confirmer ?' : 'Vider'}</span>
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
      <div className="p-3 bg-sand-100 border-b border-[#e5dcce] space-y-2">
        <div className="flex items-center gap-2">
          <User className="w-4 h-4 text-[#8a7f72] shrink-0" />
          <select
            value={selectedCustomerId}
            onChange={(e) => setSelectedCustomerId(Number(e.target.value))}
            className="flex-1 bg-sand-50 border border-[#e2d6c1] rounded-xl px-2.5 py-1.5 text-xs font-semibold text-[#233d2a] focus:outline-hidden focus:ring-2 focus:ring-[#234931]/20"
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
                className={`px-2 py-0.5 rounded-md text-xs font-semibold transition-colors cursor-pointer ${
                  globalDiscountPercent === pct
                    ? 'bg-forest-800 text-[#fdfbf7]'
                    : 'bg-sand-50 border border-[#e2d6c1] text-[#5d5244] hover:bg-[#efe8d8]'
                }`}
              >
                {pct}%
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Cart Items Scrollable List */}
      <div className="flex-1 overflow-y-auto divide-y divide-sand-100 p-2 space-y-1">
        {cart.length === 0 ? (
          <div className="h-full flex flex-col items-center justify-center p-6 text-center text-ink-600">
            <div className="w-12 h-12 rounded-full bg-sand-100 flex items-center justify-center mb-3 text-sand-300">
              <ShoppingCart className="w-6 h-6" />
            </div>
            <p className="font-semibold text-sm text-ink-700">Le panier est vide</p>
            <p className="text-xs text-ink-600 mt-1 max-w-[200px]">
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
                className="p-2.5 rounded-xl hover:bg-sand-50 transition-colors space-y-1.5"
              >
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <div className="font-semibold text-xs text-ink-900 truncate">
                      {item.product.name}
                    </div>
                    <div className="flex items-center gap-2 text-xs text-ink-600">
                      <span>{item.product.sku}</span>
                      <span>•</span>
                      <span>{formatMoney(item.unitPrice)} / u</span>
                      {item.product.taxRate > 0 && (
                        <span>(TVA {Math.round(item.product.taxRate * 100)}%)</span>
                      )}
                    </div>
                    {item.product.stock <= item.product.lowStockThreshold && (
                      <div className="mt-1">
                        <span className="inline-flex items-center gap-1 text-xs font-bold text-amber-800 bg-amber-100/80 px-1.5 py-0.5 rounded-md">
                          ⚠️ Seuil minimal : {item.product.stock} restant(s)
                        </span>
                      </div>
                    )}
                  </div>

                  {/* Line Total */}
                  <div className="text-right shrink-0">
                    <div className="font-bold text-xs text-ink-900 font-mono">
                      {formatMoney(lineNetTTC)}
                    </div>
                    {item.discountPercent > 0 && (
                      <div className="text-xs text-emerald-600 line-through font-mono">
                        {formatMoney(lineOriginalTTC)}
                      </div>
                    )}
                  </div>
                </div>

                {/* Controls: Quantity + Discount + Delete */}
                <div className="flex items-center justify-between pt-1">
                  {/* Quantity adjustment buttons */}
                  <div className="inline-flex items-center bg-white border border-sand-200 rounded-lg overflow-hidden shadow-2xs">
                    <button
                      type="button"
                      onClick={() => decrementQuantity(item.product.id)}
                      aria-label={`Retirer une unité de ${item.product.name}`}
                      className="touch-btn flex items-center justify-center text-ink-700 hover:bg-sand-100 font-bold text-xs cursor-pointer"
                    >
                      <Minus className="w-3 h-3" />
                    </button>
                    <input
                      type="number"
                      inputMode="numeric"
                      min="1"
                      aria-label={`Quantité de ${item.product.name}`}
                      value={item.quantity}
                      onChange={(e) =>
                        updateQuantity(item.product.id, Math.max(1, Number(e.target.value)))
                      }
                      className="w-12 h-11 text-center text-sm font-bold text-ink-900 border-x border-sand-200 focus:outline-hidden"
                    />
                    <button
                      type="button"
                      onClick={() => incrementQuantity(item.product.id)}
                      disabled={item.quantity >= item.product.stock}
                      aria-label={`Ajouter une unité de ${item.product.name}`}
                      className="touch-btn flex items-center justify-center text-ink-700 hover:bg-sand-100 disabled:opacity-30 font-bold text-xs cursor-pointer"
                    >
                      <Plus className="w-3 h-3" />
                    </button>
                  </div>

                  <div className="flex items-center gap-2">
                    {/* Item Discount Trigger */}
                    {isEditingDiscount ? (
                      <div className="inline-flex items-center gap-1 bg-white border border-sand-300 rounded-md px-1 py-0.5">
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
                          className="w-8 text-xs font-semibold text-center focus:outline-hidden"
                        />
                        <span className="text-xs text-ink-600">%</span>
                      </div>
                    ) : (
                      <button
                        type="button"
                        onClick={() => setEditingItemDiscountId(item.product.id)}
                        className={`touch-btn text-xs px-2 rounded-md font-medium border inline-flex items-center justify-center gap-1 cursor-pointer ${
                          item.discountPercent > 0
                            ? 'bg-emerald-50 text-emerald-700 border-emerald-200'
                            : 'bg-white text-ink-600 border-sand-200 hover:bg-sand-100'
                        }`}
                        title="Appliquer une remise article"
                        aria-label={`Remise sur ${item.product.name}`}
                      >
                        <Percent className="w-2.5 h-2.5" />
                        {item.discountPercent > 0 ? `-${item.discountPercent}%` : 'Remise'}
                      </button>
                    )}

                    {/* Delete item */}
                    <button
                      type="button"
                      onClick={() => removeFromCart(item.product.id)}
                      className="touch-btn inline-flex items-center justify-center text-ink-600 hover:text-rose-600 rounded-md hover:bg-rose-50 transition-colors cursor-pointer"
                      title="Retirer du panier"
                      aria-label={`Retirer ${item.product.name} du panier`}
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
      <div className="p-4 bg-sand-50 border-t border-sand-200/80 space-y-3">
        <div className="space-y-1.5 text-xs">
          <div className="flex justify-between text-ink-600">
            <span>Sous-total (HT):</span>
            <span className="font-medium text-ink-700 font-mono">{formatMoney(cartSummary.subtotalHT)}</span>
          </div>
          <div className="flex justify-between text-ink-600">
            <span>TVA calculée:</span>
            <span className="font-medium text-ink-700 font-mono">{formatMoney(cartSummary.totalTax)}</span>
          </div>
          {cartSummary.discountAmount > 0 && (
            <div className="flex justify-between text-emerald-600 font-medium">
              <span>Remise déduite:</span>
              <span className="font-mono">-{formatMoney(cartSummary.discountAmount)}</span>
            </div>
          )}
          <div className="pt-2 border-t border-sand-200 flex justify-between items-baseline">
            <span className="text-sm font-bold text-ink-900 font-serif-title">Total Net TTC:</span>
            <span className="text-xl font-extrabold text-forest-700 font-mono">
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
                ? 'bg-sand-100 text-[#9c9182] border-[#e5dcce] cursor-not-allowed'
                : 'bg-sand-50 hover:bg-sand-100 text-[#5d5244] border-[#e2d6c1] shadow-2xs'
            }`}
            title={`Aperçu Ticket ${printerSettings.paperWidth}`}
          >
            <Printer className="w-4 h-4 text-[#8d5732]" />
            <span className="hidden sm:inline">Aperçu ({printerSettings.paperWidth})</span>
          </button>

          <button
            type="button"
            disabled={cart.length === 0}
            onClick={handleStartCheckout}
            className={`flex-1 py-3 px-4 rounded-xl font-bold text-sm shadow-md flex items-center justify-center gap-2 transition-all cursor-pointer ${
              cart.length === 0
                ? 'bg-[#ece2d1] text-[#9c9182] cursor-not-allowed shadow-none'
                : 'bg-forest-700 hover:bg-[#23442e] active:scale-98 text-[#fdfbf7] shadow-[#2d563a]/20 border border-[#21402b]'
            }`}
          >
            <Receipt className="w-4 h-4 text-[#c5ddc5]" />
            <span>Encaisser {cart.length > 0 && `• ${formatMoney(cartSummary.totalTTC)}`}</span>
            <kbd className="hidden sm:inline-block bg-forest-900 text-[#e8f1e8] text-xs px-1.5 py-0.5 rounded-md font-mono">
              F2
            </kbd>
          </button>
        </div>
      </div>

      {/* Checkout Modal */}
      {isCheckoutOpen && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4">
          <div role="dialog" aria-modal="true" aria-labelledby="checkout-title" className="bg-sand-50 w-full max-w-md rounded-3xl shadow-2xl border border-[#e5dcce] overflow-hidden animate-in fade-in zoom-in-95 duration-200">
            <div className="px-5 py-4 bg-forest-900 text-[#fcfbf7] flex items-center justify-between border-b border-[#16311f]">
              <h3 id="checkout-title" className="font-bold text-sm flex items-center gap-2 font-serif-title">
                <Receipt className="w-4 h-4 text-[#a8d3a8]" />
                🍃 Règlement de la Vente Sherwood
              </h3>
              <button
                type="button"
                onClick={() => setIsCheckoutOpen(false)}
                aria-label="Fermer la fenêtre d'encaissement"
                className="touch-btn inline-flex items-center justify-center text-[#c5ddc5] hover:text-white transition-colors cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <div className="p-6 space-y-5">
              {/* Amount to pay banner */}
              <div className="bg-sand-100 border border-[#e5dcce] rounded-2xl p-4 text-center">
                <div className="text-xs font-semibold text-[#8d5732] uppercase tracking-wider">
                  Montant Total à Payer
                </div>
                <div className="text-3xl font-black text-forest-900 mt-1 font-serif-title font-mono">
                  {formatMoney(cartSummary.totalTTC)}
                </div>
                <div className="text-xs text-ink-600 mt-1">
                  Client : <span className="font-bold text-ink-900">{currentCustomer?.name}</span>
                </div>
              </div>

              {/* Payment Method Selector */}
              <div>
                <label className="block text-xs font-semibold text-ink-700 mb-2">
                  Mode de règlement
                </label>
                <div className="grid grid-cols-3 gap-2">
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CASH')}
                    aria-pressed={selectedPaymentMethod === 'CASH'}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CASH'
                        ? 'bg-sand-100 border-forest-700 text-forest-900 ring-2 ring-forest-700/30'
                        : 'bg-white border-sand-200 text-ink-700 hover:bg-sand-50'
                    }`}
                  >
                    <Banknote className="w-5 h-5 text-forest-700" />
                    Espèces
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CARD')}
                    aria-pressed={selectedPaymentMethod === 'CARD'}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CARD'
                        ? 'bg-sand-100 border-forest-700 text-forest-900 ring-2 ring-forest-700/30'
                        : 'bg-white border-sand-200 text-ink-700 hover:bg-sand-50'
                    }`}
                  >
                    <CreditCard className="w-5 h-5 text-forest-700" />
                    Carte bancaire
                  </button>
                  <button
                    type="button"
                    onClick={() => setSelectedPaymentMethod('CHEQUE')}
                    aria-pressed={selectedPaymentMethod === 'CHEQUE'}
                    className={`p-3 rounded-xl border text-xs font-bold flex flex-col items-center gap-2 transition-all cursor-pointer ${
                      selectedPaymentMethod === 'CHEQUE'
                        ? 'bg-sand-100 border-forest-700 text-forest-900 ring-2 ring-forest-700/30'
                        : 'bg-white border-sand-200 text-ink-700 hover:bg-sand-50'
                    }`}
                  >
                    <FileText className="w-5 h-5 text-forest-700" />
                    Chèque / Vir.
                  </button>
                </div>
              </div>

              {/* Cash Calculator if CASH selected */}
              {selectedPaymentMethod === 'CASH' && (
                <div className="space-y-3 bg-sand-50 p-3.5 rounded-xl border border-sand-200/80">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-semibold text-ink-700">Espèces reçues :</span>
                    <input
                      type="number"
                      min={cartSummary.totalTTC}
                      value={amountTenderedInput}
                      onChange={(e) => setAmountTenderedInput(e.target.value)}
                      className="w-32 px-2 py-1 text-right text-sm font-mono font-bold bg-white border border-sand-300 rounded-lg text-ink-900 focus:outline-hidden focus:ring-2 focus:ring-emerald-500/30"
                    />
                  </div>

                  {/* Quick cash denomination chips */}
                  <div className="flex items-center gap-1.5 flex-wrap">
                    {cashSuggestions.map((val) => (
                      <button
                        key={val}
                        type="button"
                        onClick={() => setAmountTenderedInput(val.toString())}
                        className="touch-btn px-3 bg-white border border-sand-200 rounded-md text-xs font-semibold text-ink-700 hover:bg-sand-100 cursor-pointer"
                      >
                        {val === cartSummary.totalTTC ? `Exact · ${formatMoney(val)}` : formatMoney(val)}
                      </button>
                    ))}
                  </div>

                  {/* Change returned feedback */}
                  <div className="pt-2 border-t border-sand-200 flex items-center justify-between text-xs">
                    <span className="text-ink-700 font-medium">Monnaie à rendre :</span>
                    <span
                      className={`text-sm font-mono font-black ${
                        changeToReturn > 0 ? 'text-emerald-700' : 'text-ink-600'
                      }`}
                    >
                      {formatMoney(changeToReturn)}
                    </span>
                  </div>
                </div>
              )}

              {/* Order note optional */}
              <div>
                <label className="block text-xs font-semibold text-ink-700 mb-1">
                  Note ticket / Bon de livraison (optionnel)
                </label>
                <input
                  type="text"
                  value={orderNote}
                  onChange={(e) => setOrderNote(e.target.value)}
                  placeholder="Ex: Commande N°42, livrer après 16h..."
                  className="w-full px-3 py-1.5 text-xs bg-sand-50 border border-sand-200 rounded-xl"
                />
              </div>

              {/* Actions */}
              <div className="pt-3 border-t border-sand-100 flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setIsCheckoutOpen(false)}
                  className="px-3 py-2.5 border border-sand-200 text-xs font-semibold text-ink-700 hover:bg-sand-50 rounded-xl transition-colors cursor-pointer"
                >
                  Annuler
                </button>
                <button
                  type="button"
                  onClick={() => setIsPrintPreviewOpen(true)}
                  className="px-3 py-2.5 bg-sand-100 hover:bg-sand-200 text-ink-900 border border-sand-300 rounded-xl text-xs font-bold transition-all flex items-center justify-center gap-1.5 cursor-pointer"
                  title={`Aperçu ticket ${printerSettings.paperWidth} avant validation finale`}
                >
                  <Eye className="w-3.5 h-3.5 text-forest-700" />
                  <span>Aperçu ({printerSettings.paperWidth})</span>
                </button>
                <button
                  type="button"
                  onClick={handleConfirmPayment}
                  className="flex-1 py-2.5 px-4 bg-forest-700 hover:bg-forest-800 text-sand-50 text-xs font-bold rounded-xl shadow-md transition-all flex items-center justify-center gap-2 cursor-pointer"
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
