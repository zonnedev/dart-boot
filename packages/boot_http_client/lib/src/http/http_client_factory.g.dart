// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client_factory.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $HttpClientFactoryDefinition extends BeanDefinition {
  @override
  get beanType => HttpClientFactory;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(AnnotationType(
            'package:boot_core/src/annotations/factory.dart#Factory')),
      ];

  @override
  HttpClientFactory create(BeanContainer container) => HttpClientFactory();
}

// **************************************************************************
// FactoryGenerator
// **************************************************************************

class $HttpClientFactory_httpClientDefinition extends BeanDefinition {
  @override
  Type get beanType => HttpClient;

  @override
  HttpClient create(BeanContainer container) {
    final factory = container.get<HttpClientFactory>();
    return factory.httpClient(container.get<HttpClientConfig>());
  }
}
