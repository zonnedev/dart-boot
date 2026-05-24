import 'package:boot_test/boot_test.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/models/todo.dart';
import 'package:todo_app/src/repositories/todo_repository.dart';
import 'package:test/test.dart';

class FakeTodoRepository implements TodoRepository {
  final _todos = <String, Todo>{};
  var _nextId = 1;

  @override
  Future<void> init() async {}

  @override
  Future<List<Todo>> findAll() async => _todos.values.toList();

  @override
  Future<Todo?> findById(String id) async => _todos[id];

  @override
  Future<Todo> create(String title) async {
    final id = '${_nextId++}';
    final todo = Todo(id: id, title: title);
    _todos[id] = todo;
    return todo;
  }

  @override
  Future<bool> delete(String id) async => _todos.remove(id) != null;
}

void main() {
  group('TodoController (unit test, no DB)', () {
    test('creates and lists todos', () async {
      await bootTest($configure, properties: {
        'pg.host': 'fake',
      }, overrides: (container) {
        container.override<TodoRepository>(FakeTodoRepository());
      }, test: (client, container) async {
        final res = await client.post('/todos/', body: {'title': 'Unit test'});
        res.expectStatus(201);

        final list = await client.get('/todos/');
        list.expectStatus(200);
        expect(list.jsonList().length, 1);
      });
    });

    test('get by id works', () async {
      await bootTest($configure, properties: {
        'pg.host': 'fake',
      }, overrides: (container) {
        container.override<TodoRepository>(FakeTodoRepository());
      }, test: (client, container) async {
        final createRes = await client.post('/todos/', body: {'title': 'Test'});
        final id = createRes.json()['id'];

        final res = await client.get('/todos/$id');
        res.expectStatus(200);
        expect(res.json()['title'], 'Test');
      });
    });

    test('delete works', () async {
      await bootTest($configure, properties: {
        'pg.host': 'fake',
      }, overrides: (container) {
        container.override<TodoRepository>(FakeTodoRepository());
      }, test: (client, container) async {
        final createRes = await client.post('/todos/', body: {'title': 'Delete me'});
        final id = createRes.json()['id'];

        final deleteRes = await client.delete('/todos/$id');
        deleteRes.expectStatus(204);

        final getRes = await client.get('/todos/$id');
        getRes.expectStatus(404);
      });
    });

    test('validation error returns 400', () async {
      await bootTest($configure, properties: {
        'pg.host': 'fake',
      }, overrides: (container) {
        container.override<TodoRepository>(FakeTodoRepository());
      }, test: (client, container) async {
        final res = await client.post('/todos/', body: {});
        res.expectStatus(400);
      });
    });
  });
}
