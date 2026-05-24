import 'package:boot/boot.dart';
import '../db/database.dart';
import '../models/todo.dart';

part 'todo_repository.g.dart';

@Singleton()
@Requires(property: 'pg.host')
class TodoRepository {
  final Database _db;

  TodoRepository(this._db);

  @PostConstruct()
  Future<void> init() async {
    await _db.query('''
      CREATE TABLE IF NOT EXISTS todos (
        id SERIAL PRIMARY KEY,
        title TEXT NOT NULL,
        completed BOOLEAN NOT NULL DEFAULT false
      )
    ''');
  }

  Future<List<Todo>> findAll() async {
    final rows = await _db.queryRows('SELECT id, title, completed FROM todos ORDER BY id');
    return rows.map((r) => Todo(
      id: r['id'].toString(),
      title: r['title'] as String,
      completed: r['completed'] as bool,
    )).toList();
  }

  Future<Todo?> findById(String id) async {
    final rows = await _db.queryRows(
      'SELECT id, title, completed FROM todos WHERE id = @id',
      params: {'id': int.parse(id)},
    );
    if (rows.isEmpty) return null;
    final r = rows.first;
    return Todo(id: r['id'].toString(), title: r['title'] as String, completed: r['completed'] as bool);
  }

  Future<Todo> create(String title) async {
    final rows = await _db.queryRows(
      'INSERT INTO todos (title) VALUES (@title) RETURNING id, title, completed',
      params: {'title': title},
    );
    final r = rows.first;
    return Todo(id: r['id'].toString(), title: r['title'] as String, completed: r['completed'] as bool);
  }

  Future<bool> delete(String id) async {
    final result = await _db.query(
      'DELETE FROM todos WHERE id = @id',
      params: {'id': int.parse(id)},
    );
    return result.affectedRows > 0;
  }
}
