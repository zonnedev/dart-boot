// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_service.dart';

// **************************************************************************
// BeanGenerator
// **************************************************************************

class $ProductServiceDefinition extends BeanDefinition {
  @override
  String get typeName => 'ProductService';

  @override
  ProductService create(BeanContainer container) => ProductService();
}

// **************************************************************************
// AopProxyGenerator
// **************************************************************************

class $ProductService$Proxy extends ProductService {
  final BeanContainer _$container;

  $ProductService$Proxy(this._$container) : super();

  @override
  Future<Map<String, dynamic>> getProduct(String id) async {
    return await InterceptorChain(
      interceptors: [
        ..._$container.getInterceptors(Timed),
        ..._$container.getInterceptors(Cached),
      ],
      methodName: 'getProduct',
      args: [id],
      target: this,
      originalMethod: () => super.getProduct(id),
    ).invokeAsync();
  }
}

class $ProductService$ProxyDefinition extends BeanDefinition {
  @override
  String get typeName => 'ProductService (proxy)';

  @override
  ProductService create(BeanContainer container) =>
      $ProductService$Proxy(container);
}
