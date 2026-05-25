// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics_listener.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $AnalyticsListenerDefinition extends BeanDefinition {
  @override
  Type get beanType => AnalyticsListener;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  List<MethodMetadata> get methodMetadata => const [
        MethodMetadata('onTodoCreated', [
          const AnnotationValue(AnnotationType(
              'package:boot_events/src/annotations/event_listener.dart#EventListener'))
        ], [
          TodoCreatedEvent
        ]),
        MethodMetadata('onTodoDeleted', [
          const AnnotationValue(AnnotationType(
              'package:boot_events/src/annotations/event_listener.dart#EventListener'))
        ], [
          TodoDeletedEvent
        ]),
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as AnalyticsListener;
    switch (method) {
      case 'onTodoCreated':
        return bean.onTodoCreated(args[0] as TodoCreatedEvent);
      case 'onTodoDeleted':
        return bean.onTodoDeleted(args[0] as TodoDeletedEvent);
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  AnalyticsListener create(BeanContainer container) => AnalyticsListener();
}
