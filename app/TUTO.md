# Guide utilisateur — Pos Module

Application de point de vente (caisse - POS) pour gérer : les **ventes**, l'**inventaire**, la
**facturation**, et les **retours** de produits. Cette app fonctionne **hors ligne** (les données
sont stockées localement) et se **synchronise** automatiquement avec Supabase quand la connexion
est rétablie.

> Ce guide décrit toutes les fenêtres, leurs options et l'expérience utilisateur (UX) de chaque écran.
> Utilisez l'**Appbar / la barre de navigation** du bas (mobile) ou **latérale** (desktop/tablette) pour
> passer d'une section à l'autre.

---

## Résumé visuel de la navigation

| Icône              | Section      | Rôle |
|--------------------|--------------|------|
| 🏠 Accueil         | Tableau de bord | Statistiques & raccourcis |
| 🛒 Caisse (POS)    | Encaisser une vente | |
| 📦 Inventaire      | Gérer les produits | |
| 🧾 Facturation     | Factures + historique des ventes | |
| ⚙️ Réglages        | Thème, langue, stockage | |
| ↺ **Retours**      | Accessible depuis l'Accueil | Retourner des articles |

> **Retours** n'apparaît **pas** dans la barre de navigation : on y accède via la **carte
> « Retours »** de l'Accueil, ou depuis le **détail d'une vente** (Facturation → Ventes).

---

## 1. Accueil (Tableau de bord)

C'est la première fenêtre visible. Elle donne une vue d'ensemble en temps réel :

- **Indicateurs clés (KPI)** : Chiffre d'affaires du jour, Ventes du jour, Panier moyen, Créances clients.
- **Graphique du CA** des 7 derniers jours (barres : toucher une barre pour le détail).
- **Ventes par catégorie** (couronne) et **Top produits** (par quantité vendue).
- **Métriques secondaires** : nombre de produits, valeur du stock, ruptures de stock, clients.
- **Carte de synchronisation** :
  - ◆ point **vert** = en ligne, ◆ point **rouge** = hors ligne.
  - Bouton **« Synchroniser »** pour forcer la synchronisation des données avec Supabase.
- **Cartes de raccourci** : Accéder rapidement à **Caisse**, **Inventaire**, **Facturation**,
  **Retours** et **Réglages**.

---

## 2. Caisse (POS) — encaisser une vente

1. Ajouter des produits au panier (recherche, scan code-barres, sélection).
2. Ajuster les **quantités**.
3. Finaliser : choisir la **méthode de paiement** (Espèces, Carte, Mobile Money, Virement, Crédit).
4. Valider → la vente est enregistrée (**statut « Terminée »**) et le **stock diminue** automatiquement.

---

## 3. Inventaire — gérer les produits

- **Liste des produits** avec recherche.
- **Ajouter / modifier un produit** : nom, SKU, prix, TVA, stock, code-barres.
- La **carte « Valeur du stock »** et les **ruptures** sont visibles sur l'Accueil.

---

## 4. Facturation

Deux onglets :

### 4.1 Onglet « Factures »
- Liste des **factures** avec recherche (numéro, client, statut).
- **Résumé** : Total, En attente, Retards.
- **Créer une facture** (bouton « + ») : à partir d'une vente existante.
- **Ouvrir une facture** (toucher la carte) pour voir le **détail** :
  - émetteur, client, articles, totaux, échéance,
  - **QR de paiement rapide**,
  - menu (⋮) : **Marquer payée / émise / Supprimer**,
  - bouton « **Imprimer** » (impression à venir).

### 4.2 Onglet « Ventes »
- Liste de **toutes les ventes** (numéro, client, date, statut, mode de paiement, montant).
- **NEW — toucher une carte de vente** pour ouvrir sa **page de détail** :

---

## 5. NEW — Détail d'une vente

En **Facturation → Ventes**, touchez n'importe quelle vente.

La page affiche :
- **Statut** de la vente (Terminée / En attente / Annulée / Retournée) et sa **date**.
- **Client**, **méthode de paiement**, **nombre d'articles**, n° de **caissier**.
- La **liste des articles** : nom, prix × quantité, TVA, sous-total ligne.
- **Totaux** : sous-total, taxe, remise, **TOTAL**.

