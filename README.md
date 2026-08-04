# POS Module - Monorepo Flutter

Module de Point de Vente complet, modulaire et cross-platform construit avec **Flutter**, **ObjectBox** et **Supabase**.

## 🚀 Télécharger l'application

Les builds de production sont publiés automatiquement dans **GitHub Releases** à chaque poussée sur `master`.

### 📱 Android (APK)

[![Télécharger l'APK Android](https://img.shields.io/badge/Android-APK-3DDC84?style=for-the-badge&logo=android&logoColor=white)](https://github.com/Connacri/Pos_module/releases/latest)

### 🖥️ Windows (installeur)

[![Télécharger Windows](https://img.shields.io/badge/Windows-Installer-0078D6?style=for-the-badge&logo=windows&logoColor=white)](https://github.com/Connacri/Pos_module/releases/latest)

> Si les liens pointent vers la dernière release, cherchez les fichiers joints (`app-release.apk` et `POSModule-Setup-*.exe`) sur la page : [voir toutes les releases](https://github.com/Connacri/Pos_module/releases).

### 📖 Guide utilisateur

[![Voir le guide en ligne](https://img.shields.io/badge/Guide%20utilisateur-HTML-1976D2?style=for-the-badge)]([index.html](https://connacri.github.io/Pos_module/))
https://connacri.github.io/Pos_module/
## Architecture

Monorepo organisé en packages Dart (pub workspaces) :

| Package | Rôle |
| --- | --- |
| **`app`** | Application hôte : composition, DI, routing, thème |
| **`pos_core`** | Thème Material 3, i18n (FR/EN/ES/AR), routing, utilitaires, widgets partagés |
| **`pos_domain`** | Entities, use cases, interfaces de repositories (Clean Architecture) |
| **`pos_data`** | Implémentations ObjectBox, Supabase, repositories concrets |
| **`pos_pos`** | Feature caisse (interface de vente) |
| **`pos_inventory`** | Feature gestion de stock |
| **`pos_billing`** | Feature facturation |

```
.
├── .github/workflows/     # CI, release, CodeQL
├── app/                   # Application hôte (main.dart)
├── packages/              # Packages Dart (bibliothèques + features)
│   ├── pos_core/
│   ├── pos_domain/
│   ├── pos_data/
│   ├── pos_pos/
│   ├── pos_inventory/
│   └── pos_billing/
├── pubspec.yaml           # Workspace pub
├── analysis_options.yaml
├── build.yaml
└── README.md
```

## Fonctionnalités

- Multiplateforme : Android, iOS, Windows, macOS, Linux
- Material 3 avec mode clair/sombre
- Multilingue (FR, EN, ES, AR)
- Mode hors-ligne avec ObjectBox
- Synchronisation temps réel Supabase
- Layout adaptatif (mobile / tablette / desktop)
- Impression PDF (tickets 80mm + factures A4)
- Gestion des taxes multiples

## Prérequis

- Flutter `>= 3.32.0` (Dart `>= 3.8.0`)
- Android Studio avec le SDK Android (pour la cible Android)

## 📖 Guide utilisateur détaillé

> La version complète et mise en page est disponible en ligne : [index.html](index.html).

### Navigation

La barre de navigation est **en bas** sur mobile et **latérale** (rail) sur tablette/desktop.

| Icône | Section | Rôle |
| --- | --- | --- |
| 🏠 | Accueil | Tableau de bord & rapports |
| 🛒 | Caisse (POS) | Encaisser une vente |
| 📦 | Inventaire | Gérer les produits |
| 🧾 | Facturation | Factures + historique des ventes |
| ⚙️ | Réglages | Thème, langue, stockage, version |
| ↺ | Retours | Depuis l'Accueil ou le détail d'une vente |

### Accueil (Tableau de bord)

KPI (CA du jour, ventes du jour, panier moyen, créances), graphique CA sur 7 jours, ventes par
catégorie, top produits, valeur du stock, ruptures. Carte de **connectivité** (témoins **Internet**
et **Supabase**) + bouton **Synchroniser**. Cartes de raccourci vers Caisse, Inventaire, Facturation,
Retours, Réglages.

### Caisse (POS)

Ajouter des produits (recherche / scan), ajuster les quantités, choisir la méthode de paiement
(espèces, carte, mobile money, virement, crédit), valider → vente « Terminée » et décrément du stock.

### Inventaire

Liste des produits avec recherche, ajout/modification (nom, SKU, prix, TVA, stock, code-barres).

### Facturation

- **Factures** : recherche, résumé (total / en attente / retards), création depuis une vente,
  QR de paiement, marquer payée / émise, supprimer, imprimer.
- **Ventes** : toutes les ventes (numéro, client, date, statut, paiement, montant). Toucher une
  vente → voir son **détail**.

### Détail d'une vente

Statut, date, client, paiement, caissier, nombre d'articles, articles (prix × quantité, TVA),
totaux (sous-total, taxe, remise, total). Bouton **« Faire un retour »** si la vente est Terminée.

### Retours (total ou partiel)

1. **Facturation → Ventes** puis toucher une vente, ou **Accueil → Retours → Nouveau retour**.
2. Sélectionner la vente, puis régler les quantités avec les compteurs −/+/max (0 = non retourné).
3. Renseigner un motif (optionnel) et valider. Le **stock est restauré**, le **remboursement**
   recalculé, et la vente passe en « Retournée » si tout est retourné.

### Réglages

Thème (clair/sombre/système), langue (FR/EN/ES/AR), stockage (upload image/CSV, export CSV),
version affichée depuis le dernier tag de release.

### Connectivité & synchronisation

L'app fonctionne hors-ligne (ObjectBox) et se synchronise quand la connexion revient. Les témoins
**Internet / Supabase** sont testés par de vraies requêtes HTTP (fiable même sous Windows).

---

## Prérequis (développeur)

- Flutter `>= 3.32.0` (Dart `>= 3.8.0`)
- Android Studio avec le SDK Android (pour la cible Android)

## Démarrage rapide

```bash
# 1. Résoudre le workspace
flutter pub get

# 2. Générer le code ObjectBox
cd packages/pos_data
dart run build_runner build --delete-conflicting-outputs
cd ../..

# 3. Configurer Supabase (optionnel)
# Éditer packages/pos_data/lib/src/data_sources/supabase_config.dart
# (URL + clé publique via --dart-define SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY)
# Sans configuration, l'app fonctionne en mode hors-ligne uniquement.

# 4. Lancer l'application hôte
cd app
flutter run
```

## Android Studio

Ouvrir le dossier racine `pos_module` dans Android Studio. La run configuration
**`main.dart`** (`app/lib/main.dart`, working directory `app/`) permet de :
- Lancer l'application sur un émulateur/appareil via **Run** (`Shift+F10`)
- Utiliser **hot reload** (`R`) et **hot restart** (`Shift+R`) pendant le développement

Si la configuration n'apparaît pas, ouvrir `app/lib/main.dart` puis faire
`Run > Edit Configurations > + > Flutter` avec :
- Dart entrypoint : `app/lib/main.dart`
- Working directory : `app`

## GitHub Actions

| Workflow | Déclencheur | Effet |
| --- | --- | --- |
| **CI** | push / pull request sur `master` ou `develop` | Analyse statique, tests, build APK |
| **CodeQL** | push / pull request sur `master` | Analyse de sécurité du code |
| **Release** | tag `v*` ou lancement manuel | Build APK + installeur Windows (Inno Setup) publiés dans **GitHub Releases** |

Déclencher une release manuellement :
`Actions > Release > Run workflow` (version optionnelle, sinon auto-incrémentée).

## Analyse statique

```bash
# Par package (workspace) :
flutter analyze
cd packages/pos_domain && dart analyze && cd ../..
```

## Tests

```bash
cd packages/pos_domain && dart test && cd ../..
cd app && flutter test && cd ..
```

## Build de production

```bash
# APK Android
cd app && flutter build apk --release && cd ..

# Installeur Windows (nécessite Inno Setup : choco install innosetup)
cd app && flutter build windows --release && cd ..
ISCC.exe "app\windows\installer\pos_module.iss"
```
