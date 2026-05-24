// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_listener.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $AnalyticsListenerDefinition extends BeanDefinition {
  BeanContainer? _container;
  @override
  String get typeName => 'AnalyticsListener';

  @override
  AnalyticsListener create(BeanContainer container) {
    _container = container;
    return AnalyticsListener();
  }

  @override
  bool get hasPostConstruct => true;
  @override
  void postConstruct(dynamic instance) {
    final bus = _container!.get<EventBus>();
    bus.on<TodoCreatedEvent>((instance as AnalyticsListener).onTodoCreated);
    bus.on<TodoDeletedEvent>((instance as AnalyticsListener).onTodoDeleted);
  }
}
