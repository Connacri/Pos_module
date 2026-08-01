# POS Module - Monorepo Flutter

Module de Point de Vente complet, modulaire et cross-platform construit avec **Flutter**, **ObjectBox** et **Supabase**.

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
# (URL + clé anon via --dart-define SUPABASE_URL / SUPABASE_ANON_KEY)
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
