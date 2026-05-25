// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_controller.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $ProductControllerDefinition extends BeanDefinition {
  @override
  get beanType => ProductController;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_http/src/annotations/controller.dart#Controller'),
            {'path': '/products'}),
      ];

  @override
  ProductController create(BeanContainer container) =>
      ProductController(container.get<ProductService>());
}

// **************************************************************************
// ControllerGenerator
// **************************************************************************

class $ProductControllerRoutes implements RouteRegistration {
  final ProductController controller;
  $ProductControllerRoutes(this.controller);

  @override
  List<RouteEntry> get routes => [
        RouteEntry(
          method: 'GET',
          path: '/products/<id>',
          handler: (request) async {
            final id = request.pathParams['id']!;
            return await controller.get(request, id);
          },
          metadata: [
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/controller.dart#Controller'),
                {'path': '/products'}),
            const AnnotationValue(
                AnnotationType(
                    'package:boot_http/src/annotations/routes.dart#Get'),
                {'path': '/<id>'})
          ],
        ),
      ];
}
