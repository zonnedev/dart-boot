import 'package:boot/boot.dart';
import '../models/todo.dart';

part 'todo_controller.g.dart';

@Controller('/todos')
class TodoController {
  final _todos = <String, Todo>{};
  var _nextId = 1;

  @Get('/')
  Future<Response> list(Request request) async {
    return Response.json(_todos.values.map((t) => t.toJson()).toList());
  }

  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final todo = _todos[id];
    if (todo == null) throw NotFoundException('Todo $id not found');
    return Response.json(todo.toJson());
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');
    final id = '${_nextId++}';
    final todo = Todo(id: id, title: title);
    _todos[id] = todo;
    return Response.created(todo.toJson());
  }

  @Delete('/<id>')
  Future<Response> delete(Request request, @PathParam() String id) async {
    if (!_todos.containsKey(id)) throw NotFoundException('Todo $id not found');
    _todos.remove(id);
    return Response.noContent();
  }
}
