// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $WeatherControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'WeatherController';

  @override
  WeatherController create(BeanContainer container) =>
      WeatherController(container.get<WeatherService>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $WeatherControllerRoutes implements RouteRegistration {
  final WeatherController controller;
  $WeatherControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
    RouteEntry(
      method: 'GET',
      path: '/weather/<city>',
      handler: (request) async {
        final city = request.pathParams['city']!;
        return await controller.getWeather(request, city);
      },
    ),
  ];
}
