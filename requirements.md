🛠️ Feature Breakdown
1. 🧱 Splash Screen
Native splash screen using flutter_native_splash

Configurable via YAML

Optional: Intro animation or onboarding walkthrough

2. 🔐 Authentication (Firebase)
Firebase Authentication

Email/password login

Google Sign-in (with plugin support)

Anonymous guest login

Prebuilt UI or fully custom form

AuthService for login, registration, and session persistence

Firebase user profile extension via Firestore

Password reset & email verification support

3. 📡 Backend Integration (Firebase)
Firestore

User data storage

Dynamic content feeds

Cloud Functions

Serverless backend logic (e.g., data triggers)

Firebase Storage

Media upload support (e.g., profile pictures)

Firebase Hosting (Optional for web support)

4. 🧠 OpenRouter AI Integration
Service for AI prompts and responses

Headers include dynamic API key from user settings

Abstracted AIService class (e.g., sendPrompt(prompt, model))

Easy switch between OpenAI, Claude, Mistral, etc.

Prompt caching (optional local storage for reuse)

5. 🔔 Push Notifications
Firebase Cloud Messaging (FCM)

Foreground and background push support

Local notification fallback using flutter_local_notifications

Token storage in Firestore for targeting specific users

Optional: Topic-based notifications

6. ⚙️ App Settings
Theme toggle (light/dark/system)

Language selection (English, French by default)

Notification preferences

OpenRouter API key input

Delete account / log out options

7. 🌐 Localization & Theming
intl for language translation

Language strings managed via .arb files

Dynamic theme switching with ThemeData

Default: Material 3-based design

Easy override for global primary color

8. 🗂️ Project Structure (Feature-First)
csharp
Copy
Edit
lib/
│
├── core/             # Theme, services, constants, error handling
│
├── features/
│   ├── auth/         # Login, signup, profile
│   ├── settings/     # App settings, theme, localization
│   ├── ai_chat/      # OpenRouter integration
│   ├── notifications/
│
├── data/             # Repositories, models, API clients
├── l10n/             # Localization files
├── routes/           # Navigation configuration
├── main.dart
9. 🌐 Connectivity & Device Info
Network connectivity checker using connectivity_plus

Device info using device_info_plus for analytics/debugging

Optional: error capturing with Sentry

10. 🔐 Security & Environment
API keys stored in .env using flutter_dotenv

Encrypted secure storage using flutter_secure_storage

Permissions handling using permission_handler