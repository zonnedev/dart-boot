import 'package:boot/boot.dart';
import '../models/todo.dart';
import '../services/notification_stream.dart';

part 'todo_controller.g.dart';

@Controller('/todos')
class TodoController {
  final _todos = <String, Todo>{};
  var _nextId = 1;
  final NotificationStream _notifications;

  TodoController(this._notifications);

  @Get('/')
  Future<Response> list(Request request) async {
    return Response.json(_todos.values.map((t) => t.toJson()).toList());
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');

    final id = '${_nextId++}';
    final todo = Todo(id: id, title: title);
    _todos[id] = todo;

    _notifications.notify('New todo created: ${todo.title}');

    return Response.created(todo.toJson());
  }
}
