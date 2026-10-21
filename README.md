# 🍃 POS Module Pro — Caisse Enregistreuse & Facturation Sherwood

Système de Point de Vente (POS), gestion des stocks, facturation et synchronisation cloud multi-postes conçu pour une utilisation intensive en magasin ou restaurant.

---

## 🛠 Stack Technique Réelle

- **Frontend** : React 19, TypeScript 5.7, Vite 6
- **Styling** : Tailwind CSS v4 avec tokens de design dédiés (Thème Sherwood artisan / bois & vert forêt)
- **Base locale & Moteur hors-ligne** : IndexedDB (avec indexation mémoire sub-milliseconde O(1) pour les lecteurs code-barres USB/Bluetooth et support de charges massives)
- **Visualisations & Graphiques** : D3.js (courbes vectorielles des tendances 7 jours) et Recharts (analyse des recettes)
- **Impression** : Ticket thermique 80 mm ESC/POS & facturation A4 via CSS `@media print`
- **Cloud & Synchronisation** : Supabase PostgreSQL (file d'attente d'émissions hors-ligne avec résolution de conflits bidirectionnelle)
- **Langue** : Interface en français

---

## ✨ Fonctionnalités Clés

### 1. Caisse Enregistreuse (POS)
- **Scan code-barres ultra-rapide** : Prise en charge des lecteurs code-barres USB, Bluetooth HID et caméras embarquées, avec affichage de la latence de traitement (sub-milliseconde).
- **Raccourcis clavier caisse** :
  - `F1` : Focus immédiat sur la recherche d'articles
  - `F2` : Déclenchement de la fenêtre d'encaissement
  - `Échap` : Fermeture sécurisée des modales et fenêtres (ne vide jamais le panier par accident)
- **Vidage panier sécurisé** : Procédure en 2 temps (bouton "Confirmer ?" pendant 4 s) avec bannière d'annulation immédiate (*Undo*).
- **Suggestions de billets réelles** : Montant exact, 500 DA, 1 000 DA, 2 000 DA arrondis au supérieur (adapté aux billets en circulation en Algérie).
- **Gestion des seuils de stock** : Alerte immédiate dès l'ajout au panier si un produit passe sous son seuil d'alerte.

### 2. Tableau de Bord (Dashboard)
- **Chiffres réels et traçables** : 100 % des statistiques (Chiffre d'affaires du jour, nombre de tickets, panier moyen, alertes de stock) sont calculées à partir des ventes effectives et du stock actuel.
- **Top 5 produits** et **Top 5 clients** calculés dynamiquement sans données fictives.
- **Répartition des ventes par rayon** sur les 50 dernières transactions.
- **Courbe D3.js** de l'évolution sur 7 jours.

### 3. Catalogue Produits & Gestion de Stock
- Fiches articles complètes (nom, SKU, code-barres EAN-13, catégorie, prix HT, TVA, prix TTC, seuil d'alerte).
- Scanner code-barres caméra via webcam / smartphone (`html5-qrcode`).
- Outil de benchmark intégré pour tester l'écriture de 1 000 à 10 000 articles dans IndexedDB.

### 4. Factures & Historique des Ventes
- Registre complet des ventes avec statut (`COMPLETED`, `CANCELLED`).
- Réimpression immédiate au format ticket 80 mm thermique ou facture grand format.

### 5. Administration & Synchronisation Supabase
- Configuration du endpoint cloud Supabase et de la clé anonyme.
- File d'attente hors-ligne automatique (stockage local avec vidage dès rétablissement de la connectivité).
- Script SQL complet fourni (`supabase/schema.sql`) pour instancier les tables PostgreSQL et les règles de sécurité RLS.

---

## 🚀 Démarrage Rapide

### Prérequis
- Node.js 20+ ou 22
- npm

### Installation & Lancement

```bash
# Installation des dépendances
npm install

# Démarrage du serveur de développement (Port 3000)
npm run dev

# Vérification des types et linting
npm run lint

# Build de production
npm run build
```

---

## ♿ Accessibilité (a11y) & Ergonomie

- Tailles de cible tactile d'au moins **44 × 44 px** (`.touch-btn`) pour les actions fréquentes (quantités `+`/`-`, corbeille, remises, catégories).
- Textes et contrastes vérifiés (minimum 12 px sur l'ensemble de l'interface de caisse).
- Annonces dynamiques via `role="status"`, `aria-live="polite"` et `role="alert"` pour les retours de scan et avertissements de stock.
- Focus visible et navigable au clavier (`:focus-visible` vert forêt avec anneau d'accent).
- Prise en charge des zones sûres mobiles (`viewport-fit=cover` et `env(safe-area-inset-bottom)`).

---

## 📄 Licence
Ce projet est distribué sous licence MIT.
