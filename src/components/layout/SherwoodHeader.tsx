import React, { useState, useEffect } from 'react';
import { usePos } from '../../context/PosContext';
import { useIsDesktop } from '../../hooks/useMediaQuery';
import {
  Wifi,
  WifiOff,
  ShoppingCart,
  Menu,
  Clock,
  Calendar as CalendarIcon,
} from 'lucide-react';

export const SherwoodHeader: React.FC = () => {
  const {
    isOffline,
    setIsOffline,
    pendingSyncCount,
    cartSummary,
    setIsCartDrawerOpen,
    setIsMobileMenuOpen,
    setActiveView,
  } = usePos();

  const isDesktop = useIsDesktop();
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
          weekday: 'short',
          day: 'numeric',
          month: 'short',
        })
      );
    };

    updateDateTime();
    const interval = setInterval(updateDateTime, 30000);
    return () => clearInterval(interval);
  }, []);

  return (
    <header className="sticky top-0 z-30 bg-[#fdfbf7]/90 backdrop-blur-md border-b border-[#e5dcce] px-4 sm:px-6 pb-2.5 pt-[max(0.625rem,env(safe-area-inset-top))] flex items-center justify-between gap-2 shadow-2xs">
      {/* Left: Mobile Menu Trigger + Brand / Subtitle */}
      <div className="flex items-center gap-3 min-w-0">
        <button
          type="button"
          onClick={() => setIsMobileMenuOpen(true)}
          className="lg:hidden touch-btn p-2 text-[#483d31] hover:text-[#234931] hover:bg-[#f7f2e7] rounded-xl transition-colors cursor-pointer"
          aria-label="Ouvrir le menu"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="min-w-0">
          <h1 className="text-lg sm:text-2xl truncate font-black text-[#223d2b] font-serif-title tracking-tight leading-tight flex items-center gap-2">
            <span>Caisse Sherwood</span>
          </h1>
          <p className="text-xs text-[#605547] font-medium hidden sm:block">
            Ventes et stocks en direct
          </p>
        </div>
      </div>

      {/* Right Controls: Date, Clock, Offline/Online Status, Cart */}
      <div className="flex items-center gap-1.5 sm:gap-3 shrink-0">
        {/* Date Pill */}
        {currentDate && (
          <div className="hidden md:flex items-center gap-1.5 px-3 py-1.5 bg-[#fdfbf7] border border-[#e5dcce] rounded-full text-xs font-semibold text-[#483d31] shadow-2xs">
            <CalendarIcon className="w-3.5 h-3.5 text-[#527d52]" />
            <span>{currentDate}</span>
          </div>
        )}

        {/* Live Clock Pill */}
        {currentTime && (
          <div className="flex items-center gap-1.5 px-3 py-1.5 bg-[#fdfbf7] border border-[#e5dcce] rounded-full text-xs font-mono font-bold text-[#483d31] shadow-2xs">
            <Clock className="w-3.5 h-3.5 text-[#8d5732]" />
            <span>{currentTime}</span>
          </div>
        )}

        {/* Offline / Online Sync Pill */}
        <button
          type="button"
          onClick={() => setIsOffline(!isOffline)}
          className={`touch-btn px-3 py-1.5 rounded-full text-xs font-bold flex items-center gap-1.5 border transition-all cursor-pointer shadow-2xs ${
            isOffline
              ? 'bg-[#faece1] border-[#f0c8a8] text-[#a85a18]'
              : 'bg-[#edf5ec] border-[#cce4ca] text-[#245229]'
          }`}
          title="Gestion synchronisation"
          aria-label={isOffline ? 'Hors ligne, basculer en ligne' : 'En ligne, basculer hors ligne'}
        >
          {isOffline ? (
            <>
              <WifiOff className="w-3.5 h-3.5 text-[#a85a18]" />
              <span className="hidden sm:inline">Hors ligne</span>
              {pendingSyncCount > 0 && (
                <span className="px-1.5 py-0.5 bg-[#a85a18] text-white rounded-full text-xs font-mono">
                  {pendingSyncCount}
                </span>
              )}
            </>
          ) : (
            <>
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <Wifi className="w-3.5 h-3.5 text-emerald-700" />
              <span className="hidden sm:inline">En ligne</span>
            </>
          )}
        </button>

        {/* Header Quick Cart Button */}
        <button
          type="button"
          onClick={() => {
            setActiveView('pos');
            if (!isDesktop) setIsCartDrawerOpen(true);
          }}
          className="touch-btn px-3.5 py-1.5 bg-[#85522b] hover:bg-[#6e3e1c] text-[#fff6ec] rounded-2xl text-xs font-bold flex items-center gap-2 transition-all cursor-pointer shadow-xs active:scale-95"
          title="Ouvrir le panier"
          aria-label={`Panier, ${cartSummary.totalItems} articles`}
        >
          <ShoppingCart className="w-4 h-4 text-[#fcdbb6]" />
          <span className="hidden sm:inline">Panier</span>
          <span className="px-1.5 py-0.5 bg-[#5d3112] text-[#fff2e2] rounded-full text-xs font-mono">
            {cartSummary.totalItems}
          </span>
        </button>
      </div>
    </header>
  );
};
