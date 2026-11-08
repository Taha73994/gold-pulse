import 'notify_stub.dart' if (dart.library.io) 'notify_native.dart' as impl;

/// واجهة موحدة للصوت والإشعارات — لها تنفيذ أصلي على أندرويد/iOS
/// ونسخة صامتة على الويب حتى لا تتعطل نسخة المتصفح.
class Notifier {
  static Future<void> init() => impl.initNotifications();

  static Future<bool> requestPermission() =>
      impl.requestNotificationPermission();

  static Future<void> playAlertSound() => impl.playAlertSound();

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
