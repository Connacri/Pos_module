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
  const { customers, products, completeSale } = usePos();
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

  // Financial breakdown calculation inspired by the reference image
  const totalAmount = sale.totalTTC;
  const isPaid = sale.status === 'COMPLETED';
  const paidAmount = isPaid ? totalAmount : 0;
  const creditAmount = Math.round(totalAmount * 0.15); // demo credit
  const balanceDue = Math.max(0, totalAmount - paidAmount);

  return (
    <div className="space-y-6 animate-in fade-in duration-200">
      {/* Top Bar Navigation */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 bg-white/70 backdrop-blur-md p-4 rounded-3xl border border-white/80 shadow-xs">
        <div className="flex items-center gap-3">
          <button
            type="button"
            onClick={onBack}
            className="touch-btn p-2 bg-white hover:bg-slate-100 text-slate-700 rounded-2xl border border-slate-200 shadow-2xs transition-colors flex items-center justify-center cursor-pointer"
            aria-label="Retour"
          >
            <ArrowLeft className="w-4 h-4" />
          </button>
          <div>
            <span className="text-xs text-slate-400 font-semibold uppercase tracking-wider">
              Facturation
            </span>
            <h2 className="text-base sm:text-lg font-extrabold text-slate-900 leading-tight">
              Facture {sale.saleNumber}
            </h2>
          </div>
        </div>

        {/* Action buttons (responsive wrap) */}
        <div className="flex items-center gap-2 flex-wrap">
          <button
            type="button"
            onClick={() => setShowReceiptModal(true)}
            className="touch-btn px-3 py-2 bg-indigo-50 hover:bg-indigo-100 text-indigo-700 border border-indigo-200 text-xs font-semibold rounded-2xl flex items-center gap-1.5 shadow-2xs transition-all cursor-pointer"
          >
            <Printer className="w-3.5 h-3.5" />
            <span>Imprimer Ticket</span>
          </button>
          <button
            type="button"
            className="touch-btn px-3 py-2 bg-white hover:bg-slate-50 text-slate-700 border border-slate-200 text-xs font-semibold rounded-2xl flex items-center gap-1.5 shadow-2xs transition-all cursor-pointer"
          >
            <CreditCard className="w-3.5 h-3.5 text-indigo-600" />
            <span>Avoir / Crédit</span>
          </button>
          <button
            type="button"
            className="touch-btn px-3 py-2 bg-slate-900 hover:bg-slate-800 text-white text-xs font-semibold rounded-2xl flex items-center gap-1.5 shadow-md transition-all cursor-pointer"
          >
            <Edit className="w-3.5 h-3.5" />
            <span>Modifier</span>
          </button>
        </div>
      </div>

      {/* Hero Financial Banner - faithfully styled after reference image */}
      <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-6 border border-white shadow-sm space-y-6">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-6">
          {/* Big Amount */}
          <div className="flex items-baseline gap-2">
            <span className="text-2xl sm:text-3xl font-extrabold text-slate-400">DA</span>
            <span className="text-3xl sm:text-5xl font-black text-slate-900 tracking-tight">
              {new Intl.NumberFormat('fr-DZ', { maximumFractionDigits: 2 }).format(totalAmount)}
            </span>
          </div>

          {/* Metadata chips */}
          <div className="grid grid-cols-2 sm:grid-cols-3 gap-3 text-xs">
            <div className="bg-slate-50/80 p-3 rounded-2xl border border-slate-100">
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Client</span>
              <span className="font-bold text-slate-800 truncate block">
                {sale.customerName || 'Client Comptoir'}
              </span>
            </div>
            <div className="bg-slate-50/80 p-3 rounded-2xl border border-slate-100">
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Réf. Facture</span>
              <span className="font-mono font-bold text-slate-800 block">
                {sale.saleNumber}
              </span>
            </div>
            <div className="bg-slate-50/80 p-3 rounded-2xl border border-slate-100 col-span-2 sm:col-span-1">
              <span className="text-[10px] text-slate-400 uppercase font-semibold block">Statut</span>
              <span className="inline-flex items-center gap-1 font-bold text-emerald-600">
                <CheckCircle2 className="w-3 h-3" />
                Payée • Validée
              </span>
            </div>
          </div>
        </div>

        {/* Progress Bar / Pill indicators from reference image */}
        <div className="flex flex-col md:flex-row items-stretch md:items-center gap-3 pt-2">
          <div className="flex-1 flex flex-wrap sm:flex-nowrap items-center gap-2">
            {/* Paid Pill */}
            <div className="flex-1 min-w-[130px] bg-emerald-100 text-emerald-800 px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-2xs">
              <CheckCircle2 className="w-4 h-4 text-emerald-600" />
              <span>Payé {formatMoney(paidAmount)}</span>
            </div>

            {/* Credit Pill */}
            <div className="flex-1 min-w-[120px] bg-amber-100 text-amber-800 px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2 shadow-2xs">
              <CreditCard className="w-4 h-4 text-amber-600" />
              <span>Crédit {formatMoney(creditAmount)}</span>
            </div>

            {/* Balance Pill */}
            <div className="flex-1 min-w-[120px] bg-slate-100 border border-dashed border-slate-300 text-slate-700 px-3.5 py-2 rounded-2xl text-xs font-bold flex items-center gap-2">
              <DollarSign className="w-4 h-4 text-slate-400" />
              <span>Solde {formatMoney(balanceDue)}</span>
            </div>
          </div>

          {/* Pay Button / Outstanding Pill */}
          <div className="flex items-center gap-2 justify-end">
            <span className="text-xs text-slate-500 font-medium px-2 py-1 bg-slate-100 rounded-xl">
              Délai: <strong className="text-slate-800">Comptant</strong>
            </span>
            <button
              type="button"
              className="touch-btn px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-2xl text-xs font-bold shadow-md transition-all cursor-pointer whitespace-nowrap"
            >
              Régler Facture
            </button>
          </div>
        </div>
      </div>

      {/* Main Content Layout: Invoice Lines on the left, Activity on the right */}
      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Left Column: Invoice Lines */}
        <div className="lg:col-span-2 bg-white/80 backdrop-blur-xl rounded-3xl p-5 border border-white shadow-xs space-y-4">
          {/* Header tabs */}
          <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 pb-3 border-b border-slate-100">
            <div className="flex items-center gap-2">
              <h3 className="font-extrabold text-slate-900 text-base">Lignes de Facture</h3>
              <span className="text-xs font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">
                {sale.items.length} réf. ({totalQuantity} unités)
              </span>
            </div>

            {/* Sub-tabs */}
            <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-2xl text-xs font-semibold text-slate-600">
              <button
                type="button"
                onClick={() => setActiveTab('lines')}
                className={`px-3 py-1.5 rounded-xl transition-all ${
                  activeTab === 'lines' ? 'bg-white text-slate-900 shadow-2xs font-bold' : ''
                }`}
              >
                Articles
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('details')}
                className={`px-3 py-1.5 rounded-xl transition-all ${
                  activeTab === 'details' ? 'bg-white text-slate-900 shadow-2xs font-bold' : ''
                }`}
              >
                Détails
              </button>
              <button
                type="button"
                onClick={() => setActiveTab('notes')}
                className={`px-3 py-1.5 rounded-xl transition-all ${
                  activeTab === 'notes' ? 'bg-white text-slate-900 shadow-2xs font-bold' : ''
                }`}
              >
                Notes
              </button>
            </div>
          </div>

          {/* Search & Layout toggle */}
          <div className="flex items-center justify-between gap-3">
            <div className="relative flex-1">
              <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={searchQuery}
                onChange={(e) => setSearchQuery(e.target.value)}
                placeholder="Rechercher un article..."
                className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-2xl text-xs focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20"
              />
            </div>

            <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-2xl">
              <button
                type="button"
                onClick={() => setViewMode('grid')}
                className={`p-1.5 rounded-xl transition-all ${
                  viewMode === 'grid' ? 'bg-white text-slate-900 shadow-2xs' : 'text-slate-500'
                }`}
                title="Vue Grille"
              >
                <LayoutGrid className="w-4 h-4" />
              </button>
              <button
                type="button"
                onClick={() => setViewMode('list')}
                className={`p-1.5 rounded-xl transition-all ${
                  viewMode === 'list' ? 'bg-white text-slate-900 shadow-2xs' : 'text-slate-500'
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
                    className="bg-white p-3.5 rounded-2xl border border-slate-200/80 shadow-2xs hover:shadow-xs transition-shadow flex flex-col justify-between"
                  >
                    <div className="flex items-start gap-3">
                      <div className="w-12 h-12 rounded-xl bg-slate-100 overflow-hidden shrink-0">
                        {prod?.imageUrl ? (
                          <img
                            src={prod.imageUrl}
                            alt={item.productName}
                            className="w-full h-full object-cover"
                          />
                        ) : (
                          <div className="w-full h-full flex items-center justify-center text-slate-400">
                            <Package className="w-5 h-5" />
                          </div>
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="font-bold text-xs text-slate-900 truncate">
                          {item.productName}
                        </div>
                        <div className="text-[11px] font-extrabold text-slate-700 mt-0.5">
                          {formatMoney(item.unitPrice)}
                        </div>
                      </div>
                    </div>

                    <div className="mt-3 pt-2.5 border-t border-slate-100 flex items-center justify-between text-xs">
                      <div className="flex items-center gap-1.5">
                        <span className="font-black text-slate-900">{item.quantity}</span>
                        <span className="text-[10px] text-slate-400">Qté</span>
                      </div>
                      <span className="text-[10px] text-slate-400 bg-slate-50 px-2 py-0.5 rounded-md">
                        {item.sku}
                      </span>
                      <button
                        type="button"
                        className="text-slate-400 hover:text-slate-700 p-1"
                      >
                        <MoreHorizontal className="w-4 h-4" />
                      </button>
                    </div>
                  </div>
                );
              })}
            </div>
          ) : (
            <div className="divide-y divide-slate-100 bg-white rounded-2xl border border-slate-200/80 overflow-hidden">
              {filteredItems.map((item) => (
                <div
                  key={item.productId}
                  className="p-3 flex items-center justify-between gap-3 text-xs"
                >
                  <div>
                    <div className="font-bold text-slate-900">{item.productName}</div>
                    <div className="text-[10px] text-slate-400 font-mono">{item.sku}</div>
                  </div>
                  <div className="text-right">
                    <div className="font-bold text-slate-900">{formatMoney(item.totalTTC)}</div>
                    <div className="text-[10px] text-slate-500">
                      {item.quantity} x {formatMoney(item.unitPrice)}
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Right Column: Activity Feed from reference image */}
        <div className="bg-white/80 backdrop-blur-xl rounded-3xl p-5 border border-white shadow-xs space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-100">
            <h3 className="font-extrabold text-slate-900 text-base">Activité & Suivi</h3>
            <span className="text-xs font-bold text-slate-400 bg-slate-100 px-2 py-0.5 rounded-full">
              4 actions
            </span>
          </div>

          {/* Quick action buttons row from reference image */}
          <div className="flex items-center justify-between gap-1 p-1 bg-slate-100 rounded-2xl">
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-slate-600 transition-colors cursor-pointer"
              title="Planifier"
            >
              <Calendar className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-slate-600 transition-colors cursor-pointer"
              title="Appeler"
            >
              <Phone className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-slate-600 transition-colors cursor-pointer"
              title="Envoyer un e-mail"
            >
              <Mail className="w-4 h-4" />
            </button>
            <button
              type="button"
              className="touch-btn p-2 hover:bg-white rounded-xl text-slate-600 transition-colors cursor-pointer"
              title="Ajouter une tâche"
            >
              <Plus className="w-4 h-4" />
            </button>
          </div>

          {/* Activity Cards Styled like the reference image */}
          <div className="space-y-3 pt-2">
            {/* Lavender Activity Card */}
            <div className="p-3.5 bg-purple-100/70 border border-purple-200/60 rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-purple-700 font-bold">
                <span>Rappel de paiement</span>
                <span className="text-[10px] opacity-75">Hier à 14h30</span>
              </div>
              <div className="text-xs font-semibold text-purple-950">
                Ticket envoyé au client par SMS / e-mail
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-purple-600 font-medium">Caissier Principal</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-purple-600" />
              </div>
            </div>

            {/* Lemon Yellow Activity Card */}
            <div className="p-3.5 bg-amber-100/70 border border-amber-200/60 rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-amber-800 font-bold">
                <span>Bon de commande validé</span>
                <span className="text-[10px] opacity-75">10:00 AM</span>
              </div>
              <div className="text-xs font-semibold text-amber-950">
                Articles réservés et décomptés du stock ObjectBox
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-amber-700 font-medium">Poste Caisse #1</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-amber-700" />
              </div>
            </div>

            {/* Mint Activity Card */}
            <div className="p-3.5 bg-emerald-100/70 border border-emerald-200/60 rounded-2xl space-y-1.5">
              <div className="flex items-center justify-between text-[11px] text-emerald-800 font-bold">
                <span>Synchronisation locale P2P</span>
                <span className="text-[10px] opacity-75">Instantané</span>
              </div>
              <div className="text-xs font-semibold text-emerald-950">
                Réplication Freebox Sync confirmée sur les postes satellites
              </div>
              <div className="flex items-center justify-between pt-1">
                <span className="text-[10px] text-emerald-700 font-medium">Réseau Local</span>
                <ArrowUpRight className="w-3.5 h-3.5 text-emerald-700" />
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
