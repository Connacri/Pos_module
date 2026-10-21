import React, { useState, useEffect } from 'react';
import { usePos } from '../../context/PosContext';
import {
  Calendar as CalendarIcon,
  Clock,
  ShoppingCart,
  Wifi,
  WifiOff,
  Menu,
  X,
  Sparkles,
} from 'lucide-react';

export const SherwoodHeader: React.FC = () => {
  const {
    cartSummary,
    isCartDrawerOpen,
    setIsCartDrawerOpen,
    isOffline,
    pendingSyncCount,
    setActiveView,
    isMobileMenuOpen,
    setIsMobileMenuOpen,
  } = usePos();

  const [currentTime, setCurrentTime] = useState<string>('');
  const [currentDate, setCurrentDate] = useState<string>('');

  useEffect(() => {
    const updateDateTime = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString('fr-FR', {
          hour: '2-digit',
          minute: '2-digit',
        })
      );
      setCurrentDate(
        now.toLocaleDateString('fr-FR', {
          day: 'numeric',
          month: 'short',
          year: 'numeric',
        })
      );
    };

    updateDateTime();
    const interval = setInterval(updateDateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="px-4 sm:px-8 py-3.5 bg-[#f4efe4] border-b border-[#e5dcce] flex flex-wrap items-center justify-between gap-4 sticky top-0 z-30">
      {/* Left: Greeting & Welcome Banner matching Sherwood image */}
      <div className="flex items-center gap-3">
        {/* Mobile Hamburger toggle */}
        <button
          type="button"
          onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
          className="lg:hidden touch-btn p-2 bg-[#fdfbf7] border border-[#e5dcce] text-[#2c4b35] rounded-xl flex items-center justify-center cursor-pointer shadow-xs"
          aria-label="Menu"
        >
          {isMobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
        </button>

        <div className="flex items-start gap-2.5">
          <div className="w-9 h-9 rounded-2xl bg-[#234931] text-[#e8f1e8] flex items-center justify-center text-lg shadow-sm shrink-0 mt-0.5">
            🍃
          </div>
          <div>
            <h1 className="text-xl sm:text-2xl font-black text-[#223d2b] font-serif-title tracking-tight leading-tight flex items-center gap-2">
              <span>Välkommen tillbaka !</span>
            </h1>
            <p className="text-xs text-[#605547] font-medium hidden sm:block">
              Här är en översikt av din ö Sherwood 🌲 • Caisse & stocks en direct
            </p>
          </div>
        </div>
      </div>

      {/* Right: Date, Season, Time, Cashier Profile, Cart & Sync */}
      <div className="flex items-center gap-2 sm:gap-3 flex-wrap ml-auto">
        {/* Date Pill */}
        <div className="hidden md:flex items-center gap-1.5 px-3 py-1.5 bg-[#fdfbf7] border border-[#e5dcce] rounded-full text-xs font-semibold text-[#483d31] shadow-2xs">
          <CalendarIcon className="w-3.5 h-3.5 text-[#527d52]" />
          <span>{currentDate || '20 oct. 2026'}</span>
        </div>

        {/* Season / Status Badge */}
        <div className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 bg-[#eaf2e8] border border-[#cbe0cb] rounded-full text-xs font-bold text-[#234931]">
          <span>🍃</span>
          <span>Automne • Caisse Active</span>
        </div>

        {/* Live Clock Pill */}
        <div className="flex items-center gap-1.5 px-3 py-1.5 bg-[#fdfbf7] border border-[#e5dcce] rounded-full text-xs font-mono font-bold text-[#483d31] shadow-2xs">
          <Clock className="w-3.5 h-3.5 text-[#8d5732]" />
          <span>{currentTime || '12:00'}</span>
        </div>

        {/* Offline / Online Sync Pill */}
        <button
          type="button"
          onClick={() => setActiveView('admin')}
          className={`touch-btn px-2.5 py-1.5 rounded-full border text-xs font-bold flex items-center gap-1.5 transition-all cursor-pointer ${
            isOffline
              ? 'bg-[#fef4ea] border-[#f5cf9e] text-[#8f521b]'
              : 'bg-[#edf5ec] border-[#cce4ca] text-[#245229]'
          }`}
          title="Gestion synchronisation"
        >
          {isOffline ? (
            <>
              <WifiOff className="w-3.5 h-3.5 text-[#a85a18]" />
              <span className="hidden xl:inline">Hors-Ligne</span>
              {pendingSyncCount > 0 && (
                <span className="px-1.5 py-0.2 bg-[#a85a18] text-white rounded-full text-[10px]">
                  {pendingSyncCount}
                </span>
              )}
            </>
          ) : (
            <>
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <Wifi className="w-3.5 h-3.5 text-emerald-700" />
              <span className="hidden xl:inline">En Ligne</span>
            </>
          )}
        </button>

        {/* Quick Cart Pill in Warm Wood Brown */}
        <button
          type="button"
          onClick={() => {
            if (window.innerWidth < 1024) {
              setIsCartDrawerOpen(!isCartDrawerOpen);
            } else {
              setActiveView('pos');
            }
          }}
          className="touch-btn px-3.5 py-1.5 bg-[#8d5732] hover:bg-[#784624] text-[#fff6ec] rounded-full font-bold text-xs shadow-md shadow-[#61381c]/20 flex items-center gap-2 transition-transform active:scale-95 cursor-pointer border border-[#6d3e1d]"
        >
          <ShoppingCart className="w-4 h-4 text-[#fcdbb6]" />
          <span className="hidden sm:inline">Panier</span>
          <span className="px-1.5 py-0.2 bg-[#5d3112] text-[#fff2e2] rounded-full text-[11px] font-mono">
            {cartSummary.totalItems}
          </span>
        </button>

        {/* Cashier Profile Badge with Robin Hood / Villager Green Cap */}
        <div className="flex items-center gap-2 pl-1 sm:pl-2">
          <div className="w-9 h-9 sm:w-10 sm:h-10 rounded-full bg-[#f4ebd9] border-2 border-[#547f54] p-0.5 shadow-sm flex items-center justify-center text-xl overflow-hidden cursor-pointer hover:rotate-6 transition-transform" title="Caissier Robin • Sherwood">
            🧝
          </div>
        </div>
      </div>
    </header>
  );
};
