// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'post_client.dart';

// **************************************************************************
// ClientGenerator
// **************************************************************************

class $PostClientImpl implements PostClient {
  final HttpClient _client;
  final String _baseUrl;

  $PostClientImpl(BeanContainer container)
      : _client = container.hasNamed<HttpClient>('jsonplaceholder')
            ? container.getNamed<HttpClient>('jsonplaceholder')
            : container.hasNamed<HttpClientBuilder>('jsonplaceholder')
                ? container
                    .getNamed<HttpClientBuilder>('jsonplaceholder')
                    .build()
                : HttpClientBuilder.fromConfig(container
                        .getNamed<HttpClientServiceConfig>('jsonplaceholder'))
                    .build(),
        _baseUrl = '/posts';

  @override
  Future<List<Map<String, dynamic>>> list() async {
    final response = await _client.send(
      'GET',
      '$_baseUrl/',
    );
    return List<Map<String, dynamic>>.from(response.jsonList);
  }

  @override
  Future<Map<String, dynamic>> getById(String id) async {
    final response = await _client.send(
      'GET',
      '$_baseUrl/${id}',
    );
    return response.json;
  }

  @override
  Future<Map<String, dynamic>> create(Map<String, dynamic> post) async {
    final response = await _client.send(
      'POST',
      '$_baseUrl/',
      body: post,
    );
    return response.json;
  }
}

class $PostClientDefinition extends BeanDefinition {
  @override
  Type get beanType => PostClient;

  @override
  PostClient create(BeanContainer container) => $PostClientImpl(container);
}
