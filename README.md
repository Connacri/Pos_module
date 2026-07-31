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
├── packages/              # Packages Dart (bibliothèques + features)
│   ├── pos_core/
│   ├── pos_domain/
│   ├── pos_data/
│   ├── pos_pos/
│   ├── pos_inventory/
│   └── pos_billing/
├── app/                   # Application hôte
├── pubspec.yaml           # Workspace pub
├── analysis_options.yaml
├── build.yaml
└── README.md
```

## Fonctionnalités

- Multiplateforme : Android, iOS, Web, Windows, macOS, Linux
- Material 3 avec mode clair/sombre
- Multilingue (FR, EN, ES, AR)
- Mode hors-ligne avec ObjectBox
- Synchronisation temps réel Supabase
- Layout adaptatif (mobile / tablette / desktop)
- Impression PDF (tickets 80mm + factures A4)
- Gestion des taxes multiples

## Démarrage rapide

```bash
# 1. Résoudre le workspace
flutter pub get

# 2. Générer le code ObjectBox
cd packages/pos_data
dart run build_runner build --delete-conflicting-outputs
cd ../..

# 3. Configurer Supabase
# Éditer app/lib/src/config/app_config.dart (URL + clé anon)

# 4. Lancer l'application hôte
cd app
flutter run
```

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
