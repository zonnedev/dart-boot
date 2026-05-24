// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_listener.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $EmailListenerDefinition extends BeanDefinition {
  BeanContainer? _container;
  @override
  String get typeName => 'EmailListener';

  @override
  EmailListener create(BeanContainer container) {
    _container = container;
    return EmailListener();
  }

  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    final bus = _container!.get<EventBus>();
    bus.on<TodoCreatedEvent>((instance as EmailListener).onTodoCreated);
  }
}
