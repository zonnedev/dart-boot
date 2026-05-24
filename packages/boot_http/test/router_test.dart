import 'dart:io' as io;

import 'package:boot_core/boot_core.dart';
import 'package:boot_http/boot_http.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

void main() {
  group('BootRouter', () {
    late BootRouter router;
    setUp(() => router = BootRouter());

    test('add and build routes', () async {
      router.add(RouteEntry(method: 'GET', path: '/hello', handler: (req) async => Response.ok('hi')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/hello')));
      expect(res.statusCode, 200);
    });

    test('404 for unmatched route', () async {
      router.add(RouteEntry(method: 'GET', path: '/exists', handler: (req) async => Response.ok('yes')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/nope')));
      expect(res.statusCode, 404);
    });

    test('addFilter applies to matching routes', () async {
      router.add(RouteEntry(method: 'GET', path: '/api/data', handler: (req) async => Response.ok('data')));
      router.addFilter('/**', _AddHeaderFilter('x-filtered', 'yes'), order: 0);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/api/data')));
      expect(res.headers['x-filtered'], 'yes');
    });

    test('filters execute in order', () async {
      final order = <int>[];
      router.add(RouteEntry(method: 'GET', path: '/test', handler: (req) async => Response.ok('ok')));
      router.addFilter('/**', _OrderFilter(order, 1), order: 1);
      router.addFilter('/**', _OrderFilter(order, 0), order: 0);
      final handler = router.build();
      await handler(shelf.Request('GET', Uri.parse('http://localhost/test')));
      expect(order, [0, 1]);
    });

    test('addExceptionHandler catches typed exceptions', () async {
      router.add(RouteEntry(method: 'GET', path: '/fail', handler: (req) async => throw const NotFoundException('gone')));
      router.addExceptionHandler<NotFoundException>(_NotFoundHandler());
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/fail')));
      expect(res.statusCode, 404);
    });

    test('unhandled exception returns 500', () async {
      router.add(RouteEntry(method: 'GET', path: '/crash', handler: (req) async => throw Exception('unexpected')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/crash')));
      expect(res.statusCode, 500);
    });

    test('enableRequestLogging', () async {
      router.enableRequestLogging();
      router.add(RouteEntry(method: 'GET', path: '/x', handler: (req) async => Response.ok('x')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/x')));
      expect(res.statusCode, 200);
    });

    test('configureStackTrace', () {
      router.configureStackTrace(maxDepth: 5, include: ['package:myapp/'], exclude: ['dart:']);
      router.add(RouteEntry(method: 'GET', path: '/x', handler: (req) async => Response.ok('x')));
      router.build();
    });
  });

  group('BootRouter CORS', () {
    test('preflight OPTIONS returns 204', () async {
      final router = BootRouter();
      router.add(RouteEntry(method: 'GET', path: '/api', handler: (req) async => Response.ok('data')));
      router.enableCors(CorsConfiguration(enabled: true, allowedOrigins: ['http://localhost:3000'], allowedMethods: ['GET', 'POST'], allowedHeaders: ['Content-Type'], maxAge: 3600));
      final handler = router.build();
      final res = await handler(shelf.Request('OPTIONS', Uri.parse('http://localhost/api'),
          headers: {'origin': 'http://localhost:3000', 'access-control-request-method': 'GET'}));
      expect(res.statusCode, 204);
    });

    test('CORS adds headers to normal response', () async {
      final router = BootRouter();
      router.add(RouteEntry(method: 'GET', path: '/api', handler: (req) async => Response.ok('ok')));
      router.enableCors(CorsConfiguration(enabled: true, allowedOrigins: ['*']));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/api'), headers: {'origin': 'http://x.com'}));
      expect(res.headers['access-control-allow-origin'], isNotNull);
    });
  });

  group('BootRouter security', () {
    test('rejects unauthenticated', () async {
      final router = BootRouter();
      router.addAuthenticationProvider(_FakeAuthProvider());
      router.add(RouteEntry(method: 'GET', path: '/secure', handler: (req) async => Response.ok('secret')));
      router.enableSecurity([SecurityRuleEntry(pattern: '/secure', access: ['isAuthenticated()'])]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/secure')));
      expect(res.statusCode, 401);
    });

    test('allows authenticated', () async {
      final router = BootRouter();
      router.addAuthenticationProvider(_FakeAuthProvider());
      router.add(RouteEntry(method: 'GET', path: '/secure', handler: (req) async => Response.ok('secret')));
      router.enableSecurity([SecurityRuleEntry(pattern: '/secure', access: ['isAuthenticated()'])]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/secure'), headers: {'authorization': 'Bearer valid-token'}));
      expect(res.statusCode, 200);
    });

    test('allows anonymous', () async {
      final router = BootRouter();
      router.addAuthenticationProvider(_FakeAuthProvider());
      router.add(RouteEntry(method: 'GET', path: '/public', handler: (req) async => Response.ok('open')));
      router.enableSecurity([SecurityRuleEntry(pattern: '/public', access: ['isAnonymous()']), SecurityRuleEntry(pattern: '/**', access: ['isAuthenticated()'])]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/public')));
      expect(res.statusCode, 200);
    });

    test('rejects wrong role', () async {
      final router = BootRouter();
      router.addAuthenticationProvider(_FakeAuthProvider());
      router.add(RouteEntry(method: 'GET', path: '/admin', handler: (req) async => Response.ok('admin')));
      router.enableSecurity([SecurityRuleEntry(pattern: '/admin', access: ['ROLE_ADMIN'])]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/admin'), headers: {'authorization': 'Bearer valid-token'}));
      expect(res.statusCode, 403);
    });
  });

  group('BootRouter static files', () {
    test('serves static files', () async {
      final tmpDir = io.Directory.systemTemp.createTempSync('router_static_');
      io.File('${tmpDir.path}/app.js').writeAsStringSync('var x=1;');
      final router = BootRouter();
      router.add(RouteEntry(method: 'GET', path: '/api', handler: (req) async => Response.ok('api')));
      router.enableStatic(StaticFileHandler(urlPath: '/static', directory: tmpDir.path, index: 'index.html'));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/static/app.js')));
      expect(res.statusCode, 200);
      tmpDir.deleteSync(recursive: true);
    });
  });

  group('BootRouter DI', () {
    test('auth providers from container', () {
      final container = BeanContainer();
      final router = BootRouter();
      container.overrideWithInstance<AuthenticationProvider>(_FakeAuthProvider());
      router.addAuthenticationProvider(container.get<AuthenticationProvider>());
      expect(router.authProviders.length, 1);
    });

    test('exception handlers from container', () async {
      final container = BeanContainer();
      final router = BootRouter();
      container.overrideWithInstance<ExceptionHandler<NotFoundException>>(_NotFoundHandler());
      router.addExceptionHandler<NotFoundException>(container.get<ExceptionHandler<NotFoundException>>());
      router.add(RouteEntry(method: 'GET', path: '/x', handler: (req) async => throw const NotFoundException('nope')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/x')));
      expect(res.statusCode, 404);
    });
  });
}

class _AddHeaderFilter implements HttpServerFilter {
  final String key, value;
  _AddHeaderFilter(this.key, this.value);
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    final res = await chain.proceed(request);
    return Response(res.statusCode, headers: {...res.headers, key: value}, body: res.body);
  }
}

class _OrderFilter implements HttpServerFilter {
  final List<int> log;
  final int id;
  _OrderFilter(this.log, this.id);
  @override
  Future<Response> filter(Request request, FilterChain chain) async {
    log.add(id);
    return chain.proceed(request);
  }
}

class _NotFoundHandler implements ExceptionHandler<NotFoundException> {
  @override
  Response handle(Request request, NotFoundException e) =>
      Response(404, headers: {'content-type': 'application/json'}, body: '{"error":"${e.message}"}');
}

class _FakeAuthProvider implements AuthenticationProvider {
  @override
  Future<Authentication?> authenticate(AuthenticationRequest request) async {
    if (request.authorization == 'Bearer valid-token') return Authentication(name: 'testuser', roles: ['ROLE_USER']);
    return null;
  }
}
