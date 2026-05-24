import 'dart:convert';

import 'package:boot_core/boot_core.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_http_common/boot_http_common.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

Request _req(String method, String path, {Map<String, String>? headers, String? body}) {
  final uri = Uri.parse('http://localhost$path');
  return Request(shelf.Request(method, uri, headers: headers ?? {}, body: body));
}

void main() {
  group('BootRouter', () {
    late BootRouter router;

    setUp(() => router = BootRouter());

    test('add and build routes', () async {
      router.add(RouteEntry(method: 'GET', path: '/hello', handler: (req) async => Response.ok('hi')));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/hello')));
      expect(res.statusCode, 200);
      expect(await res.readAsString(), 'hi');
    });

    test('addAll registers multiple routes', () async {
      router.addAll([
        RouteEntry(method: 'GET', path: '/a', handler: (req) async => Response.ok('a')),
        RouteEntry(method: 'GET', path: '/b', handler: (req) async => Response.ok('b')),
      ]);
      final handler = router.build();
      final resA = await handler(shelf.Request('GET', Uri.parse('http://localhost/a')));
      final resB = await handler(shelf.Request('GET', Uri.parse('http://localhost/b')));
      expect(await resA.readAsString(), 'a');
      expect(await resB.readAsString(), 'b');
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
      expect(order, [0, 1]); // lower order first
    });

    test('addExceptionHandler catches typed exceptions', () async {
      router.add(RouteEntry(method: 'GET', path: '/fail', handler: (req) async {
        throw const NotFoundException('gone');
      }));
      router.addExceptionHandler<NotFoundException>(_NotFoundHandler());
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/fail')));
      expect(res.statusCode, 404);
      expect(await res.readAsString(), contains('gone'));
    });

    test('unhandled exception returns 500', () async {
      router.add(RouteEntry(method: 'GET', path: '/crash', handler: (req) async {
        throw Exception('unexpected');
      }));
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/crash')));
      expect(res.statusCode, 500);
    });

    test('addAuthenticationProvider registers provider', () {
      router.addAuthenticationProvider(_FakeAuthProvider());
      expect(router.authProviders.length, 1);
    });

    test('addHealthIndicator registers indicator', () {
      router.addHealthIndicator(_FakeHealthIndicator());
      expect(router.healthIndicators.length, 1);
    });
  });

  group('BootRouter security', () {
    late BootRouter router;

    setUp(() {
      router = BootRouter();
      router.addAuthenticationProvider(_FakeAuthProvider());
    });

    test('security rejects unauthenticated request', () async {
      router.add(RouteEntry(method: 'GET', path: '/secure', handler: (req) async => Response.ok('secret')));
      router.enableSecurity([
        SecurityRuleEntry(pattern: '/secure', access: ['isAuthenticated()']),
      ]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/secure')));
      expect(res.statusCode, 401);
    });

    test('security allows authenticated request', () async {
      router.add(RouteEntry(method: 'GET', path: '/secure', handler: (req) async => Response.ok('secret')));
      router.enableSecurity([
        SecurityRuleEntry(pattern: '/secure', access: ['isAuthenticated()']),
      ]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/secure'),
          headers: {'authorization': 'Bearer valid-token'}));
      expect(res.statusCode, 200);
      expect(await res.readAsString(), 'secret');
    });

    test('security allows anonymous access', () async {
      router.add(RouteEntry(method: 'GET', path: '/public', handler: (req) async => Response.ok('open')));
      router.enableSecurity([
        SecurityRuleEntry(pattern: '/public', access: ['isAnonymous()']),
        SecurityRuleEntry(pattern: '/**', access: ['isAuthenticated()']),
      ]);
      final handler = router.build();
      final res = await handler(shelf.Request('GET', Uri.parse('http://localhost/public')));
      expect(res.statusCode, 200);
    });
  });

  group('BootRouter with DI container', () {
    test('router wired via container', () {
      final container = BeanContainer();
      final router = BootRouter();
      container.overrideWithInstance<BootRouter>(router);
      expect(identical(container.get<BootRouter>(), router), isTrue);
    });

    test('auth providers from container registered on router', () {
      final container = BeanContainer();
      final router = BootRouter();
      final provider = _FakeAuthProvider();

      // Simulate $configure: router.addAuthenticationProvider(container.get<AuthProvider>())
      container.overrideWithInstance<AuthenticationProvider>(provider);
      router.addAuthenticationProvider(container.get<AuthenticationProvider>());

      expect(router.authProviders.length, 1);
    });

    test('exception handlers from container registered on router', () async {
      final container = BeanContainer();
      final router = BootRouter();
      final handler = _NotFoundHandler();

      container.overrideWithInstance<ExceptionHandler<NotFoundException>>(handler);
      router.addExceptionHandler<NotFoundException>(container.get<ExceptionHandler<NotFoundException>>());

      router.add(RouteEntry(method: 'GET', path: '/x', handler: (req) async => throw const NotFoundException('nope')));
      final built = router.build();
      final res = await built(shelf.Request('GET', Uri.parse('http://localhost/x')));
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
    if (request.authorization == 'Bearer valid-token') {
      return Authentication(name: 'testuser', roles: ['ROLE_USER']);
    }
    return null;
  }
}

class _FakeHealthIndicator implements HealthIndicator {
  @override
  String get name => 'fake';

  @override
  Future<HealthResult> check() async => HealthResult.up('ok');
}
