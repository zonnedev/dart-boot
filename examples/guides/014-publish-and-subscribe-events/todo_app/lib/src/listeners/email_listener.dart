import 'package:boot/boot.dart';
import '../events/todo_events.dart';

part 'email_listener.g.dart';

@Singleton()
class EmailListener {
  static final _log = Logger('EmailListener');

  @EventListener()
  void onTodoCreated(TodoCreatedEvent event) {
    _log.info('Sending email notification for: ${event.todo.title}');
  }
}
