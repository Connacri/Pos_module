import React, { useState, useMemo } from 'react';
import { usePos } from '../../context/PosContext';
import { Customer } from '../../types';
import {
  Users,
  Search,
  Plus,
  Phone,
  Mail,
  MapPin,
  Building,
  CreditCard,
  X,
  Check,
  Award,
  Sparkles,
  Gift,
  Star,
  ShieldCheck,
  ArrowRight,
} from 'lucide-react';

export const CustomersView: React.FC = () => {
  const { customers, addCustomer, sales, setSelectedCustomerId, setActiveView } = usePos();
  const [searchQuery, setSearchQuery] = useState('');
  const [tierFilter, setTierFilter] = useState<'ALL' | 'GOLD' | 'SILVER' | 'BRONZE'>('ALL');
  const [isAddingCustomer, setIsAddingCustomer] = useState(false);

  // New customer form state
  const [name, setName] = useState('');
  const [company, setCompany] = useState('');
  const [phone, setPhone] = useState('');
  const [email, setEmail] = useState('');
  const [address, setAddress] = useState('');
  const [taxId, setTaxId] = useState('');
  const [notes, setNotes] = useState('');

  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Helper function to calculate points and tier
  const getCustomerLoyalty = (cust: Customer) => {
    const custSales = sales.filter((s) => s.customerId === cust.id);
    const totalSpent = custSales.reduce((acc, s) => acc + s.totalTTC, 0);

    // 1 point per 100 DA spent + any manual bonus points
    const points = (cust.loyaltyPoints || 0) + Math.floor(totalSpent / 100);

    let tier: 'Bronze' | 'Argent' | 'Or' | 'Diamant' = 'Bronze';
    let tierColor = 'bg-amber-100 text-amber-800 border-amber-300';
    let nextTierThreshold = 250;
    let nextTierName = 'Argent';

    if (points >= 1500) {
      tier = 'Diamant';
      tierColor = 'bg-cyan-100 text-cyan-800 border-cyan-300';
      nextTierThreshold = 3000;
      nextTierName = 'Privilège';
    } else if (points >= 750) {
      tier = 'Or';
      tierColor = 'bg-yellow-100 text-yellow-800 border-yellow-300';
      nextTierThreshold = 1500;
      nextTierName = 'Diamant';
    } else if (points >= 250) {
      tier = 'Argent';
      tierColor = 'bg-slate-200 text-slate-800 border-slate-300';
      nextTierThreshold = 750;
      nextTierName = 'Or';
    }

    const progressToNext = Math.min(100, Math.round((points / nextTierThreshold) * 100));

    return {
      points,
      totalSpent,
      salesCount: custSales.length,
      tier,
      tierColor,
      nextTierThreshold,
      nextTierName,
      progressToNext,
      discountValueDA: points, // 1 point = 1 DA remise
    };
  };

  // Filter customers
  const filteredCustomers = useMemo(() => {
    return customers.filter((c) => {
      const q = searchQuery.toLowerCase().trim();
      const matchesSearch =
        !q ||
        c.name.toLowerCase().includes(q) ||
        (c.company && c.company.toLowerCase().includes(q)) ||
        (c.phone && c.phone.includes(q));

      if (!matchesSearch) return false;

      const loyalty = getCustomerLoyalty(c);
      if (tierFilter === 'GOLD') return loyalty.tier === 'Or' || loyalty.tier === 'Diamant';
      if (tierFilter === 'SILVER') return loyalty.tier === 'Argent';
      if (tierFilter === 'BRONZE') return loyalty.tier === 'Bronze';
      return true;
    });
  }, [customers, sales, searchQuery, tierFilter]);

  // Total loyalty points in store
  const totalLoyaltyPoints = useMemo(() => {
    return customers.reduce((sum, c) => sum + getCustomerLoyalty(c).points, 0);
  }, [customers, sales]);

  const handleSubmitNew = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name.trim()) return;

    addCustomer({
      name: name.trim(),
      company: company.trim() || undefined,
      phone: phone.trim() || undefined,
      email: email.trim() || undefined,
      address: address.trim() || undefined,
      taxId: taxId.trim() || undefined,
      notes: notes.trim() || undefined,
      loyaltyPoints: 50, // 50 welcome bonus points
    });

    setIsAddingCustomer(false);
    setName('');
    setCompany('');
    setPhone('');
    setEmail('');
    setAddress('');
    setTaxId('');
    setNotes('');
  };

  return (
    <div className="space-y-6">
      {/* Header & Loyalty Overview Banner */}
      <div className="sherwood-card p-6 flex flex-col md:flex-row md:items-center justify-between gap-4">
        <div>
          <div className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-[#fbf4e8] border border-[#eddabb] text-[#70481f] text-xs font-bold mb-2">
            <Gift className="w-3.5 h-3.5 text-[#8d5732]" />
            <span>🍃 Programme de Fidélité Sherwood (1 Clochette / 100 DA)</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-[#233d2a] font-serif-title tracking-tight flex items-center gap-2">
            <span>🍃</span>
            <span>Invånare • Clients & Fidélité de l'Île</span>
          </h2>
          <p className="text-xs text-[#6e6354] mt-1 max-w-xl">
            Suivi des comptes villageois et professionnels, clochettes de fidélité et remises automatiques.
          </p>
        </div>

        <div className="flex items-center gap-3">
          <div className="bg-[#f7f2e7] border border-[#e5dcce] rounded-2xl p-3 text-right">
            <div className="text-[10px] text-[#6e6354] font-bold uppercase tracking-wider">
              Total Points Distribués
            </div>
            <div className="text-lg font-black text-[#8d5732] flex items-center justify-end gap-1">
              <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
              <span>{totalLoyaltyPoints.toLocaleString('fr-FR')} pts</span>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setIsAddingCustomer(true)}
            className="touch-btn px-4 py-2.5 bg-[#2d563a] hover:bg-[#23442e] text-[#fdfbf7] rounded-2xl text-xs font-bold flex items-center gap-2 shadow-xs transition-colors cursor-pointer border border-[#21402b]"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Client 🍃</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="sherwood-card p-3.5 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-slate-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher par nom, entreprise, téléphone..."
            className="w-full pl-10 pr-4 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs sm:text-sm focus:outline-hidden"
          />
        </div>

        {/* Tier filter pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 text-xs font-semibold">
          <button
            type="button"
            onClick={() => setTierFilter('ALL')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap ${
              tierFilter === 'ALL'
                ? 'bg-slate-900 text-white border-slate-900 shadow-2xs'
                : 'bg-white text-slate-600 border-slate-200 hover:bg-slate-50'
            }`}
          >
            Tous les clients ({customers.length})
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('GOLD')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'GOLD'
                ? 'bg-yellow-500 text-white border-yellow-500 shadow-2xs'
                : 'bg-white text-yellow-700 border-yellow-200 hover:bg-yellow-50'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5" />
            Palier Or & VIP
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('SILVER')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'SILVER'
                ? 'bg-slate-700 text-white border-slate-700 shadow-2xs'
                : 'bg-white text-slate-700 border-slate-200 hover:bg-slate-50'
            }`}
          >
            <Award className="w-3.5 h-3.5" />
            Palier Argent
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('BRONZE')}
            className={`px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'BRONZE'
                ? 'bg-amber-700 text-white border-amber-700 shadow-2xs'
                : 'bg-white text-amber-800 border-amber-200 hover:bg-amber-50'
            }`}
          >
            <ShieldCheck className="w-3.5 h-3.5" />
            Palier Bronze
          </button>
        </div>
      </div>

      {/* Customers Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-4">
        {filteredCustomers.map((cust) => {
          const loyalty = getCustomerLoyalty(cust);

          return (
            <div
              key={cust.id}
              className="bg-white/90 backdrop-blur-xl rounded-3xl p-5 border border-white shadow-xs hover:shadow-md transition-all flex flex-col justify-between space-y-4 relative overflow-hidden"
            >
              <div>
                {/* Header info */}
                <div className="flex items-start justify-between gap-2">
                  <div className="flex-1 min-w-0">
                    <h3 className="font-bold text-sm text-slate-900 truncate">{cust.name}</h3>
                    {cust.company ? (
                      <div className="text-xs text-indigo-600 font-semibold flex items-center gap-1 mt-0.5 truncate">
                        <Building className="w-3.5 h-3.5 shrink-0" />
                        <span className="truncate">{cust.company}</span>
                      </div>
                    ) : (
                      <div className="text-[11px] text-slate-400 mt-0.5">Particulier</div>
                    )}
                  </div>

                  {/* Loyalty Tier Badge */}
                  <span
                    className={`text-[10px] font-black uppercase px-2.5 py-1 rounded-full border shadow-2xs shrink-0 flex items-center gap-1 ${loyalty.tierColor}`}
                  >
                    <Star className="w-3 h-3 fill-current" />
                    {loyalty.tier}
                  </span>
                </div>

                {/* Loyalty Points Card Box */}
                <div className="mt-3.5 bg-gradient-to-r from-amber-50 to-orange-50 border border-amber-200/80 rounded-2xl p-3.5 space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-amber-950 flex items-center gap-1.5">
                      <Gift className="w-4 h-4 text-amber-600" />
                      Solde Fidélité
                    </span>
                    <span className="text-base font-black text-amber-700 font-mono">
                      {loyalty.points} pts
                    </span>
                  </div>

                  {/* Progress bar to next tier */}
                  <div className="space-y-1">
                    <div className="w-full bg-amber-200/60 rounded-full h-1.5 overflow-hidden">
                      <div
                        className="bg-amber-600 h-full rounded-full transition-all duration-300"
                        style={{ width: `${loyalty.progressToNext}%` }}
                      ></div>
                    </div>
                    <div className="flex justify-between text-[10px] text-amber-800/80 font-medium">
                      <span>Valeur: {formatMoney(loyalty.discountValueDA)}</span>
                      <span>
                        {loyalty.points} / {loyalty.nextTierThreshold} pts ({loyalty.nextTierName})
                      </span>
                    </div>
                  </div>
                </div>

                {/* Contact info */}
                <div className="mt-3 space-y-1.5 text-xs text-slate-600">
                  {cust.phone && (
                    <div className="flex items-center gap-2">
                      <Phone className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span>{cust.phone}</span>
                    </div>
                  )}
                  {cust.email && (
                    <div className="flex items-center gap-2">
                      <Mail className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="truncate">{cust.email}</span>
                    </div>
                  )}
                  {cust.address && (
                    <div className="flex items-center gap-2">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span className="truncate">{cust.address}</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Card Footer: Purchase history + Action */}
              <div className="pt-3 border-t border-slate-100 flex items-center justify-between gap-2">
                <div>
                  <div className="text-[10px] text-slate-400 font-semibold uppercase">
                    Achats Cumulés
                  </div>
                  <div className="text-xs font-black text-slate-900">
                    {formatMoney(loyalty.totalSpent)} ({loyalty.salesCount} ventes)
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => {
                    setSelectedCustomerId(cust.id);
                    setActiveView('pos');
                  }}
                  className="touch-btn px-3 py-1.5 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold cursor-pointer transition-colors whitespace-nowrap"
                >
                  Ouvrir Caisse
                </button>
              </div>
            </div>
          );
        })}
      </div>

      {/* Add Customer Modal */}
      {isAddingCustomer && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/50 backdrop-blur-xs p-4">
          <div className="bg-white w-full max-w-md rounded-3xl shadow-2xl border border-slate-200 overflow-hidden animate-in fade-in zoom-in-95 duration-150">
            <div className="px-6 py-4 bg-slate-900 text-white flex items-center justify-between">
              <h3 className="font-bold text-sm flex items-center gap-2">
                <Users className="w-4 h-4 text-indigo-400" />
                Nouveau Client (+50 Pts Offerts)
              </h3>
              <button
                type="button"
                onClick={() => setIsAddingCustomer(false)}
                className="touch-btn p-1 text-slate-400 hover:text-white"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmitNew} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Nom & Prénom *
                </label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Ex: Ahmed Bouzid"
                  className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Entreprise (Optionnel)
                  </label>
                  <input
                    type="text"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                    placeholder="SARL..."
                    className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    NIF / Fiscal
                  </label>
                  <input
                    type="text"
                    value={taxId}
                    onChange={(e) => setTaxId(e.target.value)}
                    placeholder="0019..."
                    className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
                  />
                </div>
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    Téléphone
                  </label>
                  <input
                    type="tel"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="0550..."
                    className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
                  />
                </div>
                <div>
                  <label className="block text-xs font-semibold text-slate-700 mb-1">
                    E-mail
                  </label>
                  <input
                    type="email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    placeholder="contact@..."
                    className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-semibold text-slate-700 mb-1">
                  Adresse
                </label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Ville, Wilaya..."
                  className="w-full px-3 py-2 border border-slate-200 rounded-xl text-sm"
                />
              </div>

              <div className="p-3 bg-amber-50 border border-amber-200 rounded-2xl flex items-center gap-2 text-xs text-amber-900 font-semibold">
                <Gift className="w-4 h-4 text-amber-600 shrink-0" />
                <span>50 points de fidélité de bienvenue crédités à l'inscription.</span>
              </div>

              <div className="pt-3 border-t border-slate-100 flex items-center justify-end gap-3">
                <button
                  type="button"
                  onClick={() => setIsAddingCustomer(false)}
                  className="touch-btn px-4 py-2 text-xs font-semibold text-slate-600"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="touch-btn px-5 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-bold rounded-xl shadow-xs"
                >
                  Enregistrer
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
