import 'package:boot/boot.dart';
import '../models/todo.dart';
import '../repositories/todo_repository.dart';

part 'todo_controller.g.dart';

@Controller('/todos')
class TodoController {
  final TodoRepository _repo;

  TodoController(this._repo);

  @Get('/')
  Future<Response> list(Request request) async {
    final todos = await _repo.findAll();
    return Response.json(todos.map((t) => t.toJson()).toList());
  }

  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final todo = await _repo.findById(id);
    if (todo == null) throw NotFoundException('Todo $id not found');
    return Response.json(todo.toJson());
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final title = body['title'] as String?;
    if (title == null || title.isEmpty) throw BadRequestException('Title is required');

    final todo = await _repo.create(title);
    return Response.created(todo.toJson());
  }

  @Delete('/<id>')
  Future<Response> delete(Request request, @PathParam() String id) async {
    final deleted = await _repo.delete(id);
    if (!deleted) throw NotFoundException('Todo $id not found');
    return Response.noContent();
  }
}