Et surtout un bouton action selon le statut :

- ✅ Vente **Terminée** → bouton **« Faire un retour »** (bleu/rouge) qui ouvre l'écran de retour.
- ↺ Vente **Retournée** → message « Cette vente a été entièrement retournée. »
- ⛔ Autre statut → message « Cette vente n'est pas retournable. »

> Le bouton « Faire un retour » n'apparaît **que** pour une vente **Terminée** et non-retournée.

---

## 6. Retour d'un produit — TOTAL ou PARTIEL

La fonctionnalité de retour gère **deux cas** : le retour **total** (tous les articles) et le
retour **partiel** (seulement certains articles et/ou quantités). Voici les **deux chemins**
pour démarrer un retour :

### Chemin A — Depuis le Détail d'une vente (recommandé)
1. **Facturation** → **Ventes**.
2. Touchez la vente concernée.
3. Touchez **« Faire un retour »**.

### Chemin B — Depuis la liste des Retours
1. **Accueil** → carte **« Retours »**.
2. Touchez le bouton **« Nouveau retour »** (flottant, en bas à droite).
3. Dans la fenêtre **« Choisir la vente »**, sélectionnez la vente encaissée à retourner.

### Écran « Retour de #N »
Une fois la vente choisie :

- Vous voyez la liste des articles **encore retournables** (la quantité déjà retournée est déduite).
- Pour **chaque article**, un compteur **− / valeur / +** :
  - **Laissez à 0** pour ne pas retourner cet article (retour partiel).
  - **Augmentez jusqu'au max disponible** (bouton + grisé au max).
- Le **« Remboursement »** se recalcule en direct (montant + nombre d'articles sélectionnés).
- Renseignez le **Motif (optionnel)** : « produit défectueux », « erreur de commande », etc.
- Touchez **« Valider le retour »**.

### Effets d'un retour
- ✅ **Stock restauré automatiquement** (les quantités retournées sont réajoutées).
- 💰 Le **remboursement** est calculé et la **remise globale** de la vente est répartie
  proportionnellement sur les articles retournés.
- ♻️ Si **tous** les articles sont retournés → la vente passe au statut **« Retournée »**.
  Sinon (retour partiel) → la vente reste **« Terminée »** et les quantités restantes restent retournables.
- Le retour est enregistré dans la liste **« Retours »** de l'Accueil.

---

## 7. Réglages

Accessible via l'icône ⚙️ et via la carte « Réglages » de l'Accueil :

- **Thème** : Clair / Sombre / Système.
- **Langue** : Français (FR), Anglais (EN), Espagnol (ES), Arabe (AR).
- **Stockage & fichiers** : upload d'**image** ou de **CSV** vers Supabase (et copie de l'URL),
  **Exporter les produits** en CSV.
- **Version** de l'application affichée.

---

## 8. Synchronisation (en ligne / hors ligne)

- L'application fonctionne **sans connexion** : les données sont enregistrées en local.
- Dès qu'une connexion est disponible, les données se **synchronisent** avec Supabase.
- La carte en haut de l'**Accueil** indique l'**état** (vert en ligne / rouge hors ligne)
  et le moment de la **dernière synchronisation**. On peut **Forcer** la synchro avec le
  bouton **« Synchroniser »**.

---

## 9. Responsive (multi-écrans)

- **Mobile** : barre de navigation **en bas**.
- **Tablette / Desktop (≥ 900px)** : navigation **latérale (rail)** + affichage en 2 colonnes
  sur l'Accueil pour les graphiques.

---

## FAQ — Retours

**Q: Puis-je retourner seulement une partie d'une commande ?**
R: Oui. Mettez à 0 (ou à la quantité partielle) les articles que vous ne retournez pas.

**Q: Pourquoi la vente n'a pas de bouton « Faire un retour » ?**
R: Le bouton n'apparaît que pour les ventes **Terminées** et **non entièrement retournées**.

**Q: Le stock se remet-il à jour ?**
R: Oui, automatiquement, dès la validation du retour.

**Q: Puis-je retourner un article déjà entièrement retourné ?**
R: Non. Les quantités déjà retournées sont **déduites** ; seules les quantités restantes sont retournables.