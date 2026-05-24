import 'package:boot/boot.dart';
import 'todo_limit_exception.dart';

part 'todo_limit_handler.g.dart';

@Singleton()
class TodoLimitHandler implements ExceptionHandler<TodoLimitException> {
  @override
  Response handle(Request request, TodoLimitException e) {
    return Response(429,
      headers: {'content-type': 'application/json'},
      body: '{"error": "Todo limit reached", "current": ${e.currentCount}, "max": ${e.maxAllowed}}',
    );
  }
}
