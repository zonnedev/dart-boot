import 'dart:async';
import 'package:boot/boot.dart';

part 'notification_stream.g.dart';

@Singleton()
class NotificationStream {
  final _controller = StreamController<String>.broadcast();

  void notify(String message) => _controller.add(message);

  Stream<String> get stream => _controller.stream;
}
