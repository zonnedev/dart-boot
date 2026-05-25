// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'timing_filter.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $TimingFilterDefinition extends BeanDefinition {
  @override
  get beanType => TimingFilter;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http_common/src/http/filter.dart#ServerFilter'),
            {'pattern': '/**', 'methods': []}),
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/order.dart#Order'),
            {'value': 2}),
      ];

  @override
  TimingFilter create(BeanContainer container) => TimingFilter();
}
