// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_service.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $WeatherServiceDefinition extends BeanDefinition {
  @override
  String get typeName => 'WeatherService';

  @override
  WeatherService create(BeanContainer container) => WeatherService(
      container.get<HttpClient>(),
      container.get<BootConfig>().resolvePlaceholder(
          '\${weather.base-url:https://api.openweathermap.org/data/2.5}'));
}
