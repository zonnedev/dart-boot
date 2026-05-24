import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/events/todo_events.dart';
import 'package:todo_app/src/models/todo.dart';
import 'package:test/test.dart';

void main() {
  group('Events', () {
    test('creating a todo publishes TodoCreatedEvent', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoCreatedEvent>[];
        container.get<EventBus>().on<TodoCreatedEvent>((e) => events.add(e));

        await client.post('/todos/', body: {'title': 'Event test'});

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todo.title, 'Event test');
      });
    });

    test('deleting a todo publishes TodoDeletedEvent', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoDeletedEvent>[];
        container.get<EventBus>().on<TodoDeletedEvent>((e) => events.add(e));

        final createRes = await client.post('/todos/', body: {'title': 'Delete me'});
        final id = createRes.json()['id'];
        await client.delete('/todos/$id');

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todoId, id);
      });
    });

    test('EventBus.publish works directly', () async {
      await bootTest($configure, test: (client, container) async {
        final events = <TodoCreatedEvent>[];
        container.get<EventBus>().on<TodoCreatedEvent>((e) => events.add(e));

        final todo = Todo(id: '1', title: 'Direct', completed: false);
        container.get<EventBus>().publish(TodoCreatedEvent(todo));

        await Future.delayed(Duration(milliseconds: 10));
        expect(events.length, 1);
        expect(events.first.todo.title, 'Direct');
      });
    });
  });
}
