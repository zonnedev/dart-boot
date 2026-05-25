// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $PostControllerDefinition extends BeanDefinition {
  @override
  Type get beanType => PostController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/posts'}),
      ];

  @override
  PostController create(BeanContainer container) =>
      PostController(container.get<PostClient>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $PostControllerRoutes implements RouteRegistration {
  final PostController controller;
  $PostControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/posts/',
          handler: (request) async {
            return await controller.list(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/posts'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/'})
          ],
        ),
        RouteEntry(
          method: 'GET',
          path: '/posts/<id>',
          handler: (request) async {
            final id = request.pathParams['id']!;
            return await controller.getById(request, id);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/posts'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/<id>'})
          ],
        ),
        RouteEntry(
          method: 'POST',
          path: '/posts/',
          handler: (request) async {
            return await controller.create(request);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/posts'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Post'),
                {'path': '/'})
          ],
        ),
      ];
}
