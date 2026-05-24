// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_controller.dart';

// **************************************************************************
// ControllerBeanGenerator
// **************************************************************************

class $ProductControllerDefinition extends BeanDefinition {
  @override
  String get typeName => 'ProductController';

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
        ),
      ];
}
