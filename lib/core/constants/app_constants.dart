/// App-wide constants for STRESSLESS VPN
class AppConstants {
  // App Information
  static const String appName = 'STRESSLESS VPN';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Secure VPN for unrestricted internet access';

  // Splash Screen
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration animationDuration = Duration(milliseconds: 1500);

  // VPN Colors (Professional and trustworthy)
  static const String primaryColorHex =
      '#1565C0'; // Deep Blue - Trust & Security
  static const String secondaryColorHex = '#0D47A1'; // Darker Blue
  static const String accentColorHex = '#4CAF50'; // Green - Connected/Safe
  static const String warningColorHex = '#FF9800'; // Orange - Warning
  static const String errorColorHex = '#F44336'; // Red - Error/Disconnected

  // Subscription & Trial
  static const int freeTrialDays = 3;
  static const String freeTrialText = '3-Day Free Trial';
  static const String subscriptionText = 'Premium Access';

  // VPN Features
  static const List<String> vpnFeatures = [
    'Bypass internet restrictions',
    'Access global content',
    'Secure encrypted connection',
    'High-speed servers',
    'No logs policy',
    '24/7 customer support',
  ];

  // Assets (to be added later)
  static const String logoPath = 'assets/images/logo.png';
  static const String splashImagePath = 'assets/images/splash.png';
  static const String vpnIconPath = 'assets/images/vpn_icon.png';
}
