import React, { useEffect } from 'react';
import { usePos } from '../../context/PosContext';
import { CartPanel } from './CartPanel';

/**
 * Tiroir panier mobile (Sheet). Rendu dans AppLayout pour fonctionner depuis toutes les vues
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
      className="fixed inset-0 z-50 lg:hidden bg-ink-900/60 backdrop-blur-xs flex flex-col justify-end transition-opacity duration-200"
      onClick={() => setIsCartDrawerOpen(false)}
      role="presentation"
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label="Panier de caisse mobile"
        onClick={(e) => e.stopPropagation()}
        className="relative bg-sand-50 rounded-t-3xl max-h-[92vh] h-[88vh] shadow-2xl flex flex-col min-h-0 overflow-hidden animate-in slide-in-from-bottom duration-250 border-t-2 border-forest-800/30"
      >
        <CartPanel isDrawer onClose={() => setIsCartDrawerOpen(false)} />
      </div>
    </div>
  );
};

export default CartDrawer;
