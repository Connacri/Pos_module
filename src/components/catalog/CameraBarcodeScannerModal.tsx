import React, { useState, useEffect, useRef } from 'react';
import { Html5Qrcode, Html5QrcodeSupportedFormats } from 'html5-qrcode';
import { Product } from '../../types';
import { usePos } from '../../context/PosContext';
import { posSounds } from '../../services/soundService';
import {
  Camera,
  X,
  Barcode,
  Search,
  ShoppingCart,
  Check,
  AlertTriangle,
  XCircle,
  RefreshCw,
  Sparkles,
  Zap,
  ArrowRight,
  Upload,
} from 'lucide-react';

interface CameraBarcodeScannerModalProps {
  isOpen: boolean;
  onClose: () => void;
  onSelectProduct: (product: Product) => void;
}

export const CameraBarcodeScannerModal: React.FC<CameraBarcodeScannerModalProps> = ({
  isOpen,
  onClose,
  onSelectProduct,
}) => {
  const { products, addToCart } = usePos();

  const [isScanning, setIsScanning] = useState(false);
  const [cameraError, setCameraError] = useState<string | null>(null);
  const [scannedCode, setScannedCode] = useState<string | null>(null);
  const [matchedProduct, setMatchedProduct] = useState<Product | null>(null);
  const [manualInput, setManualInput] = useState('');
  const [inCartQuantity, setInCartQuantity] = useState(0);
  const [torchOn, setTorchOn] = useState(false);

  const scannerRef = useRef<Html5Qrcode | null>(null);
  const containerId = 'interactive-barcode-scanner-viewport';
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Format money helper
  const formatMoney = (val: number) => {
    return new Intl.NumberFormat('fr-DZ', {
      maximumFractionDigits: 0,
    }).format(val) + ' DA';
  };

  // Process decoded code
  const handleDecodedCode = (code: string) => {
    if (!code) return;
    const clean = code.trim();
    setScannedCode(clean);

    // Find product matching barcode or SKU
    const product = products.find(
      (p) => p.barcode === clean || p.sku.toLowerCase() === clean.toLowerCase()
    );

    if (product) {
      posSounds.playScanSuccess();
      setMatchedProduct(product);
      setInCartQuantity(0);
    } else {
      posSounds.playScanError();
      setMatchedProduct(null);
    }
  };

  // Initialize and start camera
  useEffect(() => {
    if (!isOpen) {
      // Cleanup when closed
      if (scannerRef.current && scannerRef.current.isScanning) {
        scannerRef.current.stop().catch(() => {}).finally(() => {
          scannerRef.current?.clear();
          scannerRef.current = null;
        });
      }
      return;
    }

    setScannedCode(null);
    setMatchedProduct(null);
    setCameraError(null);

    // Timeout to ensure DOM container is mounted
    const timer = setTimeout(() => {
      const container = document.getElementById(containerId);
      if (!container) return;

      try {
        const html5QrCode = new Html5Qrcode(containerId, {
          formatsToSupport: [
            Html5QrcodeSupportedFormats.EAN_13,
            Html5QrcodeSupportedFormats.EAN_8,
            Html5QrcodeSupportedFormats.CODE_128,
            Html5QrcodeSupportedFormats.CODE_39,
            Html5QrcodeSupportedFormats.UPC_A,
            Html5QrcodeSupportedFormats.UPC_E,
            Html5QrcodeSupportedFormats.QR_CODE,
          ],
          verbose: false,
        });

        scannerRef.current = html5QrCode;

        html5QrCode
          .start(
            { facingMode: 'environment' },
            {
              fps: 15,
              qrbox: { width: 280, height: 160 },
              aspectRatio: 1.333333,
            },
            (decodedText) => {
              handleDecodedCode(decodedText);
            },
            () => {
              // frame scanning heartbeat (silent)
            }
          )
          .then(() => {
            setIsScanning(true);
            setCameraError(null);
          })
          .catch((err) => {
            console.warn('Camera start error:', err);
            setIsScanning(false);
            setCameraError(
              err.message ||
                "Accès caméra indisponible ou refusé par le navigateur. Vous pouvez utiliser le simulateur de scan ou téléverser une photo d'étiquette."
            );
          });
      } catch (err: any) {
        console.warn('Scanner init error:', err);
        setCameraError(
          "Impossible d'initialiser le capteur vidéo. Utilisez les codes de démonstration ci-dessous."
        );
      }
    }, 150);

    return () => {
      clearTimeout(timer);
      if (scannerRef.current && scannerRef.current.isScanning) {
        scannerRef.current
          .stop()
          .catch(() => {})
          .finally(() => {
            scannerRef.current?.clear();
            scannerRef.current = null;
          });
      }
    };
  }, [isOpen]);

  // Handle image upload scan
  const handleImageFileScan = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;

    try {
      const scanner = scannerRef.current || new Html5Qrcode(containerId);
      const result = await scanner.scanFile(file, true);
      handleDecodedCode(result);
    } catch (err: any) {
      posSounds.playScanError();
      alert("Aucun code-barres n'a pu être décodé dans cette image.");
    }
  };

  const handleManualSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!manualInput.trim()) return;
    handleDecodedCode(manualInput.trim());
    setManualInput('');
  };

  const handleAddToCart = (product: Product) => {
    addToCart(product, 1);
    setInCartQuantity((prev) => prev + 1);
  };

  if (!isOpen) return null;

  return (
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-950/75 backdrop-blur-sm p-3 sm:p-4 overflow-y-auto animate-in fade-in duration-200">
      <div className="bg-white w-full max-w-lg rounded-3xl shadow-2xl border border-slate-200 overflow-hidden flex flex-col max-h-[94vh]">
        {/* Top Header */}
        <div className="px-5 py-4 bg-slate-900 text-white flex items-center justify-between shrink-0">
          <div className="flex items-center gap-2.5">
            <div className="p-2 bg-indigo-600 rounded-xl shadow-xs">
              <Camera className="w-5 h-5 text-white" />
            </div>
            <div>
              <h3 className="font-bold text-sm sm:text-base">
                Scanner Caméra & Recherche Code-barres
              </h3>
              <p className="text-[11px] text-slate-400">
                Pointez la caméra vers l'étiquette physique EAN-13 / UPC de l'article
              </p>
            </div>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="touch-btn p-1.5 text-slate-400 hover:text-white transition-colors cursor-pointer rounded-xl hover:bg-slate-800"
            aria-label="Fermer"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Modal Body */}
        <div className="p-4 sm:p-5 overflow-y-auto space-y-4">
          {/* Camera Viewport Container with Reticle */}
          <div className="relative bg-slate-900 rounded-2xl overflow-hidden aspect-4/3 flex flex-col items-center justify-center shadow-inner border border-slate-800">
            {/* HTML5 QR/Barcode Video Mount */}
            <div
              id={containerId}
              className="w-full h-full object-cover [&>video]:w-full [&>video]:h-full [&>video]:object-cover"
            />

            {/* Target Reticle Overlay (Active when scanning) */}
            {!cameraError && (
              <div className="absolute inset-0 pointer-events-none flex flex-col items-center justify-center p-6">
                <div className="relative w-64 h-36 border-2 border-dashed border-indigo-400/90 rounded-2xl bg-indigo-950/10 shadow-2xl flex items-center justify-center">
                  {/* Corner brackets */}
                  <span className="absolute -top-1 -left-1 w-5 h-5 border-t-4 border-l-4 border-indigo-400 rounded-tl-lg"></span>
                  <span className="absolute -top-1 -right-1 w-5 h-5 border-t-4 border-r-4 border-indigo-400 rounded-tr-lg"></span>
                  <span className="absolute -bottom-1 -left-1 w-5 h-5 border-b-4 border-l-4 border-indigo-400 rounded-bl-lg"></span>
                  <span className="absolute -bottom-1 -right-1 w-5 h-5 border-b-4 border-r-4 border-indigo-400 rounded-br-lg"></span>

                  {/* Red Laser Sweep line */}
                  <div className="w-full h-0.5 bg-gradient-to-r from-transparent via-rose-500 to-transparent shadow-[0_0_8px_#f43f5e] animate-pulse"></div>
                </div>

                <div className="mt-3 bg-slate-900/80 backdrop-blur-xs text-white text-[11px] font-medium px-3 py-1 rounded-full shadow-md flex items-center gap-1.5">
                  <span className="w-2 h-2 rounded-full bg-emerald-400 animate-ping"></span>
                  <span>Alignez le code-barres dans le cadre</span>
                </div>
              </div>
            )}

            {/* Camera Error / Permission Fallback View */}
            {cameraError && (
              <div className="absolute inset-0 bg-slate-900/95 p-5 flex flex-col items-center justify-center text-center text-white space-y-3 z-10">
                <div className="w-12 h-12 rounded-2xl bg-amber-500/20 text-amber-400 flex items-center justify-center border border-amber-500/30">
                  <AlertTriangle className="w-6 h-6" />
                </div>
                <div className="space-y-1 max-w-sm">
                  <h4 className="font-bold text-sm text-slate-100">
                    Flux Caméra Non Disponible
                  </h4>
                  <p className="text-xs text-slate-400 leading-relaxed">
                    {cameraError}
                  </p>
                </div>

                <div className="flex items-center gap-2 pt-1">
                  <button
                    type="button"
                    onClick={() => {
                      setCameraError(null);
                      // Trigger scan restart
                      const container = document.getElementById(containerId);
                      if (container) {
                        const html5QrCode = new Html5Qrcode(containerId);
                        scannerRef.current = html5QrCode;
                        html5QrCode
                          .start(
                            { facingMode: 'environment' },
                            { fps: 15, qrbox: { width: 280, height: 160 } },
                            handleDecodedCode,
                            () => {}
                          )
                          .catch((e) => setCameraError(e.message));
                      }
                    }}
                    className="px-3 py-1.5 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <RefreshCw className="w-3.5 h-3.5" />
                    Réessayer la caméra
                  </button>

                  <button
                    type="button"
                    onClick={() => fileInputRef.current?.click()}
                    className="px-3 py-1.5 bg-slate-800 hover:bg-slate-700 text-slate-200 border border-slate-700 rounded-xl text-xs font-semibold flex items-center gap-1.5 transition-colors cursor-pointer"
                  >
                    <Upload className="w-3.5 h-3.5" />
                    Scanner une photo
                  </button>
                  <input
                    ref={fileInputRef}
                    type="file"
                    accept="image/*"
                    className="hidden"
                    onChange={handleImageFileScan}
                  />
                </div>
              </div>
            )}
          </div>

          {/* Quick Simulation Chips (Essential for instant testing) */}
          <div className="bg-slate-50 p-3 rounded-2xl border border-slate-200 space-y-2">
            <div className="flex items-center justify-between text-xs">
              <span className="font-bold text-slate-700 flex items-center gap-1.5">
                <Sparkles className="w-3.5 h-3.5 text-amber-500" />
                Simulateur de Scan Rapide (Échantillons) :
              </span>
              <span className="text-[10px] text-slate-400">Clic direct</span>
            </div>

            <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 text-xs">
              <button
                type="button"
                onClick={() => handleDecodedCode('613000000001')}
                className="p-2 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 rounded-xl text-left transition-colors cursor-pointer"
              >
                <div className="font-bold text-slate-800 truncate">Coca-Cola</div>
                <div className="text-[10px] font-mono text-slate-400">613000000001</div>
              </button>
              <button
                type="button"
                onClick={() => handleDecodedCode('613000000004')}
                className="p-2 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 rounded-xl text-left transition-colors cursor-pointer"
              >
                <div className="font-bold text-slate-800 truncate">Huile d'Olive</div>
                <div className="text-[10px] font-mono text-slate-400">613000000004</div>
              </button>
              <button
                type="button"
                onClick={() => handleDecodedCode('613000000012')}
                className="p-2 bg-white hover:bg-indigo-50 border border-slate-200 hover:border-indigo-300 rounded-xl text-left transition-colors cursor-pointer"
              >
                <div className="font-bold text-slate-800 truncate">Écouteurs BT</div>
                <div className="text-[10px] font-mono text-slate-400">613000000012</div>
              </button>
              <button
                type="button"
                onClick={() => handleDecodedCode('613000000013')}
                className="p-2 bg-white hover:bg-rose-50 border border-slate-200 hover:border-rose-300 rounded-xl text-left transition-colors cursor-pointer"
              >
                <div className="font-bold text-rose-800 truncate">Pain (Rupture)</div>
                <div className="text-[10px] font-mono text-rose-400">613000000013</div>
              </button>
            </div>
          </div>

          {/* Manual Barcode / SKU Input Form */}
          <form onSubmit={handleManualSubmit} className="flex items-center gap-2">
            <div className="relative flex-1">
              <Barcode className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                value={manualInput}
                onChange={(e) => setManualInput(e.target.value)}
                placeholder="Ou tapez un code-barres / SKU manuellement..."
                className="w-full pl-9 pr-3 py-2 bg-slate-50 border border-slate-200 rounded-xl text-xs font-mono placeholder:font-sans text-slate-800 focus:outline-hidden focus:ring-2 focus:ring-indigo-500/20"
              />
            </div>
            <button
              type="submit"
              className="touch-btn px-4 py-2 bg-slate-900 hover:bg-slate-800 text-white rounded-xl text-xs font-bold transition-colors cursor-pointer"
            >
              Rechercher
            </button>
          </form>

          {/* Scanned Result Card */}
          {scannedCode && (
            <div className="border border-slate-200 rounded-2xl p-4 bg-slate-50 space-y-3 animate-in zoom-in-95 duration-150">
              <div className="flex items-center justify-between text-xs pb-2 border-b border-slate-200">
                <span className="font-semibold text-slate-500">
                  Dernier code détecté : <strong className="font-mono text-slate-900">{scannedCode}</strong>
                </span>
                {matchedProduct ? (
                  <span className="bg-emerald-100 text-emerald-800 font-bold px-2 py-0.5 rounded-full text-[10px] flex items-center gap-1">
                    <Check className="w-3 h-3" />
                    Article Trouvé
                  </span>
                ) : (
                  <span className="bg-rose-100 text-rose-800 font-bold px-2 py-0.5 rounded-full text-[10px] flex items-center gap-1">
                    <XCircle className="w-3 h-3" />
                    Introuvable
                  </span>
                )}
              </div>

              {matchedProduct ? (
                <div className="space-y-3">
                  <div className="flex items-center gap-3 bg-white p-3 rounded-xl border border-slate-200/80 shadow-2xs">
                    {/* Image / Thumbnail */}
                    <div className="w-16 h-16 rounded-xl bg-slate-100 overflow-hidden shrink-0 flex items-center justify-center border border-slate-200">
                      {matchedProduct.imageUrl ? (
                        <img
                          src={matchedProduct.imageUrl}
                          alt={matchedProduct.name}
                          className="w-full h-full object-cover"
                        />
                      ) : (
                        <Barcode className="w-8 h-8 text-slate-300" />
                      )}
                    </div>

                    {/* Details */}
                    <div className="flex-1 min-w-0">
                      <h4 className="font-extrabold text-sm text-slate-900 truncate">
                        {matchedProduct.name}
                      </h4>
                      <div className="text-[11px] text-slate-500 font-mono flex items-center gap-2 mt-0.5">
                        <span>{matchedProduct.sku}</span>
                        <span>•</span>
                        <span className="font-bold text-indigo-700">
                          {formatMoney(matchedProduct.price)}
                        </span>
                      </div>

                      {/* Stock threshold tag */}
                      <div className="mt-1">
                        {matchedProduct.stock <= 0 ? (
                          <span className="inline-flex items-center gap-1 text-[10px] font-black text-rose-600 bg-rose-50 px-2 py-0.5 rounded-md">
                            <XCircle className="w-3 h-3" />
                            Rupture de Stock (0 unité)
                          </span>
                        ) : matchedProduct.stock <= matchedProduct.lowStockThreshold ? (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold text-amber-800 bg-amber-100 px-2 py-0.5 rounded-md">
                            <AlertTriangle className="w-3 h-3 text-amber-600" />
                            Alerte seuil : {matchedProduct.stock} restant(s) (min {matchedProduct.lowStockThreshold})
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[10px] font-medium text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-md">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-500"></span>
                            Stock disponible : {matchedProduct.stock} unités
                          </span>
                        )}
                      </div>
                    </div>
                  </div>

                  {/* Actions for found product */}
                  <div className="flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => handleAddToCart(matchedProduct)}
                      disabled={matchedProduct.stock <= 0}
                      className={`flex-1 py-2.5 px-3 rounded-xl text-xs font-bold flex items-center justify-center gap-1.5 shadow-xs transition-all cursor-pointer ${
                        matchedProduct.stock <= 0
                          ? 'bg-slate-200 text-slate-400 cursor-not-allowed'
                          : 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-emerald-600/20 active:scale-98'
                      }`}
                    >
                      <ShoppingCart className="w-4 h-4" />
                      <span>
                        Ajouter au Panier {inCartQuantity > 0 ? `(x${inCartQuantity})` : ''}
                      </span>
                    </button>

                    <button
                      type="button"
                      onClick={() => {
                        onSelectProduct(matchedProduct);
                        onClose();
                      }}
                      className="py-2.5 px-4 bg-indigo-600 hover:bg-indigo-700 text-white rounded-xl text-xs font-bold transition-all shadow-xs flex items-center gap-1.5 cursor-pointer"
                    >
                      <span>Voir fiche</span>
                      <ArrowRight className="w-3.5 h-3.5" />
                    </button>
                  </div>
                </div>
              ) : (
                <div className="p-3 bg-rose-50 text-rose-800 border border-rose-200 rounded-xl text-xs">
                  <div className="font-bold flex items-center gap-1.5">
                    <XCircle className="w-4 h-4 text-rose-600 shrink-0" />
                    Aucun article correspondant à "{scannedCode}"
                  </div>
                  <p className="text-[11px] text-rose-700 mt-1">
                    Vérifiez le code ou créez un nouveau produit avec ce code-barres.
                  </p>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="p-4 bg-slate-50 border-t border-slate-200 flex items-center justify-between gap-3 shrink-0">
          <div className="text-[11px] text-slate-500 flex items-center gap-1">
            <Zap className="w-3.5 h-3.5 text-indigo-600" />
            <span>Détection instantanée EAN-13, EAN-8, UPC et QR</span>
          </div>
          <button
            type="button"
            onClick={onClose}
            className="touch-btn px-4 py-2 bg-white hover:bg-slate-100 text-slate-700 border border-slate-300 rounded-xl text-xs font-semibold transition-colors cursor-pointer"
          >
            Fermer
          </button>
        </div>
      </div>
    </div>
  );
};
