abstract class EmailService {
  Future<void> send(String to, String body);
}
