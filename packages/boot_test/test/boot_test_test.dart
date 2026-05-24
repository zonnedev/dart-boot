import 'package:boot/boot.dart';
import 'package:boot_test/boot_test.dart';
import 'package:boot_test/src/test_client.dart' as tc;
import 'package:test/test.dart';

// Hand-crafted $configure — simulates what the generator produces
void _configure(BeanContainer container, BootRouter router) {
  container.register<_GreetService>(_GreetServiceDef());
  router.addAll([
    RouteEntry(method: 'GET', path: '/hello', handler: (req) async {
      final svc = container.get<_GreetService>();
      return Response.json({'message': svc.greet('World')});
    }),
    RouteEntry(method: 'POST', path: '/echo', handler: (req) async {
      final body = await req.json();
      return Response.json(body);
    }),
  ]);
}

void main() {
  group('bootTest', () {
    test('basic GET request', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.get('/hello');
        res.expectStatus(200);
        expect(res.json()['message'], 'Hello, World!');
      });
    });

    test('POST with JSON body', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.post('/echo', body: {'key': 'val'});
        res.expectStatus(200);
        expect(res.json()['key'], 'val');
      });
    });

    test('custom headers', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.get('/hello', headers: {'x-custom': 'test'});
        res.expectStatus(200);
      });
    });

    test('404 for unknown route', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.get('/unknown');
        res.expectStatus(404);
      });
    });

    test('overrides applied before configure', () async {
      await bootTest(_configure, overrides: (container) {
        container.override<_GreetService>(_MockGreetService());
      }, test: (client, container) async {
        final res = await client.get('/hello');
        res.expectStatus(200);
        expect(res.json()['message'], 'Mocked!');
      });
    });

    test('properties passed to BootConfig', () async {
      await bootTest(_configure, properties: {
        'app.name': 'test-app',
      }, test: (client, container) async {
        final config = container.get<BootConfig>();
        expect(config.get('app.name'), 'test-app');
      });
    });

    test('env defaults to test', () async {
      await bootTest(_configure, test: (client, container) async {
        final config = container.get<BootConfig>();
        expect(config.get('boot.env'), 'test');
      });
    });

    test('custom env', () async {
      await bootTest(_configure, env: 'prod', test: (client, container) async {
        final config = container.get<BootConfig>();
        expect(config.get('boot.env'), 'prod');
      });
    });

    test('each bootTest gets fresh container', () async {
      await bootTest(_configure, test: (client, container) async {
        final svc = container.get<_GreetService>();
        expect(svc, isA<_GreetService>());
      });
      // Second call — fresh container, no state leakage
      await bootTest(_configure, test: (client, container) async {
        final svc = container.get<_GreetService>();
        expect(svc, isA<_GreetService>());
      });
    });
  });

  group('TestContainer', () {
    test('get retrieves beans', () async {
      await bootTest(_configure, test: (client, container) async {
        expect(container.get<_GreetService>(), isNotNull);
      });
    });

    test('has checks registration', () async {
      await bootTest(_configure, test: (client, container) async {
        expect(container.has<_GreetService>(), isTrue);
        expect(container.has<String>(), isFalse);
      });
    });

    test('override replaces bean', () async {
      await bootTest(_configure, overrides: (container) {
        container.override<_GreetService>(_MockGreetService());
      }, test: (client, container) async {
        final svc = container.get<_GreetService>();
        expect(svc.greet('x'), 'Mocked!');
      });
    });
  });

  group('BootTestClient', () {
    test('expectStatus throws on mismatch', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.get('/hello');
        expect(() => res.expectStatus(500), throwsA(isA<tc.TestFailure>()));
      });
    });

    test('json() parses response body', () async {
      await bootTest(_configure, test: (client, container) async {
        final res = await client.post('/echo', body: {'a': 1});
        expect(res.json()['a'], 1);
      });
    });

    test('jsonList() parses array response', () async {
      // Need a route that returns a list
      void configWithList(BeanContainer c, BootRouter r) {
        r.add(RouteEntry(method: 'GET', path: '/list', handler: (req) async => Response.json([1, 2, 3])));
      }
      await bootTest(configWithList, test: (client, container) async {
        final res = await client.get('/list');
        expect(res.jsonList(), [1, 2, 3]);
      });
    });

    test('PUT and DELETE methods', () async {
      void configCrud(BeanContainer c, BootRouter r) {
        r.add(RouteEntry(method: 'PUT', path: '/item', handler: (req) async => Response.ok('updated')));
        r.add(RouteEntry(method: 'DELETE', path: '/item', handler: (req) async => Response.noContent()));
      }
      await bootTest(configCrud, test: (client, container) async {
        final putRes = await client.put('/item', body: {'x': 1});
        putRes.expectStatus(200);
        final delRes = await client.delete('/item');
        delRes.expectStatus(204);
      });
    });
  });
}

class _GreetService {
  String greet(String name) => 'Hello, $name!';
}

class _MockGreetService extends _GreetService {
  @override
  String greet(String name) => 'Mocked!';
}

class _GreetServiceDef extends BeanDefinition {
  @override
  String get typeName => '_GreetService';
  @override
  dynamic create(BeanContainer container) => _GreetService();
}
