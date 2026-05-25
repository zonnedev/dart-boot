// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'weather_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $WeatherControllerDefinition extends BeanDefinition {
  @override
  get beanType => WeatherController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/weather'}),
      ];

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
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/weather'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/<city>'})
          ],
        ),
      ];
}
