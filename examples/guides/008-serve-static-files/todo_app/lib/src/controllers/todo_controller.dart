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
}
