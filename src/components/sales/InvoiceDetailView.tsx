import React, { useState } from 'react';
import { usePos } from '../../context/PosContext';
import { Sale } from '../../types';
import { PrintableReceiptModal } from '../receipt/PrintableReceiptModal';
import {
  ArrowLeft,
  CreditCard,
  Edit,
  Trash2,
  Search,
  SlidersHorizontal,
  LayoutGrid,
  List,
  MoreHorizontal,
  Calendar,
  Phone,
  Mail,
  Plus,
  ArrowUpRight,
  Printer,
  CheckCircle2,
  DollarSign,
  Package,
} from 'lucide-react';

export const InvoiceDetailView: React.FC<{
  sale: Sale;
  onBack: () => void;
}> = ({ sale, onBack }) => {
  const { customers, products } = usePos();
  const [searchQuery, setSearchQuery] = useState('');
  const [activeTab, setActiveTab] = useState<'lines' | 'details' | 'docs' | 'notes'>('lines');
  const [viewMode, setViewMode] = useState<'grid' | 'list'>('grid');
  const [showReceiptModal, setShowReceiptModal] = useState(false);

  const customer = customers.find((c) => c.id === sale.customerId);

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Filter items
  const filteredItems = sale.items.filter((it) =>
    it.productName.toLowerCase().includes(searchQuery.toLowerCase()) ||
    it.sku.toLowerCase().includes(searchQuery.toLowerCase())
  );

  const totalQuantity = sale.items.reduce((sum, it) => sum + it.quantity, 0);

  // Financial breakdown calculation
  const totalAmount = sale.totalTTC;
  const isPaid = sale.status === 'COMPLETED';
  const paidAmount = isPaid ? totalAmount : 0;
  const creditAmount = Math.round(totalAmount * 0.15);
  const balanceDue = Math.max(0, totalAmount - paidAmount);

  return (
    <div className="space-y-6 max-w-7xl mx-auto animate-in fade-in duration-200">
      {/* Top Bar Navigation */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 sherwood-panel p-4">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="touch-btn p-2 sherwood-btn-outline flex items-center justify-center cursor-pointer shadow-xs"
            aria-label="Retour"
          >
            <ArrowLeft className="w-4 h-4 text-[#234931]" />
          </button>
          <div>
            <span className="text-[11px] text-[#877a6b] font-bold uppercase tracking-wider block">
              Facturation & Vente
            </span>
            <h2 className="text-base sm:text-lg font-black text-[#234931] font-serif-title leading-tight">
              Facture {sale.saleNumber}
            </h2>
          </div>
        </div>

        {/* Action buttons */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            onClick={() => setShowReceiptModal(true)}
            className="touch-btn px-3.5 py-2 sherwood-btn-forest text-xs font-bold flex items-center gap-1.5"
          >
            <Printer className="w-3.5 h-3.5" />
            <span>Imprimer Ticket</span>
          </button>
          <button
            type="button"
            className="touch-btn px-3.5 py-2 sherwood-btn-outline text-xs font-bold flex items-center gap-1.5"
          >
            <CreditCard className="w-3.5 h-3.5 text-[#85522b]" />
            <span>Avoir / Crédit</span>
          </button>
          <button
            type="button"
            className="touch-btn px-3.5 py-2 sherwood-btn-wood text-xs font-bold flex items-center gap-1.5"
          >
            <Edit className="w-3.5 h-3.5" />
            <span>Modifier</span>
          </button>
        </div>
      </div>

      {/* Hero Financial Banner */}
      <div className="sherwood-panel p-6 space-y-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          {/* Big Amount */}
          <div className="flex items-baseline gap-2">
            <span className="text-2xl sm:text-3xl font-black text-[#877a6b]">DA</span>
            <span className="text-3xl sm:text-5xl font-black text-[#234931] font-serif-title tracking-tight">
              {new Intl.NumberFormat('fr-DZ', { maximumFractionDigits: 2 }).format(totalAmount)}
            </span>
          </div>

          {/* Metadata chips */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
            <div className="sherwood-panel-subtle p-3">
              <span className="text-[10px] text-[#877a6b] uppercase font-bold block">Client</span>
              <span className="font-bold text-[#2c241c] truncate block">
                {sale.customerName || 'Client Comptoir'}
              </span>
            </div>
            <div className="sherwood-panel-subtle p-3">
              <span className="text-[10px] text-[#877a6b] uppercase font-bold block">Réf. Facture</span>
              <span className="font-mono font-bold text-[#234931] block">
                {sale.saleNumber}
              </span>
            </div>
            <div className="sherwood-panel-subtle p-3 col-span-2 sm:col-span-1">
              <span className="text-[10px] text-[#877a6b] uppercase font-bold block">Statut</span>
              <span className="inline-flex items-center gap-1 font-bold text-emerald-800">
                <CheckCircle2 className="w-3.5 h-3.5 text-emerald-700" />
                Payée • Validée
              </span>
            </div>
          </div>
        </div>

        {/* Progress Bar / Pill indicators */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center gap-3 pt-2">
          <div className="flex-1 flex flex-wrap sm:flex-nowrap items-center gap-2">
            {/* Paid Pill */}
            <div className="flex-1 min-w-[130px] bg-[#eaf2e8] text-[#234931] border border-[#cbe0cb] px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-2xs">
              <CheckCircle2 className="w-4 h-4 text-[#234931]" />
              <span>Payé {formatMoney(paidAmount)}</span>
            </div>

            {/* Credit Pill */}
            <div className="flex-1 min-w-[120px] bg-[#faeee2] text-[#85522b] border border-[#f0d4ba] px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-2xs">
              <CreditCard className="w-4 h-4 text-[#85522b]" />
              <span>Crédit {formatMoney(creditAmount)}</span>
            </div>

            {/* Balance Pill */}
            <div className="flex-1 min-w-[120px] bg-[#f7f2e7] border border-dashed border-[#d8cdba] text-[#605547] px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2">
              <DollarSign className="w-4 h-4 text-[#877a6b]" />
              <span>Solde {formatMoney(balanceDue)}</span>
            </div>
          </div>

          {/* Pay Button / Outstanding Pill */}
          <div className="flex items-center gap-2 justify-end">
            <span className="text-xs text-[#605547] font-medium px-2.5 py-1 bg-[#f7f2e7] rounded-xl border border-[#e2d7c2]">
              Délai: <strong className="text-[#2c241c]">Comptant</strong>
            </span>
            <button
              type="button"
              className="touch-btn px-4 py-2 sherwood-btn-forest text-xs font-bold whitespace-nowrap"
            >
              Régler Facture
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Layout: Invoice Lines on the left, Activity on the right */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Invoice Lines */}
        <div className="lg:col-span-2 sherwood-panel p-5 space-y-4">
          {/* Header tabs */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-[#e7ddca]">
            <div className="flex items-center gap-2">
              <h3 className="font-serif-title font-black text-[#234931] text-base">Lignes de Facture</h3>
              <span className="text-xs font-bold text-[#85522b] bg-[#faeee2] px-2.5 py-0.5 rounded-full font-mono">
                {sale.items.length} réf. ({totalQuantity} unités)
              </span>
            </div>

            {/* Sub-tabs */}
            <div className="flex items-center gap-1 bg-[#f7f2e7] p-1 rounded-2xl text-xs font-bold text-[#605547] border border-[#e2d7c2]">
              <button
                type="button"
                onClick={() => setActiveTab('lines')}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                  activeTab === 'lines' ? 'bg-[#234931] text-white shadow-2xs' : 'hover:text-[#234931]'
                }`}
              >
                Articles
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('details')}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                  activeTab === 'details' ? 'bg-[#234931] text-white shadow-2xs' : 'hover:text-[#234931]'
                }`}
              >
                Détails
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('notes')}
                className={`px-3 py-1.5 rounded-xl transition-all cursor-pointer ${
                  activeTab === 'notes' ? 'bg-[#234931] text-white shadow-2xs' : 'hover:text-[#234931]'
                }`}
              >
                Notes
              </button>
            </div>
          </div>

          {/* Search & Layout toggle */}
          <div className="flex items-center justify-between gap-3">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-[#877a6b] absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Rechercher un article..."
                className="w-full pl-9 pr-3 py-2.5 sherwood-input text-xs"
              />
            </div>

            <div className="flex items-center gap-1 bg-[#f7f2e7] p-1 rounded-2xl border border-[#e2d7c2]">
              <button
                type="button"
                onClick={() => setViewMode('grid')}
                className={`p-1.5 rounded-xl transition-all cursor-pointer ${
                  viewMode === 'grid' ? 'bg-[#234931] text-white shadow-2xs' : 'text-[#877a6b]'
                }`}
                title="Vue Grille"
              >
                <LayoutGrid className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={() => setViewMode('list')}
                className={`p-1.5 rounded-xl transition-all cursor-pointer ${
                  viewMode === 'list' ? 'bg-[#234931] text-white shadow-2xs' : 'text-[#877a6b]'
                }`}
                title="Vue Liste"
              >
                <List className="w-4 h-4" />
              </button>
            </div>
          </div>

          {/* Items Container */}
          {viewMode === 'grid' ? (
            <div className="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-3">
              {filteredItems.map((item) => {
                const prod = products.find((p) => p.id === item.productId);
                return (
                  <div
                    key={item.productId}
                    className="sherwood-card p-3.5 flex flex-col justify-between"
                  >
                    <div className="flex items-start gap-3">
                      <div className="w-12 h-12 rounded-xl bg-[#f7f2e7] overflow-hidden shrink-0 border border-[#e2d7c2]">
                        {prod?.imageUrl ? (
                          <img
                            src={prod.imageUrl}
                            alt={item.productName}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-[#877a6b]">
                            <Package className="w-5 h-5" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-bold text-xs text-[#2c241c] truncate">
                          {item.productName}
                        </div>
                        <div className="text-[11px] font-black text-[#234931] font-mono mt-0.5">
                          {formatMoney(item.unitPrice)}
                        </div>
                      </div>
                    </div>

                    <div className="mt-3 pt-2.5 border-t border-[#e7ddca] flex items-center justify-between text-xs">
                      <div className="flex items-center gap-1.5">
                        <span className="font-black text-[#2c241c]">{item.quantity}</span>
                        <span className="text-[10px] text-[#877a6b]">Qté</span>
                      </div>
                      <span className="text-[10px] text-[#85522b] bg-[#faeee2] px-2 py-0.5 rounded-md font-mono font-bold">
                        {item.sku}
                      </span>
                      <button
                        type="button"
                        className="text-[#877a6b] hover:text-[#234931] p-1 cursor-pointer"
                      >
                        <MoreHorizontal className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="divide-y divide-[#e7ddca] sherwood-panel p-0 overflow-hidden">
              {filteredItems.map((item) => (
                <div
                  key={item.productId}
                  className="p-3.5 flex items-center justify-between gap-3 text-xs"
                >
                  <div>
                    <div className="font-bold text-[#2c241c]">{item.productName}</div>
                    <div className="text-[10px] text-[#877a6b] font-mono">{item.sku}</div>
                  </div>
                  <div className="text-right">
                    <div className="font-black text-[#234931] font-mono">{formatMoney(item.totalTTC)}</div>
                    <div className="text-[10px] text-[#605547]">
                      {item.quantity} x {formatMoney(item.unitPrice)}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Right Column: Activity Feed */}
        <div className="sherwood-panel p-5 space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-[#e7ddca]">
            <h3 className="font-serif-title font-black text-[#234931] text-base">Activité & Suivi</h3>
            <span className="text-xs font-bold text-[#234931] bg-[#eaf2e8] px-2.5 py-0.5 rounded-full font-mono">
              3 événements
            </span>
          </div>

          {/* Quick action buttons row */}
          <div className="flex items-center justify-between gap-1 p-1 bg-[#f7f2e7] rounded-2xl border border-[#e2d7c2]">
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-[#605547] hover:text-[#234931] transition-colors cursor-pointer"
              title="Planifier"
            >
              <Calendar className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-[#605547] hover:text-[#234931] transition-colors cursor-pointer"
              title="Appeler"
            >
              <Phone className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-[#605547] hover:text-[#234931] transition-colors cursor-pointer"
              title="Envoyer un e-mail"
            >
              <Mail className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-[#605547] hover:text-[#234931] transition-colors cursor-pointer"
              title="Ajouter une tâche"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>

          {/* Activity Cards Styled with global Sherwood palettes */}
          <div className="space-y-3 pt-2">
            <div className="p-3.5 bg-[#faeee2] border border-[#f0d4ba] rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-[#85522b] font-bold">
                <span>Rappel de paiement</span>
                <span className="text-[10px] opacity-75">Hier à 14h30</span>
              </div>
              <div className="text-xs font-bold text-[#482611]">
                Ticket envoyé au client par SMS / e-mail
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-[#85522b] font-medium">Caissier Principal</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-[#85522b]" />
              </div>
            </div>

            <div className="p-3.5 bg-[#fef3c7] border border-[#fde68a] rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-[#92400e] font-bold">
                <span>Bon de commande validé</span>
                <span className="text-[10px] opacity-75">10:00 AM</span>
              </div>
              <div className="text-xs font-bold text-[#78350f]">
                Articles réservés et décomptés du stock POS
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-[#92400e] font-medium">Poste Caisse #1</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-[#92400e]" />
              </div>
            </div>

            <div className="p-3.5 bg-[#eaf2e8] border border-[#cbe0cb] rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-[#234931] font-bold">
                <span>Synchronisation Cloud Supabase</span>
                <span className="text-[10px] opacity-75">Instantané</span>
              </div>
              <div className="text-xs font-bold text-[#14281b]">
                Réplication PostgreSQL & P2P confirmée
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-[#234931] font-medium">Réseau Local</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-[#234931]" />
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* Printable Receipt Modal */}
      {showReceiptModal && (
        <PrintableReceiptModal
          sale={sale}
          onClose={() => setShowReceiptModal(false)}
        />
      )}
    </div>
  );
};
