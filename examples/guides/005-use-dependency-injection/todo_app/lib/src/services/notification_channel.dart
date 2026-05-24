abstract class NotificationChannel {
  String get name;
  Future<void> send(String recipient, String message);
}
