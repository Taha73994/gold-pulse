/// نسخة الويب: لا صوت نظام ولا إشعارات خلفية (المتصفح يمنعهما).
Future<void> initNotifications() async {}

Future<bool> requestNotificationPermission() async => false;

Future<bool> notificationsEnabled() async => false;

Future<void> playAlertSound() async {}

Future<void> showAlertNotification({
  required int id,
  required String title,
  required String body,
  required String severity,
}) async {}
