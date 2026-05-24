// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rate_limit_filter.dart';

// **************************************************************************
// ServerFilterBeanGenerator
// **************************************************************************

class $RateLimitFilterDefinition extends BeanDefinition {
  @override
  String get typeName => 'RateLimitFilter';

  @override
  RateLimitFilter create(BeanContainer container) => RateLimitFilter(
    int.parse(
      container.get<BootConfig>().resolvePlaceholder('\${rate-limit.max:60}'),
    ),
  );
}
