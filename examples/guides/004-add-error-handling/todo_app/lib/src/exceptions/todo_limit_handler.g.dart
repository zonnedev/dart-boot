// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'todo_limit_handler.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $TodoLimitHandlerDefinition extends BeanDefinition {
  @override
  Type get beanType => TodoLimitHandler;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
        const AnnotationValue(
            AnnotationType(
                'package:boot_http_common/src/http/exception_handler.dart#ExceptionHandler'),
            {'handledType': TodoLimitException}),
      ];

  @override
  TodoLimitHandler create(BeanContainer container) => TodoLimitHandler();
}
