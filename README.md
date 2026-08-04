# 🌍 Travelouge Frontend

![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-Android%20%7C%20iOS-success)
![Backend](https://img.shields.io/badge/Backend-Django%20REST-green)

Travelouge Frontend is a cross-platform Flutter application for discovering, creating, and sharing memorable travel routes. It combines interactive maps, rich media, and social features in a responsive mobile experience backed by a Django REST API.

## ✨ Features

- 🔐 Secure registration and login with JWT authentication
- 👤 User profile and account management
- 🗺️ Create, edit, view, and delete travel routes
- 📍 Explore routes and coordinates on interactive maps
- 📸 Upload photos when creating route content
- ❤️ Like and unlike routes
- 💬 Join discussions through route comments
- 🔖 Save favorite routes for quick access
- 🔎 Search for travelers and travel routes
- 📱 Responsive, cross-platform user interface
- 🔄 REST API integration with a Django backend

## 🛠️ Tech Stack

| Category                | Technologies                              |
| ----------------------- | ----------------------------------------- |
| **Mobile**              | Flutter, Dart                             |
| **Networking**          | REST API, HTTP, Dio                       |
| **Backend Integration** | Django REST Framework, JWT Authentication |
| **Local Storage**       | SharedPreferences                         |
| **Maps & Location**     | Google Maps, Geolocator, Geocoding        |
| **Media**               | Image Picker, Video Player                |

## 📂 Project Structure

```text
travelouge_frontend/
├── android/                     # Android platform configuration
├── ios/                         # iOS platform configuration
├── assets/
│   ├── png/                     # Images and UI assets
│   └── videos/                  # Video assets
├── lib/
│   ├── core/
│   │   └── constants/           # App-wide configuration and constants
│   ├── data/
│   │   └── services/            # Authentication and route API services
│   ├── features/
│   │   ├── auth/
│   │   │   └── screens/         # Sign-in, sign-up, and password flows
│   │   ├── home/
│   │   │   └── screens/         # Home and search experiences
│   │   ├── profile/
│   │   │   └── screens/         # Account and profile management
│   │   └── route/
│   │       └── screens/         # Route creation, details, trips, and maps
│   ├── widget/                  # Reusable application widgets
│   ├── app_theme.dart           # Global theme configuration
│   └── main.dart                # Application entry point
├── test/                        # Automated tests
├── pubspec.yaml                 # Dependencies and asset declarations
└── README.md
```

## 📱 Screenshots

> Screenshots will be added in a future update.

## 🚀 Installation

Ensure that the [Flutter SDK](https://docs.flutter.dev/get-started/install) is installed and a device or emulator is available.

```bash
git clone https://github.com/selcanakturk/travelouge_frontend.git
cd travelouge_frontend
flutter pub get
flutter run
```

Configure the backend base URL and required map credentials for your environment before running the application.

## 🔗 Backend

This application communicates with the **Travelouge Django REST backend** for authentication, user profiles, routes, media, likes, comments, favorites, and search functionality. API requests are authorized using JWT access tokens.

The backend service must be running and accessible from the device or emulator for API-dependent features to work.

## 🎯 Future Improvements

- 📴 Offline mode and local route caching
- 🧭 Personalized route recommendations
- 🔔 Push notifications for social interactions
- 🌐 Multi-language support
- 🌙 Enhanced dark mode experience
- ⚡ Performance and image-loading optimization

## 👨‍💻 Author

**Selcan Aktürk** · Software Engineer

- GitHub: [@selcanakturk](https://github.com/selcanakturk)
- LinkedIn: [Selcan Aktürk](https://linkedin.com/in/selcan-akt%C3%BCrk)
