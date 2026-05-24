import 'package:boot/boot.dart';
import '../events/todo_events.dart';

part 'analytics_listener.g.dart';

@Singleton()
class AnalyticsListener {
  static final _log = Logger('AnalyticsListener');

  @EventListener()
  void onTodoCreated(TodoCreatedEvent event) {
    _log.info('Tracking: todo_created', {'title': event.todo.title});
  }

  @EventListener()
  void onTodoDeleted(TodoDeletedEvent event) {
    _log.info('Tracking: todo_deleted', {'id': event.todoId});
  }
}
