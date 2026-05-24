import 'package:boot/boot.dart';

part 'todo.g.dart';

@Serdeable()
class Todo {
  final String id;
  final String title;
  final bool completed;

  Todo({required this.id, required this.title, this.completed = false});
}
