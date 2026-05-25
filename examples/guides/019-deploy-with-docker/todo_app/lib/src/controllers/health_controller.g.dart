// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'health_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $HealthControllerDefinition extends BeanDefinition {
  @override
  Type get beanType => HealthController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/health'}),
      ];

  @override
  HealthController create(BeanContainer container) => HealthController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $HealthControllerRoutes implements RouteRegistration {
  final HealthController controller;
  $HealthControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/health/',
          handler: (request) async {
            return await controller.health(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/health'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/'})
          ],
        ),
      ];
}
