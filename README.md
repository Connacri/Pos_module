<div align="center">

# 🛒 POS Module

### Modern Flutter Point of Sale • Offline First • Modular • Cross Platform

<p>
A complete, scalable and enterprise-ready Point of Sale solution built with
<b>Flutter</b>, <b>ObjectBox</b> and <b>Supabase</b>.
</p>

<p>

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20Windows%20%7C%20Linux%20%7C%20macOS-success)
![Material3](https://img.shields.io/badge/Material-3-blue)
![ObjectBox](https://img.shields.io/badge/ObjectBox-Offline-green)
![Supabase](https://img.shields.io/badge/Supabase-Realtime-3ECF8E?logo=supabase)
![License](https://img.shields.io/github/license/Connacri/Pos_module)
![Stars](https://img.shields.io/github/stars/Connacri/Pos_module)
![Issues](https://img.shields.io/github/issues/Connacri/Pos_module)
![Release](https://img.shields.io/github/v/release/Connacri/Pos_module)

</p>

---

Enterprise-grade Point of Sale built using **Flutter Monorepo**, **Clean Architecture**, **Provider**, **ObjectBox**, and **Supabase**.

Designed for:

🏪 Retail Stores • 🛒 Supermarkets • 🍽 Restaurants • ☕ Cafés • 💊 Pharmacies • 🏥 Hospitals • 🧾 Small & Large Businesses

</div>

---

# ✨ Features

## 🛒 Sales

- Modern POS interface
- Barcode Scanner
- Fast Product Search
- Multiple Payment Methods
- Discounts
- Taxes
- Partial Payments
- Split Payments
- Returns & Refunds
- Sales History

---

## 📦 Inventory

- Unlimited Products
- Categories
- Brands
- Suppliers
- Stock Management
- Purchase Orders
- Stock Movements
- Low Stock Alerts
- Barcode Support
- SKU Management

---

## 🧾 Billing

- Invoices
- Quotations
- Receipts
- PDF Export
- 80mm Thermal Printing
- A4 Invoice Printing
- QR Code Payment

---

## 📊 Dashboard

- Daily Revenue
- Monthly Revenue
- Sales Statistics
- Product Analytics
- Best Sellers
- Customer Statistics
- Inventory Value
- Profit Reports

---

## 🌍 Internationalization

Supports:

- 🇫🇷 French
- 🇬🇧 English
- 🇪🇸 Spanish
- 🇸🇦 Arabic (RTL)

---

## 🌙 User Experience

- Material Design 3
- Dark Mode
- Light Mode
- Responsive UI
- Desktop Layout
- Tablet Layout
- Mobile Layout

---

## ⚡ Offline First

Built for unreliable internet connections.

✔ ObjectBox Local Database

✔ Instant Local Operations

✔ Automatic Synchronization

✔ Conflict Resolution

✔ Realtime Updates

---

# 🚀 Download

## Android

[![Android](https://img.shields.io/badge/Download-Android%20APK-3DDC84?style=for-the-badge&logo=android)](https://github.com/Connacri/Pos_module/releases/latest)

---

## Windows

[![Windows](https://img.shields.io/badge/Download-Windows%20Installer-0078D6?style=for-the-badge&logo=windows)](https://github.com/Connacri/Pos_module/releases/latest)

---

## Latest Releases

https://github.com/Connacri/Pos_module/releases

---

# 📚 Documentation

## Online User Guide

https://connacri.github.io/Pos_module/

---

# 🏗 Architecture

```
POS Module
│
├── app
│
├── packages
│   ├── pos_core
│   ├── pos_domain
│   ├── pos_data
│   ├── pos_pos
│   ├── pos_inventory
│   ├── pos_billing
│   └── ...
│
├── docs
├── assets
└── .github
```

---

## Architecture Layers

```
Presentation
      │
Provider
      │
Use Cases
      │
Repositories
      │
ObjectBox / Supabase
```

Following:

- Clean Architecture
- Feature First
- MVVM
- SOLID
- Repository Pattern
- Dependency Injection

---

# 📦 Packages

| Package | Description |
|----------|-------------|
| app | Main Application |
| pos_core | Shared Widgets, Theme, Localization |
| pos_domain | Entities & Business Logic |
| pos_data | Database, ObjectBox & Supabase |
| pos_pos | Point of Sale |
| pos_inventory | Inventory |
| pos_billing | Billing |
| future modules | CRM, Accounting, HR... |

---

# 🖥 Supported Platforms

| Platform | Status |
|-----------|--------|
| Android | ✅ |
| Windows | ✅ |
| Linux | ✅ |
| macOS | ✅ |
| Web | 🚧 |
| iOS | 🚧 |

---

# 🛠 Tech Stack

- Flutter
- Dart
- Material 3
- Provider
- ObjectBox
- Supabase
- PostgreSQL
- Realtime
- Storage
- Authentication
- GitHub Actions
- CodeQL

---

# 🚀 Quick Start

## Clone

```bash
git clone https://github.com/Connacri/Pos_module.git
```

---

## Install

```bash
flutter pub get
```

---

## Generate ObjectBox

```bash
cd packages/pos_data

dart run build_runner build --delete-conflicting-outputs
```

---

## Run

```bash
cd app

flutter run
```

---

# ⚙ Supabase

Configure using:

```
SUPABASE_URL

SUPABASE_PUBLISHABLE_KEY
```

via

```
--dart-define
```

Without Supabase configuration, the application automatically runs in **Offline Mode**.

---

# 📱 Screenshots

| Dashboard | POS | Inventory |
|------------|-----|-----------|
| Coming Soon | Coming Soon | Coming Soon |

---

# 🧪 Development

## Analyze

```bash
flutter analyze
```

---

## Tests

```bash
flutter test
```

---

## Build Android

```bash
flutter build apk --release
```

---

## Build Windows

```bash
flutter build windows --release
```

---

# 🔄 Continuous Integration

GitHub Actions automatically performs:

- Static Analysis
- Formatting
- Unit Tests
- APK Build
- Windows Build
- Releases
- CodeQL Security Scan

---

# 🎯 Roadmap

- [x] Flutter Monorepo
- [x] ObjectBox Offline
- [x] Supabase Sync
- [x] Material 3
- [x] Desktop Support
- [x] Barcode Scanner
- [x] Thermal Printing
- [x] PDF Invoice
- [ ] CRM Module
- [ ] Accounting Module
- [ ] Multi Store
- [ ] Employee Management
- [ ] Loyalty Program
- [ ] Cloud Backup
- [ ] AI Reports
- [ ] BI Dashboard

---

# 🤝 Contributing

Contributions are welcome!

1. Fork the repository

2. Create a feature branch

3. Commit your changes

4. Open a Pull Request

---

# ⭐ Support

If you like this project,

⭐ Star the repository

🐛 Report issues

💡 Suggest improvements

---

# 📄 License

This project is licensed under the MIT License.

---

<div align="center">

Codded By RMZ LAB

**POS Module**

Enterprise FORSLOG LTD Solution

</div>
