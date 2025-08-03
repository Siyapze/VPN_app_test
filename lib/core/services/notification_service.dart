import 'dart:convert';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Firebase Cloud Messaging and Local Notifications service
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  static const String _fcmTokenKey = 'fcm_token';
  static const String _notificationSettingsKey = 'notification_settings';

  String? _fcmToken;
  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Request permission for notifications
      await _requestPermissions();

      // Initialize local notifications
      await _initializeLocalNotifications();

      // Initialize Firebase Messaging
      await _initializeFirebaseMessaging();

      // Setup message handlers
      _setupMessageHandlers();

      _isInitialized = true;
      print('Notification service initialized successfully');
    } catch (e) {
      print('Error initializing notification service: $e');
    }
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    final settings = await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  /// Initialize local notifications
  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels for Android
    if (Platform.isAndroid) {
      await _createNotificationChannels();
    }
  }

  /// Create notification channels for Android
  Future<void> _createNotificationChannels() async {
    const vpnChannel = AndroidNotificationChannel(
      'vpn_notifications',
      'VPN Notifications',
      description: 'Notifications related to VPN connection status',
      importance: Importance.high,
      sound: RawResourceAndroidNotificationSound('notification'),
    );

    const generalChannel = AndroidNotificationChannel(
      'general_notifications',
      'General Notifications',
      description: 'General app notifications',
      importance: Importance.defaultImportance,
    );

    const securityChannel = AndroidNotificationChannel(
      'security_notifications',
      'Security Alerts',
      description: 'Security-related notifications',
      importance: Importance.max,
      sound: RawResourceAndroidNotificationSound('alert'),
    );

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(vpnChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(generalChannel);

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(securityChannel);
  }

  /// Initialize Firebase Messaging
  Future<void> _initializeFirebaseMessaging() async {
    // Get FCM token
    _fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $_fcmToken');

    // Save token to preferences
    if (_fcmToken != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_fcmTokenKey, _fcmToken!);
    }

    // Listen for token refresh
    _firebaseMessaging.onTokenRefresh.listen((token) {
      _fcmToken = token;
      _saveTokenToPreferences(token);
      print('FCM Token refreshed: $token');
    });
  }

  /// Setup message handlers
  void _setupMessageHandlers() {
    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle background message taps
    FirebaseMessaging.onMessageOpenedApp.listen(_handleBackgroundMessageTap);

    // Handle app launch from terminated state
    _handleAppLaunchFromNotification();
  }

  /// Handle foreground messages
  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    print('Received foreground message: ${message.messageId}');

    // Show local notification for foreground messages
    await _showLocalNotification(
      title: message.notification?.title ?? 'StressLess VPN',
      body: message.notification?.body ?? 'New notification',
      payload: jsonEncode(message.data),
      channelId: _getChannelId(message.data['type']),
    );
  }

  /// Handle background message tap
  void _handleBackgroundMessageTap(RemoteMessage message) {
    print('Background message tapped: ${message.messageId}');
    _handleNotificationAction(message.data);
  }

  /// Handle app launch from notification
  Future<void> _handleAppLaunchFromNotification() async {
    final initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      print('App launched from notification: ${initialMessage.messageId}');
      _handleNotificationAction(initialMessage.data);
    }
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    print('Local notification tapped: ${response.id}');
    
    if (response.payload != null) {
      try {
        final data = jsonDecode(response.payload!);
        _handleNotificationAction(data);
      } catch (e) {
        print('Error parsing notification payload: $e');
      }
    }
  }

  /// Handle notification actions
  void _handleNotificationAction(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final action = data['action'] as String?;

    switch (type) {
      case 'vpn_status':
        // Navigate to VPN screen
        break;
      case 'security_alert':
        // Show security alert dialog
        break;
      case 'announcement':
        // Navigate to announcements
        break;
      case 'ai_response':
        // Navigate to AI chat
        break;
      default:
        // Default action
        break;
    }
  }

  /// Show local notification
  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
    String channelId = 'general_notifications',
    int id = 0,
  }) async {
    final androidDetails = AndroidNotificationDetails(
      channelId,
      _getChannelName(channelId),
      channelDescription: _getChannelDescription(channelId),
      importance: _getImportance(channelId),
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id,
      title,
      body,
      notificationDetails,
      payload: payload,
    );
  }

  /// Show VPN status notification
  Future<void> showVpnStatusNotification({
    required bool isConnected,
    String? serverLocation,
  }) async {
    final title = isConnected ? 'VPN Connected' : 'VPN Disconnected';
    final body = isConnected 
        ? 'Connected to ${serverLocation ?? 'VPN server'}'
        : 'VPN connection has been disconnected';

    await _showLocalNotification(
      title: title,
      body: body,
      channelId: 'vpn_notifications',
      id: 1,
      payload: jsonEncode({
        'type': 'vpn_status',
        'connected': isConnected,
        'server': serverLocation,
      }),
    );
  }

  /// Show security alert notification
  Future<void> showSecurityAlert({
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    await _showLocalNotification(
      title: title,
      body: message,
      channelId: 'security_notifications',
      id: 2,
      payload: jsonEncode({
        'type': 'security_alert',
        'data': data,
      }),
    );
  }

  /// Get FCM token
  String? get fcmToken => _fcmToken;

  /// Get notification settings
  Future<Map<String, bool>> getNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final settingsJson = prefs.getString(_notificationSettingsKey);
    
    if (settingsJson != null) {
      final settings = jsonDecode(settingsJson) as Map<String, dynamic>;
      return settings.map((key, value) => MapEntry(key, value as bool));
    }

    // Default settings
    return {
      'vpn_notifications': true,
      'security_alerts': true,
      'general_notifications': true,
      'ai_notifications': true,
    };
  }

  /// Update notification settings
  Future<void> updateNotificationSettings(Map<String, bool> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_notificationSettingsKey, jsonEncode(settings));
  }

  /// Save FCM token to preferences
  Future<void> _saveTokenToPreferences(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_fcmTokenKey, token);
  }

  /// Get channel ID based on notification type
  String _getChannelId(String? type) {
    switch (type) {
      case 'vpn_status':
        return 'vpn_notifications';
      case 'security_alert':
        return 'security_notifications';
      default:
        return 'general_notifications';
    }
  }

  /// Get channel name
  String _getChannelName(String channelId) {
    switch (channelId) {
      case 'vpn_notifications':
        return 'VPN Notifications';
      case 'security_notifications':
        return 'Security Alerts';
      default:
        return 'General Notifications';
    }
  }

  /// Get channel description
  String _getChannelDescription(String channelId) {
    switch (channelId) {
      case 'vpn_notifications':
        return 'Notifications related to VPN connection status';
      case 'security_notifications':
        return 'Security-related notifications';
      default:
        return 'General app notifications';
    }
  }

  /// Get importance level
  Importance _getImportance(String channelId) {
    switch (channelId) {
      case 'security_notifications':
        return Importance.max;
      case 'vpn_notifications':
        return Importance.high;
      default:
        return Importance.defaultImportance;
    }
  }

  /// Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _localNotifications.cancelAll();
  }

  /// Cancel notification by ID
  Future<void> cancelNotification(int id) async {
    await _localNotifications.cancel(id);
  }
}
