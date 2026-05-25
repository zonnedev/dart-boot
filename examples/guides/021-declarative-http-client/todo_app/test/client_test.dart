import 'dart:convert';
import 'dart:io';

import 'package:boot_test/boot_test.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:boot_core/boot_core.dart';
import 'package:todo_app/src/generated/boot_context.g.dart';
import 'package:todo_app/src/clients/post_client.dart';
import 'package:test/test.dart';

class _Def extends BeanDefinition {
  final dynamic Function(BeanContainer) _factory;
  @override
  final Type beanType;
  _Def(this.beanType, this._factory);
  @override
  dynamic create(BeanContainer container) => _factory(container);
}

void main() {
  late HttpServer mockServer;
  late String mockBaseUrl;

  setUp(() async {
    mockServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    mockBaseUrl = 'http://localhost:${mockServer.port}';
    mockServer.listen((req) async {
      final path = req.uri.path;
      if (req.method == 'GET' && path == '/posts/') {
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode([
            {'id': 1, 'title': 'First Post', 'body': 'Hello'},
            {'id': 2, 'title': 'Second Post', 'body': 'World'},
          ]));
      } else if (req.method == 'GET' && path.startsWith('/posts/')) {
        final id = path.split('/').last;
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'id': int.parse(id), 'title': 'Post $id', 'body': 'Content'}));
      } else if (req.method == 'POST' && path == '/posts/') {
        final body = jsonDecode(await utf8.decoder.bind(req).join());
        req.response
          ..statusCode = 201
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({...body, 'id': 101}));
      } else {
        req.response.statusCode = 404;
      }
      await req.response.close();
    });
  });

  tearDown(() async {
    await mockServer.close(force: true);
  });

  void registerMockClient(TestContainer c) {
    c.overrideNamed<HttpClientServiceConfig>(
      'jsonplaceholder',
      _Def(HttpClientServiceConfig, (_) => HttpClientServiceConfig(url: mockBaseUrl)),
    );
  }

  group('@Client integration', () {
    test('PostClient is registered as a bean', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final postClient = container.get<PostClient>();
        expect(postClient, isNotNull);
      });
    });

    test('PostClient.list() returns posts', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final postClient = container.get<PostClient>();
        final posts = await postClient.list();
        expect(posts, hasLength(2));
        expect(posts[0]['title'], 'First Post');
      });
    });

    test('PostClient.getById() returns a single post', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final postClient = container.get<PostClient>();
        final post = await postClient.getById('42');
        expect(post['id'], 42);
        expect(post['title'], 'Post 42');
      });
    });

    test('PostClient.create() sends POST and returns created', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final postClient = container.get<PostClient>();
        final created = await postClient.create({'title': 'New', 'body': 'Content'});
        expect(created['id'], 101);
        expect(created['title'], 'New');
      });
    });

    test('controller GET /posts/ proxies through @Client bean', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final res = await client.get('/posts/');
        res.expectStatus(200);
        final body = res.jsonList();
        expect(body, hasLength(2));
      });
    });

    test('controller GET /posts/<id> works', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final res = await client.get('/posts/7');
        res.expectStatus(200);
        expect(res.json()['id'], 7);
      });
    });

    test('controller POST /posts/ creates via client', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final res = await client.post('/posts/', body: {'title': 'Test', 'body': 'Body'});
        res.expectStatus(201);
        expect(res.json()['id'], 101);
      });
    });
  });
}
