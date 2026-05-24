// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_repository.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $TodoRepositoryDefinition extends BeanDefinition {
  @override
  String get typeName => 'TodoRepository';

  @override
  TodoRepository create(BeanContainer container) =>
      TodoRepository(container.get<Database>());
  @override
  bool get hasPostConstructAsync => true;
  @override
  Future<void> postConstructAsync(dynamic instance) async {
    await (instance as TodoRepository).init();
  }
}
