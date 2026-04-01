import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/subscription.dart';

class NotificationHelper {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
        macOS: darwinSettings,
      ),
    );
  }

  static Future<void> requestPermissions() async {
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  static Future<void> showInstantNotification({
    required String title,
    required String body,
    int id = 0,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'kill_switch_channel',
      'Kill Switch Alerts',
      channelDescription: 'Subscription alerts and reminders',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: darwinDetails,
    );

    await _plugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  static Future<void> showKillConfirmation(Subscription sub) async {
    await showInstantNotification(
      id: sub.id.hashCode,
      title: '🎯 Subscription Neutralized!',
      body:
          '${sub.name} has been killed. You\'ll save ${sub.currency}${sub.price.toStringAsFixed(0)}/month.',
    );
  }

  static Future<void> showTrialWarning(Subscription sub) async {
    await showInstantNotification(
      id: sub.id.hashCode + 1000,
      title: '⚠️ Trial Ending Soon!',
      body:
          '${sub.name} trial ends ${sub.renewalDate ?? "soon"}. Cancel now to avoid charges.',
    );
  }

  static Future<void> showRenewalReminder(Subscription sub) async {
    await showInstantNotification(
      id: sub.id.hashCode + 2000,
      title: '🔔 Upcoming Renewal',
      body:
          '${sub.name} will charge ${sub.currency}${sub.price.toStringAsFixed(0)} on ${sub.renewalDate ?? "soon"}.',
    );
  }

  static Future<void> cancelNotification(int id) async {
    await _plugin.cancel(id: id);
  }

  static Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }
}
