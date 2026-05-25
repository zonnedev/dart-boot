// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_dispatcher.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $NotificationDispatcherDefinition extends BeanDefinition {
  @override
  Type get beanType => NotificationDispatcher;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  NotificationDispatcher create(BeanContainer container) =>
      NotificationDispatcher(container.get<BeanContainer>());
}
