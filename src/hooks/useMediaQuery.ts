import { useEffect, useState } from 'react';

/** Abonnement à une media query (remplace les écouteurs 'resize' + window.innerWidth). */
export function useMediaQuery(query: string): boolean {
  const get = () => (typeof window !== 'undefined' ? window.matchMedia(query).matches : false);
  const [matches, setMatches] = useState(get);

  useEffect(() => {
    const mql = window.matchMedia(query);
    const onChange = () => setMatches(mql.matches);
    onChange();
    mql.addEventListener('change', onChange);
    return () => mql.removeEventListener('change', onChange);
  }, [query]);

  return matches;
}

/** Breakpoint Tailwind `lg` : bureau / grande tablette paysage. */
export const useIsDesktop = () => useMediaQuery('(min-width: 1024px)');
