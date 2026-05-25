// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_service.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $ProductServiceDefinition extends BeanDefinition {
  @override
  Type get beanType => ProductService;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/singleton.dart#Singleton'),
            {'typed': []}),
      ];

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
        ..._$container.getInterceptors(Cached)
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
  Type get beanType => ProductService;

  @override
  ProductService create(BeanContainer container) => $ProductService$Proxy(
        container,
      );
}
