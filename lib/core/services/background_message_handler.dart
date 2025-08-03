import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:convert';

/// Background message handler for Firebase Cloud Messaging
/// This function must be a top-level function
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Handling background message: ${message.messageId}');

  // Initialize local notifications for background handling
  final localNotifications = FlutterLocalNotificationsPlugin();
  
  const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const iosSettings = DarwinInitializationSettings();
  const initSettings = InitializationSettings(
    android: androidSettings,
    iOS: iosSettings,
  );

  await localNotifications.initialize(initSettings);

  // Show notification based on message type
  await _showBackgroundNotification(localNotifications, message);
}

/// Show notification for background messages
Future<void> _showBackgroundNotification(
  FlutterLocalNotificationsPlugin localNotifications,
  RemoteMessage message,
) async {
  final title = message.notification?.title ?? 'StressLess VPN';
  final body = message.notification?.body ?? 'New notification';
  final type = message.data['type'] as String?;

  final channelId = _getChannelId(type);
  final importance = _getImportance(type);

  final androidDetails = AndroidNotificationDetails(
    channelId,
    _getChannelName(channelId),
    channelDescription: _getChannelDescription(channelId),
    importance: importance,
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

  await localNotifications.show(
    message.hashCode,
    title,
    body,
    notificationDetails,
    payload: jsonEncode(message.data),
  );
}

/// Get channel ID based on notification type
String _getChannelId(String? type) {
  switch (type) {
    case 'vpn_status':
      return 'vpn_notifications';
    case 'security_alert':
      return 'security_notifications';
    case 'ai_response':
      return 'ai_notifications';
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
    case 'ai_notifications':
      return 'AI Notifications';
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
    case 'ai_notifications':
      return 'AI assistant notifications';
    default:
      return 'General app notifications';
  }
}

/// Get importance level
Importance _getImportance(String? type) {
  switch (type) {
    case 'security_alert':
      return Importance.max;
    case 'vpn_status':
      return Importance.high;
    default:
      return Importance.defaultImportance;
  }
}
