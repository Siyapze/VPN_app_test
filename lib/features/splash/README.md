# Splash Screen Feature

## Overview
The splash screen feature provides a native splash screen implementation using `flutter_native_splash` package with custom animations and optional onboarding flow.

## Features
- ✅ Native splash screen using `flutter_native_splash`
- ✅ Configurable via YAML in `pubspec.yaml`
- ✅ Custom animated splash screen with fade and scale animations
- ✅ Optional onboarding walkthrough
- ✅ Smooth transitions between screens
- ✅ Material 3 design system integration

## Implementation Details

### Native Splash Screen
- **Package**: `flutter_native_splash: ^2.4.1`
- **Background Color**: `#42a5f5` (Material Blue)
- **Configuration**: Located in `pubspec.yaml` under `flutter_native_splash` section
- **Generation Command**: `dart run flutter_native_splash:create`

### Custom Splash Screen Widget
- **Location**: `lib/features/splash/splash_screen.dart`
- **Duration**: 3 seconds (configurable in `AppConstants`)
- **Animations**: 
  - Fade animation (0.0 to 1.0 opacity)
  - Scale animation (0.5 to 1.0 scale with elastic curve)
- **Navigation**: Automatically navigates to onboarding or home screen

### Onboarding Flow
- **Location**: `lib/features/onboarding/onboarding_screen.dart`
- **Features**:
  - 4 onboarding pages with different themes
  - Page indicators
  - Skip functionality
  - Previous/Next navigation
  - Smooth page transitions

## Configuration

### Splash Duration
```dart
// In lib/core/constants/app_constants.dart
static const Duration splashDuration = Duration(seconds: 3);
static const Duration animationDuration = Duration(milliseconds: 1500);
```

### Colors
```dart
static const String primaryColorHex = '#42a5f5';
static const String secondaryColorHex = '#1976d2';
```

## Usage

### Basic Implementation
The splash screen is automatically shown when the app starts. It's configured as the initial route in `main.dart`:

```dart
initialRoute: '/',
routes: {
  '/': (context) => const SplashScreen(),
  '/onboarding': (context) => const OnboardingScreen(),
  '/home': (context) => const HomeScreen(),
},
```

### Customization
1. **Change splash duration**: Modify `AppConstants.splashDuration`
2. **Update animations**: Modify animation controllers in `SplashScreen`
3. **Change colors**: Update color constants in `AppConstants`
4. **Add custom logo**: Update the icon in the splash screen widget

## Future Enhancements
- [ ] Add SharedPreferences to track first-time users
- [ ] Implement custom splash images/logos
- [ ] Add more animation options
- [ ] Support for different splash screens per platform
- [ ] Integration with app initialization logic
