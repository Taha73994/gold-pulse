import 'package:flutter/services.dart';

/// جسر بسيط إلى كود Android الأصلي (بدون إضافات Gradle ثقيلة):
/// - تشغيل نغمة تنبيه مخصصة من res/raw/gold_alert
/// - إظهار إشعار نظام مع صورة كبيرة ونغمة
/// - طلب صلاحية POST_NOTIFICATIONS على أندرويد 13+
const MethodChannel _channel = MethodChannel('iq.goldpulse/notify');

Future<void> initNotifications() async {
  try {
    await _channel.invokeMethod<int>('init');
  } catch (_) {}
}

Future<bool> requestNotificationPermission() async {
  try {
    final result = await _channel.invokeMethod<bool>('requestPermission');
    return result ?? false;
  } catch (_) {
    return false;
  }
}

Future<bool> notificationsEnabled() async {
  try {
    final result = await _channel.invokeMethod<bool>('status');
    return result ?? false;
  } catch (_) {
    return false;
  }
}

Future<void> playAlertSound() async {
  try {
    await _channel.invokeMethod<bool>('playSound');
  } catch (_) {}
}

Future<void> showAlertNotification({
  required int id,
  required String title,
  required String body,
  required String severity,
}) async {
  try {
    await _channel.invokeMethod<bool>('showAlert', {
      'id': id,
      'title': title,
      'body': body,
      'severity': severity,
    });
  } catch (_) {}
}
