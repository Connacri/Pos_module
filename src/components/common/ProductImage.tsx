import React, { useState } from 'react';
import {
  CupSoda,
  Utensils,
  Sparkles,
  Smartphone,
  Croissant,
  Home,
  Package,
} from 'lucide-react';

interface ProductImageProps {
  src?: string;
  alt: string;
  categoryId?: number;
  categoryName?: string;
  className?: string;
  imgClassName?: string;
}

const CATEGORY_STYLES: Record<
  number,
  { bg: string; text: string; border: string; icon: React.FC<{ className?: string }> }
> = {
  1: {
    bg: 'bg-blue-50 text-blue-700',
    text: 'text-blue-800',
    border: 'border-blue-200',
    icon: CupSoda,
  },
  2: {
    bg: 'bg-emerald-50 text-emerald-700',
    text: 'text-emerald-800',
    border: 'border-emerald-200',
    icon: Utensils,
  },
  3: {
    bg: 'bg-pink-50 text-pink-700',
    text: 'text-pink-800',
    border: 'border-pink-200',
    icon: Sparkles,
  },
  4: {
    bg: 'bg-purple-50 text-purple-700',
    text: 'text-purple-800',
    border: 'border-purple-200',
    icon: Smartphone,
  },
  5: {
    bg: 'bg-amber-50 text-amber-700',
    text: 'text-amber-800',
    border: 'border-amber-200',
    icon: Croissant,
  },
  6: {
    bg: 'bg-cyan-50 text-cyan-700',
    text: 'text-cyan-800',
    border: 'border-cyan-200',
    icon: Home,
  },
};

export const ProductImage: React.FC<ProductImageProps> = ({
  src,
  alt,
  categoryId = 0,
  categoryName,
  className = 'w-full h-full',
  imgClassName = 'w-full h-full object-cover',
}) => {
  const [hasError, setHasError] = useState(false);
  const [isLoaded, setIsLoaded] = useState(false);

  const style = CATEGORY_STYLES[categoryId] || {
    bg: 'bg-[#f4efe4] text-[#85522b]',
    text: 'text-[#482611]',
    border: 'border-[#e2d7c2]',
    icon: Package,
  };

  const IconComponent = style.icon;

  if (!src || hasError) {
    return (
      <div
        className={`${className} ${style.bg} flex flex-col items-center justify-center p-2 text-center select-none border ${style.border}`}
        aria-hidden="true"
      >
        <div className="p-2 rounded-xl bg-white/70 shadow-2xs mb-1">
          <IconComponent className="w-5 h-5 sm:w-6 sm:h-6" />
        </div>
        {categoryName && (
          <span className={`text-[10px] font-bold ${style.text} truncate max-w-full px-1`}>
            {categoryName}
          </span>
        )}
      </div>
    );
  }

  return (
    <div className={`relative overflow-hidden ${className}`}>
      {!isLoaded && (
        <div className="absolute inset-0 bg-sand-200/60 animate-pulse flex items-center justify-center">
          <IconComponent className="w-5 h-5 text-sand-300" />
        </div>
      )}
      <img
        src={src}
        alt={alt}
        loading="lazy"
        onLoad={() => setIsLoaded(true)}
        onError={() => setHasError(true)}
        className={`${imgClassName} transition-all duration-300 ${
          isLoaded ? 'opacity-100' : 'opacity-0'
        }`}
      />
    </div>
  );
};
