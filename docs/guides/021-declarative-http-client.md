# Guide 021: Declarative HTTP Client

## What you'll build

A service that consumes an external REST API using Boot's `@Client` annotation — no manual HTTP calls, just an interface.

## What you'll learn

- How to define a declarative HTTP client with `@Client`
- How the generator produces the implementation at compile time
- How to inject and use the client in controllers
- How to test with a mock server using `bootTest`

## Prerequisites

- Completed [Guide 001](001-build-a-rest-api.md)

---

## Step 1: Add dependencies

**`pubspec.yaml`**

```yaml
dependencies:
  boot: ^0.1.0
  boot_http_client: ^0.1.0

dev_dependencies:
  boot_generator: ^0.1.0
  boot_http_client_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
  test: ^1.25.0
```

`boot_http_client` provides the `@Client` annotation and `HttpClient` runtime. `boot_http_client_generator` generates the implementation at compile time.

---

## Step 2: Configure the service URL

**`application.yml`**

```yaml
boot:
  env: dev
  http:
    services:
      jsonplaceholder:
        url: https://jsonplaceholder.typicode.com
```

The `name` in `@Client(name: 'jsonplaceholder')` maps to this config key.

---

## Step 3: Define the client interface

**`lib/src/clients/post_client.dart`**

```dart
import 'package:boot/boot.dart';
import 'package:boot_http_client/boot_http_client.dart';

part 'post_client.g.dart';

@Client(name: 'jsonplaceholder', path: '/posts')
abstract class PostClient {
  @Get('/')
  Future<List<Map<String, dynamic>>> list();

  @Get('/<id>')
  Future<Map<String, dynamic>> getById(@PathParam() String id);

  @Post('/')
  Future<Map<String, dynamic>> create(@Body() Map<String, dynamic> post);
}
```

**What's happening:**
- `@Client(name: 'jsonplaceholder')` — resolves the base URL from config
- `path: '/posts'` — appended to the base URL for all methods
- `@Get`, `@Post` — same annotations as controllers, but here they define outgoing requests
- `@PathParam`, `@Body` — same parameter annotations, used to build the request

The generator produces `$PostClientImpl` with real HTTP calls and `$PostClientDefinition` for DI registration.

---

## Step 4: Use the client in a controller

**`lib/src/controllers/post_controller.dart`**

```dart
import 'package:boot/boot.dart';
import '../clients/post_client.dart';

part 'post_controller.g.dart';

@Controller('/posts')
class PostController {
  final PostClient _client;

  PostController(this._client);

  @Get('/')
  Future<Response> list(Request request) async {
    final posts = await _client.list();
    return Response.json(posts.take(5).toList());
  }

  @Get('/<id>')
  Future<Response> getById(Request request, @PathParam() String id) async {
    final post = await _client.getById(id);
    return Response.json(post);
  }

  @Post('/')
  Future<Response> create(Request request) async {
    final body = await request.json();
    final created = await _client.create(body);
    return Response.created(created);
  }
}
```

`PostClient` is injected automatically — the framework registered it via `@BeanSource`.

---

## Step 5: Build and run

```bash
boot build
boot serve
```

```bash
curl http://localhost:8080/posts/1
# → {"id": 1, "title": "...", ...}
```

---

## Step 6: Write tests with a mock server

**`test/client_test.dart`**

```dart
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
  final String typeName;
  _Def(this.typeName, this._factory);
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
            {'id': 1, 'title': 'First Post'},
            {'id': 2, 'title': 'Second Post'},
          ]));
      } else if (req.method == 'GET' && path.startsWith('/posts/')) {
        final id = path.split('/').last;
        req.response
          ..statusCode = 200
          ..headers.contentType = ContentType.json
          ..write(jsonEncode({'id': int.parse(id), 'title': 'Post $id'}));
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
    c.container.registerNamed<HttpClientBuilder>(
      'jsonplaceholder',
      _Def('HttpClientBuilder', (_) => HttpClientBuilder().baseUrl(mockBaseUrl)),
    );
  }

  group('@Client integration', () {
    test('PostClient.list() returns posts', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final postClient = container.get<PostClient>();
        final posts = await postClient.list();
        expect(posts, hasLength(2));
        expect(posts[0]['title'], 'First Post');
      });
    });

    test('controller proxies through @Client bean', () async {
      await bootTest($configure, overrides: registerMockClient, test: (client, container) async {
        final res = await client.get('/posts/1');
        res.expectStatus(200);
        expect(res.json()['title'], 'Post 1');
      });
    });
  });
}
```

**Key testing pattern:**
- Start a local `HttpServer` as a mock
- Register a named `HttpClientBuilder` pointing to the mock URL
- `bootTest` wires everything — the `@Client` bean resolves the named builder and makes real HTTP calls to your mock

```bash
boot test
```

---

## Step 7: Using URL-based clients (alternative)

If you don't need config-driven URLs:

```dart
@Client(url: 'https://api.github.com', path: '/repos')
abstract class GitHubClient {
  @Get('/<owner>/<repo>')
  Future<Map<String, dynamic>> getRepo(
    @PathParam() String owner,
    @PathParam() String repo,
  );
}
```

This hardcodes the URL — useful for third-party APIs that never change.

---

## What you've learned

- `@Client(name: 'x')` — URL from `boot.http.services.x.url` in config
- `@Client(url: 'https://...')` — inline URL
- Same annotations as controllers (`@Get`, `@Post`, `@PathParam`, `@Body`)
- Generator produces the implementation — you write only the interface
- Test by registering a named `HttpClientBuilder` pointing to a mock server
- `@BeanSource` meta-annotation enables automatic bean registration without the core generator knowing about `@Client`

## Next steps

- [Guide 003: Add Authentication](003-add-authentication.md) — protect your endpoints with JWT
