# 🛒 DashGrocer — Fresh Groceries & Smart Pickup App

[![Flutter](https://img.shields.io/badge/Flutter-3.47+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.0+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Core%20%7C%20Firestore%20%7C%20Auth-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS%20%7C%20Web%20%7C%20Windows-brightgreen)](#)
[![Tests](https://img.shields.io/badge/Tests-27%20Passed-success)](#)

A modern, fast, full-featured grocery ordering and local in-store pickup application built with Flutter, Firebase, and Clean UI/UX principles.

---

## 🌟 Key Features

### 👤 Customer Experience
- **Cinematic Launch & Onboarding:** Full-screen 9:16 high-resolution splash hero with smooth animations and edge-to-edge onboarding.
- **Fresh Vegetable Catalog:** Authentic local vegetables (Pumpkin, Tomatoes, Red Onions, Green Beans, Highland Carrots) with transparent PNG imagery, verified prices, and rich nutritional breakdowns (Vitamin A, Lycopene, Quercetin, Vitamin K, Beta-Carotene).
- **Seller Showcase & Live Chat:**
  - View full seller/store credentials directly from any product page (Verified badge, store rating, response time, location).
  - Real-time context-aware interactive chat with the seller (shows the product being inquired about, quick questions chips, typing indicators).
  - Direct store telephone dialer.
- **Cart & Store Pickup:** Add items, view instant subtotal calculations, select scheduled pickup time slots (e.g., today 4:30 PM), and track order progress via a vertical stepper.
- **Ratings & Reviews:** Rate products, view star distribution bars, and read verified customer feedback.

### 🏪 Shop Owner / Seller Dashboard
- **Incoming Orders Management:** View live customer pickup orders, customer contact info, item summaries, and toggle orders as "Ready for Pickup" or "Completed".
- **Real-Time Notification Sheet:** Sound & badge notifications for incoming customer inquiries and orders.
- **Product Management & Presets:** Add new grocery items with custom photos, stock counts, pricing, or choose from verified vegetable presets.
- **Sales Analytics:** Track daily revenue, order volume, and top-selling items.

---

## 🚀 Quick Start (Install & Run in 3 Minutes)

Anyone can clone and run this application immediately without any special setup!

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`v3.24` or later)
- [Git](https://git-scm.com)
- Any supported device / emulator: Android device/emulator, Chrome browser, or Windows Desktop.

### 2. Clone Repository
```bash
git clone https://github.com/Akila-Liyanage/DashGrocer.git
cd DashGrocer
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Run Application
Run on your connected phone, emulator, or computer:

```bash
# Run on default connected device:
flutter run

# Or run directly on Web (Chrome):
flutter run -d chrome

# Or run on Windows Desktop:
flutter run -d windows
```

> **VS Code Users:** Simply open the folder in VS Code, open `.vscode/launch.json`, and press `F5` to start debugging immediately!

---

## 🔑 Pre-Configured Test Accounts

The app includes ready-to-test accounts so you can test all roles immediately:

| Role | Email | Password | What You Can Test |
| :--- | :--- | :--- | :--- |
| **Customer** | `customer@dashgrocer.com` | `Password123!` | Browse catalog, chat with seller, add to cart, checkout, schedule pickup |
| **Shop Owner** | `seller@dashgrocer.com` | `Password123!` | Manage incoming orders, mark orders ready, receive live inquiries, add products |
| **Admin** | `admin@dashgrocer.com` | `Password123!` | System monitoring and administrative controls |

*(You can also click **"Sign Up"** to create a brand new Customer or Shop Owner account at any time).*

---

## 🧪 Running Automated Tests

Run the comprehensive unit, widget, and integration test suite:

```bash
flutter test
```

All 27 automated tests pass with 0 failures:
- `complete_app_flow_test.dart` (End-to-end checkout, pickup flow, live order reflection)
- `figma_screens_test.dart` (5-screen UI layout and interaction tests)
- `seller_dashboard_test.dart` (Seller tabs, analytics, and add product screen)
- `seller_chat_test.dart` (Seller profile card, live chat screen, quick inquiries)
- `widget_test.dart` (Role-based access control and login flows)

---

## 📁 Project Architecture

```
lib/
├── core/
│   └── theme/           # Color palettes, typography, theme constants
├── models/
│   ├── chat_message_model.dart # Live chat data model
│   ├── grocery_item_model.dart # Product catalog & seller metadata
│   ├── seller_order_model.dart # Pickup orders & notifications
│   └── user_model.dart         # Role-based user model
├── services/
│   ├── auth_service.dart       # Firebase Authentication & session state
│   ├── chat_service.dart       # Real-time customer-seller chat engine
│   ├── database_seeder.dart    # Cloud Firestore seeder
│   └── grocery_service.dart    # In-memory & Firestore synchronized store
└── views/
    ├── auth/            # Splash screen, onboarding, login, register
    ├── common/          # Reusable AppImageView, helpers
    ├── customer/        # Customer dashboard, product details, cart, pickup, seller chat
    └── shop_owner/      # Shop owner dashboard, orders, analytics, add product
```

---

## 📄 License
This project is licensed under the MIT License — feel free to use, modify, and build upon it!
