import 'dart:convert';
import 'dart:io' as io;

import 'package:boot_core/boot_core.dart';
import 'package:boot_http_common/boot_http_common.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClientConfiguration', () {
    test('defaults', () {
      final config = HttpClientConfiguration();
      expect(config.connectTimeout, Duration(seconds: 5));
      expect(config.readTimeout, Duration(seconds: 30));
      expect(config.maxRedirects, 5);
    });

    test('custom values', () {
      final config = HttpClientConfiguration(
        connectTimeout: Duration(seconds: 10),
        readTimeout: Duration(minutes: 1),
        maxRedirects: 3,
      );
      expect(config.connectTimeout, Duration(seconds: 10));
      expect(config.readTimeout, Duration(minutes: 1));
      expect(config.maxRedirects, 3);
    });

    test('fromConfig reads BootConfig properties', () {
      final bootConfig = BootConfig(properties: {
        'boot.http.client.connect-timeout': '10s',
        'boot.http.client.read-timeout': '500ms',
        'boot.http.client.max-redirects': '2',
      });
      final config = HttpClientConfiguration.fromConfig(bootConfig);
      expect(config.connectTimeout, Duration(seconds: 10));
      expect(config.readTimeout, Duration(milliseconds: 500));
      expect(config.maxRedirects, 2);
    });

    test('fromConfig uses defaults for missing properties', () {
      final bootConfig = BootConfig();
      final config = HttpClientConfiguration.fromConfig(bootConfig);
      expect(config.connectTimeout, Duration(seconds: 5));
      expect(config.readTimeout, Duration(seconds: 30));
      expect(config.maxRedirects, 5);
    });
  });

  group('HttpClientBuilder', () {
    test('builds with defaults', () {
      final client = HttpClientBuilder().build();
      expect(client.baseUrl, isNull);
      expect(client.readTimeout, Duration(seconds: 30));
      expect(client.maxRedirects, 5);
      client.close();
    });

    test('fluent API configures all fields', () {
      final client = HttpClientBuilder()
          .baseUrl('http://api.example.com')
          .connectTimeout(Duration(seconds: 2))
          .readTimeout(Duration(seconds: 10))
          .maxRedirects(3)
          .followRedirects(false)
          .defaultHeader('X-Api-Key', 'secret')
          .build();
      expect(client.baseUrl, 'http://api.example.com');
      expect(client.readTimeout, Duration(seconds: 10));
      expect(client.maxRedirects, 3);
      expect(client.followRedirects, isFalse);
      expect(client.defaultHeaders['X-Api-Key'], 'secret');
      client.close();
    });

    test('fromConfig pre-loads from configuration', () {
      final config = HttpClientServiceConfig(
        url: 'http://svc.local',
        connectTimeout: Duration(seconds: 3),
        readTimeout: Duration(seconds: 15),
        maxRedirects: 2,
      );
      final client = HttpClientBuilder.fromConfig(config).build();
      expect(client.baseUrl, 'http://svc.local');
      expect(client.readTimeout, Duration(seconds: 15));
      expect(client.maxRedirects, 2);
      client.close();
    });
  });

  group('ClientResponse', () {
    test('isSuccess for 2xx', () {
      expect(ClientResponse(statusCode: 200, body: '', headers: {}).isSuccess, isTrue);
      expect(ClientResponse(statusCode: 201, body: '', headers: {}).isSuccess, isTrue);
      expect(ClientResponse(statusCode: 299, body: '', headers: {}).isSuccess, isTrue);
    });

    test('isSuccess false for non-2xx', () {
      expect(ClientResponse(statusCode: 400, body: '', headers: {}).isSuccess, isFalse);
      expect(ClientResponse(statusCode: 500, body: '', headers: {}).isSuccess, isFalse);
    });

    test('json parses body', () {
      final res = ClientResponse(statusCode: 200, body: '{"key":"val"}', headers: {});
      expect(res.json['key'], 'val');
    });

    test('jsonList parses array body', () {
      final res = ClientResponse(statusCode: 200, body: '[1,2,3]', headers: {});
      expect(res.jsonList, [1, 2, 3]);
    });
  });

  group('Client exceptions', () {
    test('HttpClientException', () {
      final e = HttpClientException('timeout', Uri.parse('http://x.com/api'));
      expect(e.message, 'timeout');
      expect(e.uri.host, 'x.com');
      expect(e.toString(), contains('timeout'));
      expect(e.toString(), contains('x.com'));
    });

    test('HttpClient4xxException', () {
      final e = HttpClient4xxException(Uri.parse('http://x.com'),
          statusCode: 404, body: 'not found', headers: {'x': 'y'});
      expect(e.statusCode, 404);
      expect(e.body, 'not found');
      expect(e.headers!['x'], 'y');
    });

    test('HttpClient5xxException', () {
      final e = HttpClient5xxException(Uri.parse('http://x.com'),
          statusCode: 503, body: 'unavailable');
      expect(e.statusCode, 503);
      expect(e.body, 'unavailable');
    });
  });

  group('HttpClient with DI container', () {
    test('HttpClient as singleton in container', () {
      final container = BeanContainer();
      final client = HttpClient();
      container.overrideWithInstance<HttpClient>(client);
      expect(identical(container.get<HttpClient>(), client), isTrue);
      client.close();
    });

    test('addFilter registers runtime filters', () {
      final client = HttpClient();
      client.addFilter(_NoOpFilter());
      // No error — filter registered
      client.close();
    });

    test('HttpClientBuilder as named bean in container', () {
      final container = BeanContainer();
      final config = HttpClientServiceConfig(url: 'http://payments.local', connectTimeout: Duration(seconds: 1));
      final builder = HttpClientBuilder.fromConfig(config);

      // Simulate: container.registerNamed<HttpClientBuilder>('payments', def)
      container.overrideWithInstance<HttpClientBuilder>(builder);

      final resolved = container.get<HttpClientBuilder>();
      final client = resolved.build();
      expect(client.baseUrl, 'http://payments.local');
      client.close();
    });
  });

  group('HttpClient.send (with local server)', () {
    late io.HttpServer server;
    late String baseUrl;

    setUp(() async {
      server = await io.HttpServer.bind('127.0.0.1', 0);
      baseUrl = 'http://127.0.0.1:${server.port}';
      server.listen((req) async {
        final body = await utf8.decoder.bind(req).join();
        switch (req.uri.path) {
          case '/ok':
            req.response.statusCode = 200;
            req.response.headers.contentType = io.ContentType.json;
            req.response.write('{"status":"ok"}');
          case '/echo':
            req.response.statusCode = 200;
            req.response.headers.contentType = io.ContentType.json;
            req.response.write(body);
          case '/not-found':
            req.response.statusCode = 404;
            req.response.write('not found');
          case '/error':
            req.response.statusCode = 500;
            req.response.write('server error');
          case '/headers':
            req.response.statusCode = 200;
            req.response.write(req.headers.value('x-custom') ?? 'none');
          default:
            req.response.statusCode = 404;
        }
        await req.response.close();
      });
    });

    tearDown(() => server.close());

    test('GET returns response', () async {
      final client = HttpClient(baseUrl: baseUrl);
      final res = await client.send('GET', '/ok');
      expect(res.statusCode, 200);
      expect(res.json['status'], 'ok');
      client.close();
    });

    test('POST sends body', () async {
      final client = HttpClient(baseUrl: baseUrl);
      final res = await client.send('POST', '/echo', body: {'key': 'val'});
      expect(res.statusCode, 200);
      expect(res.json['key'], 'val');
      client.close();
    });

    test('POST sends string body', () async {
      final client = HttpClient(baseUrl: baseUrl);
      final res = await client.send('POST', '/echo', body: '{"raw":true}');
      expect(res.json['raw'], true);
      client.close();
    });

    test('default headers are sent', () async {
      final client = HttpClient(baseUrl: baseUrl, defaultHeaders: {'x-custom': 'hello'});
      final res = await client.send('GET', '/headers');
      expect(res.body, 'hello');
      client.close();
    });

    test('per-request headers override defaults', () async {
      final client = HttpClient(baseUrl: baseUrl, defaultHeaders: {'x-custom': 'default'});
      final res = await client.send('GET', '/headers', headers: {'x-custom': 'override'});
      expect(res.body, 'override');
      client.close();
    });

    test('4xx throws HttpClient4xxException', () async {
      final client = HttpClient(baseUrl: baseUrl);
      expect(
        () => client.send('GET', '/not-found'),
        throwsA(isA<HttpClient4xxException>().having((e) => e.statusCode, 'status', 404)),
      );
      client.close();
    });

    test('5xx throws HttpClient5xxException', () async {
      final client = HttpClient(baseUrl: baseUrl);
      expect(
        () => client.send('GET', '/error'),
        throwsA(isA<HttpClient5xxException>().having((e) => e.statusCode, 'status', 500)),
      );
      client.close();
    });

    test('absolute URL ignores baseUrl', () async {
      final client = HttpClient(baseUrl: 'http://wrong.host');
      final res = await client.send('GET', '$baseUrl/ok');
      expect(res.statusCode, 200);
      client.close();
    });

    test('filters are applied to requests', () async {
      final client = HttpClient(baseUrl: baseUrl);
      client.addFilter(_HeaderInjectFilter('x-custom', 'from-filter'));
      final res = await client.send('GET', '/headers');
      expect(res.body, 'from-filter');
      client.close();
    });
  });
}

class _NoOpFilter implements HttpClientFilter {
  @override
  Future<Response> filter(MutableRequest request, ClientFilterChain chain) => chain.proceed(request);
}

class _HeaderInjectFilter implements HttpClientFilter {
  final String key;
  final String value;
  _HeaderInjectFilter(this.key, this.value);

  @override
  Future<Response> filter(MutableRequest request, ClientFilterChain chain) {
    request.header(key, value);
    return chain.proceed(request);
  }
}
