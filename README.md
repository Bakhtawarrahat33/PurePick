<div align="center">

# 🌿 PurePick AI

**Your AI-powered product safety companion.**  
Scan any product label, instantly analyze ingredients, and know exactly what you're putting on or in your body.

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?style=flat-square&logo=flutter)](https://flutter.dev)
[![Python](https://img.shields.io/badge/Python-3.10+-3776AB?style=flat-square&logo=python)](https://python.org)
[![Django](https://img.shields.io/badge/Django-REST-092E20?style=flat-square&logo=django)](https://www.django-rest-framework.org)
[![License](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

</div>

---

## 📖 Overview

**PurePick** is a full-stack mobile application that empowers users to make safer, more informed purchasing decisions. Point your camera at any product's ingredient list — PurePick's AI pipeline will extract, analyze, and score each ingredient against your personal health profile, flagging allergens, harmful chemicals, and risky additives in seconds.

---

## ✨ Features

| Feature | Description |
|---|---|
| 📸 **Scan Product Labels** | Camera-based OCR to extract ingredients from physical labels |
| 🤖 **AI Ingredient Analysis** | Each ingredient is scored for safety, toxicity, and allergen risk |
| 🧬 **Personal Health Profile** | Set your allergies and sensitivities for personalized results |
| 💬 **AI Chat Assistant** | Ask follow-up questions about any ingredient or product |
| 💡 **AI Tips** | Personalized health and safety tips based on your scan history |
| 🕓 **Scan History** | View all past scans with safety scores and breakdowns |
| 🔖 **Save Products** | Bookmark products for quick future reference |
| 🔐 **Authentication** | Register/login with username & password, or Google Sign-In |
| 🔄 **Safer Alternatives** | Suggests safer product swaps when harmful ingredients are detected |

---

## 🏗️ Project Structure

```
PurePick/
├── backend/                  # Django REST API (Python)
│   ├── purepick_core/        # Core Django app (models, views, URLs)
│   ├── scanner/              # AI scanning & ingredient analysis engine
│   ├── db.sqlite3            # Local development database
│   └── venv/                 # Python virtual environment (not committed)
│
└── mobile_app/               # Flutter cross-platform mobile app
    └── lib/
        ├── main.dart         # App entry point
        ├── screens/          # All UI screens
        │   ├── welcome_screen.dart
        │   ├── login_screen.dart
        │   ├── signup_screen.dart
        │   ├── profile_setup_screen.dart
        │   ├── home_screen.dart
        │   ├── scan_screen.dart
        │   ├── analysis_screen.dart
        │   ├── result_screen.dart
        │   ├── history_screen.dart
        │   ├── saved_screen.dart
        │   ├── ai_chat_screen.dart
        │   ├── ai_tips_screen.dart
        │   ├── settings_screen.dart
        │   └── privacy_screen.dart
        └── services/
            └── api_service.dart   # All HTTP calls to backend
```

---

## 🛠️ Tech Stack

### Mobile App (Frontend)
- **Flutter** — Cross-platform UI (Android, iOS, Windows)
- **Dart** — Application logic
- **Google Fonts** (Poppins) — Typography
- **shared_preferences** — Local session/user storage
- **http** — REST API communication
- **camera / image_picker** — Product label scanning

### Backend (API)
- **Python 3.10+**
- **Django + Django REST Framework** — REST API
- **SQLite** (dev) — Database
- **AI/ML Pipeline** — Ingredient extraction & safety scoring

---

## 🚀 Getting Started

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- [Python](https://www.python.org/downloads/) ≥ 3.10
- An Android device or emulator

---

### 1. Clone the Repository

```bash
git clone https://github.com/Bakhtawarrahat33/PurePick.git
cd PurePick
```

---

### 2. Backend Setup

```bash
cd backend

# Create and activate a virtual environment
python -m venv venv
venv\Scripts\activate          # Windows
# source venv/bin/activate    # macOS/Linux

# Install dependencies
pip install -r requirements.txt

# Run migrations
python manage.py migrate

# Start the development server
python manage.py runserver 0.0.0.0:8000
```

> ⚠️ The server must be started with `0.0.0.0:8000` so your physical phone can reach it over your local Wi-Fi network.

---

### 3. Configure the Mobile App

Open `mobile_app/lib/services/api_service.dart` and update the base URL to your computer's **local IP address**:

```dart
// Find your IP with: ipconfig (Windows) or ifconfig (macOS/Linux)
static const String baseUrl = 'http://YOUR_LOCAL_IP:8000/api';
```

> 💡 **Note:** Do **not** use `localhost` — physical devices cannot reach it. Use your machine's local network IP (e.g., `192.168.1.x`).

---

### 4. Run the Flutter App

```bash
cd mobile_app

# Get dependencies
flutter pub get

# Run on a connected device or emulator
flutter run
```

---

## 📱 App Screens

| Screen | Description |
|---|---|
| **Welcome** | Onboarding / splash screen |
| **Login / Sign Up** | User authentication |
| **Profile Setup** | Enter allergies & health preferences |
| **Home** | Dashboard with stats, quick actions & recent scans |
| **Scan** | Camera screen to scan product labels |
| **Analysis** | Real-time processing & ingredient extraction |
| **Results** | Full safety score breakdown with flagged ingredients |
| **AI Chat** | Conversational AI for ingredient/health questions |
| **AI Tips** | Personalized health tips from your scan history |
| **History** | Full archive of all scans with scores |
| **Saved** | Bookmarked products |
| **Settings** | Account management, privacy, preferences |

---

## 🔌 API Endpoints

| Method | Endpoint | Description |
|---|---|---|
| `POST` | `/api/register/` | Register a new user |
| `POST` | `/api/login/` | Authenticate user |
| `POST` | `/api/google-login/` | Google OAuth login |
| `POST` | `/api/profile/update/` | Update health profile |
| `GET` | `/api/profile/<id>/` | Get health profile |
| `POST` | `/api/analyze/` | Analyze ingredients (text list) |
| `POST` | `/api/scan-label/` | Analyze product label (image upload) |
| `POST` | `/api/alternatives/` | Get safer product alternatives |
| `GET` | `/api/history/<user_id>/` | Get scan history |
| `POST` | `/api/saved/add/` | Save a product |
| `GET` | `/api/saved/<user_id>/` | Get saved products |
| `DELETE` | `/api/saved/delete/<id>/` | Delete a saved product |
| `POST` | `/api/chat/` | Chat with the AI assistant |
| `GET` | `/api/ai-tips/<user_id>/` | Get personalized AI tips |

---

## 🤝 Contributing

1. Fork the repo
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Commit your changes: `git commit -m "feat: add your feature"`
4. Push to the branch: `git push origin feature/your-feature`
5. Open a Pull Request

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with 💚 by [Bakhtawar Rahat](https://github.com/Bakhtawarrahat33)

</div>
