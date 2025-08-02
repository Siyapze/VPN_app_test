# First Test App 🚀

A comprehensive Flutter application featuring native splash screens, onboarding flow, Firebase integration, AI-powered features, and modern Material 3 design.

## 📱 Features

### ✅ Completed Features
- **🧱 Native Splash Screen** - Configurable splash screen with animations
- **📖 Onboarding Flow** - Interactive 4-page walkthrough for new users
- **🎨 Material 3 Design** - Modern UI with dynamic theming
- **📱 Cross-Platform** - Supports Android, iOS, Web, Windows, macOS, and Linux

### 🚧 Planned Features
- **🔐 Firebase Authentication** - Email/password, Google Sign-in, anonymous login
- **📡 Backend Integration** - Firestore, Cloud Functions, Firebase Storage
- **🧠 OpenRouter AI Integration** - AI-powered features with multiple model support
- **🔔 Push Notifications** - Firebase Cloud Messaging with local fallback
- **⚙️ App Settings** - Theme toggle, language selection, preferences
- **🌐 Localization** - Multi-language support (English, French)
- **🔒 Security** - Encrypted storage, environment variables, permissions

## 🏗️ Architecture

This project follows a **feature-first architecture** for better scalability and maintainability:

```
lib/
├── core/             # Theme, services, constants, error handling
├── features/         # Feature-specific modules
│   ├── splash/       # Splash screen implementation
│   ├── onboarding/   # User onboarding flow
│   ├── home/         # Home screen
│   ├── auth/         # Authentication (planned)
│   ├── settings/     # App settings (planned)
│   └── ai_chat/      # AI integration (planned)
├── data/             # Repositories, models, API clients (planned)
├── l10n/             # Localization files (planned)
├── routes/           # Navigation configuration (planned)
└── main.dart         # App entry point
```

## 🚀 Getting Started

### Prerequisites
- Flutter SDK (3.7.2 or higher)
- Dart SDK
- Android Studio / VS Code
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/YOUR_USERNAME/first_test_app.git
   cd first_test_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Generate splash screen assets**
   ```bash
   dart run flutter_native_splash:create
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

### Building for Production

**Android APK:**
```bash
flutter build apk
```

**iOS (requires macOS):**
```bash
flutter build ios
```

**Web:**
```bash
flutter build web
```

## 📋 Development Progress

- [x] **Project Setup** - Flutter project initialization
- [x] **Splash Screen** - Native splash with custom animations
- [x] **Onboarding** - Interactive user walkthrough
- [x] **Basic Navigation** - Route configuration
- [ ] **Firebase Setup** - Authentication and backend
- [ ] **AI Integration** - OpenRouter API implementation
- [ ] **Push Notifications** - FCM integration
- [ ] **Settings System** - User preferences
- [ ] **Localization** - Multi-language support
- [ ] **Security** - Encrypted storage and API keys

## 🎨 Design System

- **Primary Color:** `#42a5f5` (Material Blue)
- **Secondary Color:** `#1976d2` (Blue 700)
- **Design Language:** Material 3
- **Typography:** Default Material fonts
- **Icons:** Material Icons + Custom icons

## 🛠️ Key Dependencies

```yaml
dependencies:
  flutter: sdk
  cupertino_icons: ^1.0.8

dev_dependencies:
  flutter_test: sdk
  flutter_lints: ^5.0.0
  flutter_native_splash: ^2.4.1
```

## 📱 Screenshots

*Screenshots will be added as features are completed*

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Flutter team for the amazing framework
- Material Design team for the design system
- Firebase team for backend services
- OpenRouter for AI integration capabilities

---

**Built with ❤️ using Flutter**

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
