# POS Module — Application hôte

Point de vente multiplateforme : caisse, inventaire, facturation et retours, avec mode hors-ligne
(ObjectBox) et synchronisation Supabase.

## 💻 Lancer l'application

```bash
flutter pub get
cd packages/pos_data && dart run build_runner build --delete-conflicting-outputs && cd ../..
cd app
flutter run
```

## ▶️ Run depuis Android Studio

Ouvrir la racine `pos_module` dans Android Studio puis `app/lib/main.dart` (working directory `app/`)
pour y exécuter `Run` / `hot reload`.

## 🔗 Liens utiles

- Guide utilisateur complet : [`../index.html`](../index.html)
- Documentation racine : [`../README.md`](../README.md)
- Télécharger la dernière release : https://github.com/Connacri/Pos_module/releases