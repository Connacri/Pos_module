# POS Module Pro — Caisse, Stock & Facturation

Application de point de vente (POS) **web et Android**, conçue pour un usage intensif en magasin, restaurant ou commerce de détail : encaissement rapide, gestion de stock, facturation, impression thermique et synchronisation Supabase.

<p>

🌐 **[Live Web](https://connacri.github.io/Pos_module/)** ·
⬇️ **[Télécharger l'APK](https://github.com/Connacri/Pos_module/releases/latest)** ·
📦 **[Toutes les releases](https://github.com/Connacri/Pos_module/releases)**

</p>

---

## Stack technique

| Couche | Technologie |
| --- | --- |
| UI | React 19, TypeScript 5.7, Tailwind CSS 4 (`@theme`) |
| Build | Vite 6 |
| Android | Capacitor 8 (WebView + assets embarqués) |
| Données locales | IndexedDB (moteur hors-ligne) |
| Cloud | Supabase (PostgreSQL + RLS) |
| Graphiques | D3.js, Recharts |
| Scan | `html5-qrcode` (caméra) + lecteurs USB/Bluetooth HID |
| Langue | Français |

---

## Fonctionnalités

### Caisse
- Recherche et scan code-barres (lecteur USB/Bluetooth, caméra), avec latence de traitement affichée.
- Raccourcis clavier : `F1` recherche, `F2` encaissement, `Échap` fermeture sécurisée.
- Panier, remises, quantités, alertes de stock dès l'ajout.
- Paiements multiples, rendu de monnaie avec suggestions de billets (DA).
- Vidage de panier en deux temps (confirmation + annulation immédiate).

### Catalogue & stock
- Fiches produits (SKU, code-barres EAN-13, catégorie, prix HT/TVA/TTC, seuil d'alerte).
- Scanner caméra pour associer un code-barres.
- Suivi des seuils et alertes de stock.

### Ventes, factures, clients
- Historique des ventes avec statuts.
- Réimpression ticket thermique 80 mm ou facture A4.
- Fiches clients et historique d'achats.

### Tableau de bord
- KPI calculés à partir des ventes et du stock réels (CA du jour, tickets, panier moyen, alertes).
- Tendances et répartitions via D3.js / Recharts.

### Administration & synchronisation
- Configuration du endpoint Supabase et de la clé anonyme.
- File d'attente hors-ligne et résolution de conflits.
- Script SQL fourni dans `supabase/schema.sql`.

---

## Démarrage rapide

Prérequis : Node.js 20+ (22 recommandé) et npm.

```bash
npm ci          # installation reproductible (package-lock.json)
npm run dev     # serveur de développement — http://localhost:3000
npm run lint    # vérification TypeScript
npm run build   # build de production dans dist/
```

---

## Android

Le projet Android est généré/maintenu via Capacitor (`android/`).

```bash
npm run build
npx cap sync android
cd android && ./gradlew assembleDebug   # APK de développement local
```

> ⚠️ **Aucune release de production n'est signée localement.**
> Les APK/AAB publiés sont construits et signés exclusivement par GitHub Actions.

---

## CI/CD et releases

| Workflow | Déclencheur | Rôle |
| --- | --- | --- |
| `CI` | push / pull request | `tsc`, build Vite, et build Android **debug** de validation sur les PR |
| `Release` | push sur `master` / `main`, ou manuel | APK **release signé**, AAB signé, archive Web, sommes SHA-256, release GitHub |
| `Deploy to GitHub Pages` | push sur `master` / `main` | Déploiement du build Web |
| `CodeQL` | push / PR / hebdomadaire | Analyse de sécurité |

### Versionnement

- Format strict `MAJOR.MINOR.PATCH`, tag Git `vX.Y.Z`.
- Incrément automatique du patch à chaque release (ex. `v1.0.0` → `v1.0.1`).
- Version manuelle : `Actions → Release → Run workflow` avec le champ `version`.
- `versionCode` Android = `MAJOR × 10000 + MINOR × 100 + PATCH`.
- Le tag n'est créé **qu'après** un build réussi : pas de tag orphelin en cas d'échec.

### Secrets requis pour signer l'APK

À configurer dans `Settings → Secrets and variables → Actions` :

| Secret | Description |
| --- | --- |
| `ANDROID_KEYSTORE_BASE64` | Keystore `.jks` encodé en base64 |
| `ANDROID_KEYSTORE_PASSWORD` | Mot de passe du keystore |
| `ANDROID_KEY_ALIAS` | Alias de la clé |
| `ANDROID_KEY_PASSWORD` | Mot de passe de la clé |

Sans ces secrets, le workflow `Release` échoue volontairement : aucun APK signé en debug n'est publié.

Génération d'un keystore (à conserver hors du dépôt) :

```bash
keytool -genkeypair -v -keystore release.keystore -alias posmodule \
  -keyalg RSA -keysize 2048 -validity 10000
base64 -w 0 release.keystore   # → ANDROID_KEYSTORE_BASE64
```

---

## Structure

```
src/
  components/     # caisse, catalogue, clients, ventes, dashboard, layout, reçus
  context/        # PosContext (état métier, panier, statistiques)
  services/       # IndexedDB, synchronisation Supabase, sons
  hooks/          # hooks partagés (useMediaQuery…)
  data/           # données de démarrage
  types/          # types TypeScript
android/          # projet Capacitor natif
supabase/         # schéma SQL et politiques RLS
.github/workflows # CI, release signée, Pages, CodeQL
```

---

## Licence

MIT.
