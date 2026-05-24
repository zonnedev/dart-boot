import 'package:todo_app/src/models/todo.dart';
import 'package:test/test.dart';

void main() {
  group('Todo model', () {
    test('creates with defaults', () {
      final todo = Todo(id: '1', title: 'Test');
      expect(todo.completed, isFalse);
    });

    test('toJson includes all fields', () {
      final todo = Todo(id: '1', title: 'Test', completed: true);
      final json = todo.toJson();
      expect(json['id'], '1');
      expect(json['title'], 'Test');
      expect(json['completed'], true);
    });
  });
}
