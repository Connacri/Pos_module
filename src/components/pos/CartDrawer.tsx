import React, { useEffect } from 'react';
import { X } from 'lucide-react';
import { usePos } from '../../context/PosContext';
import { CartPanel } from './CartPanel';

/**
 * Tiroir panier mobile. Rendu dans AppLayout pour fonctionner depuis toutes les vues
 * (le bouton Panier de la barre du bas et du header est visible partout).
 */
export const CartDrawer: React.FC = () => {
  const { isCartDrawerOpen, setIsCartDrawerOpen, isCheckoutOpen, isPrintPreviewOpen } = usePos();

  useEffect(() => {
    if (!isCartDrawerOpen) return;
    const onKeyDown = (e: KeyboardEvent) => {
      // Les modales d'encaissement ont leur propre gestion d'Échap
      if (e.key === 'Escape' && !isCheckoutOpen && !isPrintPreviewOpen) {
        setIsCartDrawerOpen(false);
      }
    };
    window.addEventListener('keydown', onKeyDown);
    return () => window.removeEventListener('keydown', onKeyDown);
  }, [isCartDrawerOpen, isCheckoutOpen, isPrintPreviewOpen, setIsCartDrawerOpen]);

  if (!isCartDrawerOpen) return null;

  return (
    <div
      className="fixed inset-0 z-50 lg:hidden bg-ink-900/50 backdrop-blur-xs flex flex-col justify-end"
      onClick={() => setIsCartDrawerOpen(false)}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Panier de vente"
        onClick={(e) => e.stopPropagation()}
        className="relative bg-sand-50 rounded-t-3xl max-h-[92vh] h-[85vh] shadow-2xl flex flex-col overflow-hidden animate-in slide-in-from-bottom duration-200"
      >
        <div className="p-3 bg-sand-100 border-b border-sand-200 flex items-center justify-center">
          <span className="w-10 h-1 bg-sand-300 rounded-full block" aria-hidden="true" />
          <button
            type="button"
            onClick={() => setIsCartDrawerOpen(false)}
            aria-label="Fermer le panier"
            className="touch-btn inline-flex items-center justify-center text-ink-600 hover:text-ink-900 absolute right-2 top-0 cursor-pointer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>
        <div className="flex-1 overflow-hidden">
          <CartPanel />
        </div>
      </div>
    </div>
  );
};
