// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hello_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $HelloControllerDefinition extends BeanDefinition {
  @override
  get beanType => HelloController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/hello'}),
      ];

  @override
  HelloController create(BeanContainer container) => HelloController();
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $HelloControllerRoutes implements RouteRegistration {
  final HelloController controller;
  $HelloControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/hello/',
          handler: (request) async {
            return await controller.hello(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/hello'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/'})
          ],
        ),
        RouteEntry(
          method: 'GET',
          path: '/hello/<name>',
          handler: (request) async {
            final name = request.pathParams['name']!;
            return await controller.greet(request, name);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/hello'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/<name>'})
          ],
        ),
      ];
}
