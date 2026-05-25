// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'email_listener.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $EmailListenerDefinition extends BeanDefinition {
  @override
  Type get beanType => EmailListener;

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
      ];

  @override
  dynamic dispatch(Object instance, String method, List<dynamic> args) {
    final bean = instance as EmailListener;
    switch (method) {
      case 'onTodoCreated':
        return bean.onTodoCreated(args[0] as TodoCreatedEvent);
      default:
        return super.dispatch(instance, method, args);
    }
  }

  @override
  EmailListener create(BeanContainer container) => EmailListener();
}
