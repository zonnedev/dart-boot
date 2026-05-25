// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_limit_filter.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $RateLimitFilterDefinition extends BeanDefinition {
  @override
  Type get beanType => RateLimitFilter;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http_common/src/http/filter.dart#ServerFilter'),
            {'pattern': '/**', 'methods': []}),
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/order.dart#Order'),
            {'value': 0}),
      ];

  @override
  RateLimitFilter create(BeanContainer container) => RateLimitFilter(int.parse(
      container.get<BootConfig>().resolvePlaceholder('\${rate-limit.max:60}')));
}
