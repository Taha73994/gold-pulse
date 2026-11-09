import 'notify_stub.dart' if (dart.library.io) 'notify_native.dart' as impl;

/// واجهة موحدة للصوت والإشعارات — لها تنفيذ أصلي على أندرويد/iOS
/// ونسخة صامتة على الويب حتى لا تتعطل نسخة المتصفح.
class Notifier {
  static Future<void> init() => impl.initNotifications();

  static Future<bool> requestPermission() =>
      impl.requestNotificationPermission();

  /// هل الإشعارات مسموحة حالياً من إعدادات الهاتف؟
  static Future<bool> areEnabled() => impl.notificationsEnabled();

  static Future<void> playAlertSound() => impl.playAlertSound();

  /// فتح إعدادات البطارية/الإشعارات في الهاتف لضمان العمل في الخلفية.
  static Future<void> openBatterySettings() => impl.openBatterySettings();

  static Future<void> openNotificationSettings() =>
      impl.openNotificationSettings();

  static Future<void> showAlert({
    required int id,
    required String title,
    required String body,
    required String severity,
  }) => impl.showAlertNotification(
    id: id,
    title: title,
    body: body,
    severity: severity,
  );
}
