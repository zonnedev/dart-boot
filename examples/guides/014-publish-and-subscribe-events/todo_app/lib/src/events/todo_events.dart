import '../models/todo.dart';

class TodoCreatedEvent {
  final Todo todo;
  final DateTime timestamp;
  TodoCreatedEvent(this.todo) : timestamp = DateTime.now();
}

class TodoDeletedEvent {
  final String todoId;
  final DateTime timestamp;
  TodoDeletedEvent(this.todoId) : timestamp = DateTime.now();
}
