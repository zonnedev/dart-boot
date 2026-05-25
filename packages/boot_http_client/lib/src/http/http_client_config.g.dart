// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'http_client_config.dart';

// **************************************************************************
// BeanDefinitionGenerator
// **************************************************************************

class $HttpClientConfigDefinition extends BeanDefinition {
  @override
  get beanType => HttpClientConfig;

  @override
  List<AnnotationValue> get annotationMetadata => const [
        const AnnotationValue(
            AnnotationType(
                'package:boot_core/src/annotations/configuration_properties.dart#ConfigurationProperties'),
            {'prefix': 'boot.http.client'}),
      ];

  @override
  HttpClientConfig create(BeanContainer container) => HttpClientConfig(
      connectTimeout: parseDurationOrNull(container
              .get<BootConfig>()
              .get('boot.http.client.connect-timeout')) ??
          const Duration(seconds: 5),
      readTimeout: parseDurationOrNull(container
              .get<BootConfig>()
              .get('boot.http.client.read-timeout')) ??
          const Duration(seconds: 30),
      maxRedirects: int.tryParse(container
                  .get<BootConfig>()
                  .get('boot.http.client.max-redirects') ??
              '') ??
          5);
}
