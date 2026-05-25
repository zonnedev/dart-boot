// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_service.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $WeatherServiceDefinition extends BeanDefinition {
  @override
  Type get beanType => WeatherService;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

  @override
  WeatherService create(BeanContainer container) => WeatherService(
      container.get<HttpClient>(),
      container.get<BootConfig>().resolvePlaceholder(
          '\${weather.base-url:https://api.openweathermap.org/data/2.5}'));
}
