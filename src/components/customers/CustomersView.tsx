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
  Smile,
} from 'lucide-react';
import { SHERWOOD_ASSETS } from '../../assets/images';

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

  // Animal Crossing villager avatars matching the reference photo
  const villagerAvatars = [
    { emoji: '🦌', name: 'Fauna', bg: 'bg-[#f5e6d3]' },
    { emoji: '🦌', name: 'Beau', bg: 'bg-[#faeee2]' },
    { emoji: '🦏', name: 'Merengue', bg: 'bg-[#fde8e8]' },
    { emoji: '🐿️', name: 'Marshal', bg: 'bg-[#f4efe4]' },
    { emoji: '🐿️', name: 'Filbert', bg: 'bg-[#e0f2fe]' },
    { emoji: '🐙', name: 'Zucker', bg: 'bg-[#fef3c7]' },
    { emoji: '🦌', name: 'Erik', bg: 'bg-[#e2e8f0]' },
    { emoji: '🐰', name: 'Bunnie', bg: 'bg-[#ffedd5]' },
  ];

  // Helper function to calculate points and tier
  const getCustomerLoyalty = (cust: Customer) => {
    const custSales = sales.filter((s) => s.customerId === cust.id);
    const totalSpent = custSales.reduce((acc, s) => acc + s.totalTTC, 0);

    // 1 point per 100 DA spent + any manual bonus points
    const points = (cust.loyaltyPoints || 0) + Math.floor(totalSpent / 100);

    let tier: 'Bronze' | 'Argent' | 'Or' | 'Diamant' = 'Bronze';
    let tierColor = 'bg-[#faeee2] text-[#85522b] border-[#eddabb]';
    let nextTierThreshold = 250;
    let nextTierName = 'Argent';

    if (points >= 1500) {
      tier = 'Diamant';
      tierColor = 'bg-[#e0f2fe] text-[#0369a1] border-[#bae6fd]';
      nextTierThreshold = 3000;
      nextTierName = 'Privilège';
    } else if (points >= 750) {
      tier = 'Or';
      tierColor = 'bg-[#fef3c7] text-[#92400e] border-[#fde68a]';
      nextTierThreshold = 1500;
      nextTierName = 'Diamant';
    } else if (points >= 250) {
      tier = 'Argent';
      tierColor = 'bg-[#eaf2e8] text-[#234931] border-[#cbe0cb]';
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
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header & Loyalty Overview Banner */}
      <div className="sherwood-panel p-5 sm:p-6 flex flex-col md:flex-row md:items-center justify-between gap-5 relative overflow-hidden">
        <div>
          <div className="sherwood-badge-wood mb-2">
            <Gift className="w-3.5 h-3.5 text-[#85522b]" />
            <span>🍃 Programme Fidélité Sherwood (1 Clochette / 100 DA)</span>
          </div>
          <h2 className="text-xl sm:text-2xl font-black text-[#234931] font-serif-title tracking-tight flex items-center gap-2">
            <span>🍃</span>
            <span>Clients & fidélité</span>
          </h2>
          <p className="text-xs sm:text-sm text-[#605547] mt-1 max-w-xl font-medium">
            Suivi des comptes clients particuliers et professionnels, clochettes de fidélité et remises automatiques.
          </p>
        </div>

        <div className="flex items-center gap-3 shrink-0">
          <div className="sherwood-panel-subtle p-3 text-right">
            <div className="text-[10px] text-[#877a6b] font-bold uppercase tracking-wider">
              Total Points Distribués
            </div>
            <div className="text-lg font-black text-[#85522b] flex items-center justify-end gap-1 font-mono">
              <Star className="w-4 h-4 fill-amber-400 text-amber-500" />
              <span>{totalLoyaltyPoints.toLocaleString('fr-FR')} pts</span>
            </div>
          </div>

          <button
            type="button"
            onClick={() => setIsAddingCustomer(true)}
            className="touch-btn px-4 py-2.5 sherwood-btn-forest text-xs font-bold flex items-center gap-2 shadow-sm"
          >
            <Plus className="w-4 h-4" />
            <span>Nouveau Client 🍃</span>
          </button>
        </div>
      </div>

      {/* Filter and Search Bar */}
      <div className="sherwood-panel p-3.5 flex flex-col sm:flex-row items-stretch sm:items-center gap-3">
        <div className="relative flex-1">
          <Search className="w-4 h-4 text-[#877a6b] absolute left-3.5 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            value={searchQuery}
            onChange={(e) => setSearchQuery(e.target.value)}
            placeholder="Rechercher par nom, entreprise, téléphone..."
            className="w-full pl-10 pr-4 py-2 sherwood-input text-xs sm:text-sm"
          />
        </div>

        {/* Tier filter pills */}
        <div className="flex items-center gap-1.5 overflow-x-auto pb-1 sm:pb-0 text-xs font-bold">
          <button
            type="button"
            onClick={() => setTierFilter('ALL')}
            className={`touch-btn px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap ${
              tierFilter === 'ALL'
                ? 'bg-[#234931] text-[#fdfbf7] border-[#234931] shadow-2xs'
                : 'sherwood-btn-outline'
            }`}
          >
            Tous ({customers.length})
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('GOLD')}
            className={`touch-btn px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'GOLD'
                ? 'bg-[#85522b] text-white border-[#85522b] shadow-2xs'
                : 'sherwood-btn-outline'
            }`}
          >
            <Sparkles className="w-3.5 h-3.5 text-[#d97706]" />
            <span>Or & VIP</span>
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('SILVER')}
            className={`touch-btn px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'SILVER'
                ? 'bg-[#234931] text-white border-[#234931] shadow-2xs'
                : 'sherwood-btn-outline'
            }`}
          >
            <Award className="w-3.5 h-3.5 text-[#234931]" />
            <span>Argent</span>
          </button>
          <button
            type="button"
            onClick={() => setTierFilter('BRONZE')}
            className={`touch-btn px-3 py-1.5 rounded-xl border transition-all cursor-pointer whitespace-nowrap flex items-center gap-1 ${
              tierFilter === 'BRONZE'
                ? 'bg-[#483d31] text-white border-[#483d31] shadow-2xs'
                : 'sherwood-btn-outline'
            }`}
          >
            <ShieldCheck className="w-3.5 h-3.5 text-[#605547]" />
            <span>Bronze</span>
          </button>
        </div>
      </div>

      {/* Customers Cards Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
        {filteredCustomers.map((cust, idx) => {
          const loyalty = getCustomerLoyalty(cust);
          const avatar = villagerAvatars[idx % villagerAvatars.length];

          return (
            <div
              key={cust.id}
              className="sherwood-card p-5 transition-all flex flex-col justify-between space-y-4 hover:shadow-md"
            >
              <div>
                {/* Header info with Villager Avatar Figurine */}
                <div className="flex items-start justify-between gap-3">
                  <div className="flex items-center gap-3 min-w-0">
                    <div
                      className={`w-11 h-11 rounded-2xl ${avatar.bg} border-2 border-[#d8cdba] flex items-center justify-center text-xl shadow-inner shrink-0`}
                      title={`${avatar.name} • Résident Sherwood`}
                    >
                      {avatar.emoji}
                    </div>

                    <div className="min-w-0">
                      <h3 className="font-bold text-sm text-[#2c241c] truncate">{cust.name}</h3>
                      {cust.company ? (
                        <div className="text-xs text-[#85522b] font-semibold flex items-center gap-1 mt-0.5 truncate">
                          <Building className="w-3 h-3 shrink-0" />
                          <span className="truncate">{cust.company}</span>
                        </div>
                      ) : (
                        <div className="text-[11px] text-[#605547] mt-0.5">Particulier</div>
                      )}
                    </div>
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
                <div className="mt-3.5 sherwood-panel-subtle p-3.5 space-y-2">
                  <div className="flex items-center justify-between text-xs">
                    <span className="font-bold text-[#234931] flex items-center gap-1.5">
                      <Gift className="w-4 h-4 text-[#85522b]" />
                      Solde Fidélité
                    </span>
                    <span className="text-base font-black text-[#85522b] font-mono">
                      {loyalty.points} pts
                    </span>
                  </div>

                  {/* Progress bar to next tier */}
                  <div className="space-y-1">
                    <div className="w-full bg-[#d8cdba]/60 rounded-full h-1.5 overflow-hidden">
                      <div
                        className="bg-[#234931] h-full rounded-full transition-all duration-300"
                        style={{ width: `${loyalty.progressToNext}%` }}
                      ></div>
                    </div>
                    <div className="flex justify-between text-[10px] text-[#605547] font-medium">
                      <span>Valeur: {formatMoney(loyalty.discountValueDA)}</span>
                      <span>
                        {loyalty.points} / {loyalty.nextTierThreshold} pts ({loyalty.nextTierName})
                      </span>
                    </div>
                  </div>
                </div>

                {/* Contact info */}
                <div className="mt-3 space-y-1.5 text-xs text-[#483d31]">
                  {cust.phone && (
                    <div className="flex items-center gap-2">
                      <Phone className="w-3.5 h-3.5 text-[#877a6b] shrink-0" />
                      <span className="font-mono">{cust.phone}</span>
                    </div>
                  )}
                  {cust.email && (
                    <div className="flex items-center gap-2">
                      <Mail className="w-3.5 h-3.5 text-[#877a6b] shrink-0" />
                      <span className="truncate">{cust.email}</span>
                    </div>
                  )}
                  {cust.address && (
                    <div className="flex items-center gap-2">
                      <MapPin className="w-3.5 h-3.5 text-[#877a6b] shrink-0" />
                      <span className="truncate">{cust.address}</span>
                    </div>
                  )}
                </div>
              </div>

              {/* Card Footer: Purchase history + Action */}
              <div className="pt-3 border-t border-[#e7ddca] flex items-center justify-between gap-2">
                <div>
                  <div className="text-[10px] text-[#877a6b] font-semibold uppercase">
                    Achats Cumulés
                  </div>
                  <div className="text-xs font-black text-[#234931] font-mono">
                    {formatMoney(loyalty.totalSpent)} ({loyalty.salesCount} ventes)
                  </div>
                </div>

                <button
                  type="button"
                  onClick={() => {
                    setSelectedCustomerId(cust.id);
                    setActiveView('pos');
                  }}
                  className="touch-btn px-3 py-1.5 sherwood-btn-forest text-xs font-bold whitespace-nowrap"
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
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-black/60 backdrop-blur-xs p-4 animate-in fade-in duration-150">
          <div className="sherwood-panel w-full max-w-md p-0 overflow-hidden shadow-2xl">
            <div className="px-6 py-4 bg-[#1f3d29] text-[#fcfbf7] flex items-center justify-between border-b border-[#16311f]">
              <h3 className="font-bold text-sm flex items-center gap-2 font-serif-title">
                <Users className="w-4 h-4 text-[#a8d3a8]" />
                Nouveau Client (+50 Pts Offerts 🍃)
              </h3>
              <button
                type="button"
                onClick={() => setIsAddingCustomer(false)}
                className="touch-btn p-1 text-[#c5ddc5] hover:text-white cursor-pointer"
              >
                <X className="w-5 h-5" />
              </button>
            </div>

            <form onSubmit={handleSubmitNew} className="p-6 space-y-4">
              <div>
                <label className="block text-xs font-bold text-[#2c241c] mb-1">
                  Nom & Prénom *
                </label>
                <input
                  type="text"
                  required
                  value={name}
                  onChange={(e) => setName(e.target.value)}
                  placeholder="Ex: Samira Belkacem"
                  className="w-full px-3 py-2 text-xs sherwood-input"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-xs font-bold text-[#2c241c] mb-1">
                    Entreprise / Société
                  </label>
                  <input
                    type="text"
                    value={company}
                    onChange={(e) => setCompany(e.target.value)}
                    placeholder="Optionnel"
                    className="w-full px-3 py-2 text-xs sherwood-input"
                  />
                </div>
                <div>
                  <label className="block text-xs font-bold text-[#2c241c] mb-1">
                    Téléphone
                  </label>
                  <input
                    type="text"
                    value={phone}
                    onChange={(e) => setPhone(e.target.value)}
                    placeholder="0550 12 34 56"
                    className="w-full px-3 py-2 text-xs sherwood-input font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-xs font-bold text-[#2c241c] mb-1">
                  Email
                </label>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="contact@exemple.com"
                  className="w-full px-3 py-2 text-xs sherwood-input"
                />
              </div>

              <div>
                <label className="block text-xs font-bold text-[#2c241c] mb-1">
                  Adresse de livraison / Facturation
                </label>
                <input
                  type="text"
                  value={address}
                  onChange={(e) => setAddress(e.target.value)}
                  placeholder="Ex: 12 Rue Didouche Mourad, Alger"
                  className="w-full px-3 py-2 text-xs sherwood-input"
                />
              </div>

              <div className="pt-2 flex items-center justify-end gap-2 border-t border-[#e7ddca]">
                <button
                  type="button"
                  onClick={() => setIsAddingCustomer(false)}
                  className="touch-btn px-4 py-2 sherwood-btn-outline text-xs font-bold"
                >
                  Annuler
                </button>
                <button
                  type="submit"
                  className="touch-btn px-5 py-2 sherwood-btn-forest text-xs font-bold flex items-center gap-1.5"
                >
                  <Check className="w-4 h-4" />
                  <span>Créer le Compte Client</span>
                </button>
              </div>
            </form>
          </div>
        </div>
      )}
    </div>
  );
};
