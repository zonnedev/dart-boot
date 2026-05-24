import 'dart:io' as io;

import 'package:boot/boot.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

shelf.Request shelf_request(String method, String path, {Map<String, String>? headers}) =>
    shelf.Request(method, Uri.parse('http://localhost$path'), headers: headers ?? {});

void main() {
  group('configureRuntime', () {
    late BeanContainer container;
    late BootRouter router;

    setUp(() {
      container = BeanContainer();
      router = BootRouter();
      container.overrideWithInstance<EventBus>(EventBus());
      container.overrideWithInstance<TaskScheduler>(TaskScheduler());
      container.overrideWithInstance<HttpClient>(HttpClient());
    });

    test('does nothing with empty config', () async {
      final config = BootConfig();
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // No crash, no WebSocketServer registered
      expect(container.has<WebSocketServer>(), isFalse);
    });

    test('registers WebSocketServer when enabled', () async {
      final config = BootConfig(properties: {'boot.websocket.enabled': 'true'});
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      expect(container.has<WebSocketServer>(), isTrue);
    });

    test('WebSocketServer auth required when configured', () async {
      final config = BootConfig(properties: {
        'boot.websocket.enabled': 'true',
        'boot.websocket.auth': 'true',
      });
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      expect(container.get<WebSocketServer>().authRequired, isTrue);
    });

    test('enables security with intercept-url-map', () async {
      final config = BootConfig(properties: {
        'boot.security.enabled': 'true',
        'boot.security.intercept-url-map[0].pattern': '/api/**',
        'boot.security.intercept-url-map[0].access[0]': 'isAuthenticated()',
      });
      container.overrideWithInstance<BootConfig>(config);
      router.add(RouteEntry(method: 'GET', path: '/api/data', handler: (req) async => Response.ok('secret')));
      await configureRuntime(container, router, config);

      // Unauthenticated request should be rejected
      final handler = router.build();
      final res = await handler(shelf_request('GET', '/api/data'));
      expect(res.statusCode, 401);
    });

    test('enables static file serving', () async {
      final tmpDir = io.Directory.systemTemp.createTempSync('runtime_test_');
      io.File('${tmpDir.path}/index.html').writeAsStringSync('<h1>Hi</h1>');

      final config = BootConfig(properties: {
        'boot.static.enabled': 'true',
        'boot.static.path': '/static',
        'boot.static.directory': tmpDir.path,
        'boot.static.index': 'index.html',
      });
      container.overrideWithInstance<BootConfig>(config);
      router.add(RouteEntry(method: 'GET', path: '/api', handler: (req) async => Response.ok('api')));
      await configureRuntime(container, router, config);

      final handler = router.build();
      final res = await handler(shelf_request('GET', '/static/'));
      expect(res.statusCode, 200);
      expect(await res.readAsString(), contains('<h1>Hi</h1>'));

      tmpDir.deleteSync(recursive: true);
    });

    test('publishes StartupEvent after ready', () async {
      final config = BootConfig();
      container.overrideWithInstance<BootConfig>(config);

      final events = <StartupEvent>[];
      container.get<EventBus>().on<StartupEvent>((e) => events.add(e));

      await configureRuntime(container, router, config);
      expect(events.length, 1);
    });

    test('sets log level from config', () async {
      final config = BootConfig(properties: {'boot.logging.level': 'error'});
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      expect(LogManager().rootLevel, Level.error);
      LogManager().rootLevel = Level.info; // reset
    });

    test('enables CORS when configured', () async {
      final config = BootConfig(properties: {
        'boot.http.cors.enabled': 'true',
        'boot.http.cors.allowed-origins[0]': 'http://localhost:3000',
      });
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // CORS is enabled — no crash
    });

    test('enables request logging by default', () async {
      final config = BootConfig();
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // Request logging enabled (default: not 'false')
    });

    test('disables request logging when configured', () async {
      final config = BootConfig(properties: {'boot.logging.request-logging': 'false'});
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // No crash
    });

    test('configures stack trace filtering', () async {
      final config = BootConfig(properties: {
        'boot.logging.stacktrace.filter.enabled': 'true',
        'boot.logging.stacktrace.filter.max-depth': '5',
      });
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
    });

    test('disables stack trace filtering', () async {
      final config = BootConfig(properties: {
        'boot.logging.stacktrace.filter.enabled': 'false',
      });
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
    });

    test('enables health endpoints when configured', () async {
      final config = BootConfig(properties: {
        'boot.health.enabled': 'true',
        'boot.health.path': '/health',
        'boot.health.ready-path': '/ready',
      });
      container.overrideWithInstance<BootConfig>(config);
      router.add(RouteEntry(method: 'GET', path: '/api', handler: (req) async => Response.ok('api')));
      await configureRuntime(container, router, config);

      final handler = router.build();
      final res = await handler(shelf_request('GET', '/health'));
      expect(res.statusCode, 200);
      expect(await res.readAsString(), contains('UP'));
    });

    test('sets json log format', () async {
      final config = BootConfig(properties: {'boot.logging.format': 'json'});
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // Reset
      LogManager().setHandlers([ConsoleLogHandler()]);
    });

    test('trace propagation enabled by default', () async {
      final config = BootConfig();
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
      // HttpClient should have trace filter added — no crash
    });

    test('trace propagation disabled', () async {
      final config = BootConfig(properties: {'boot.tracing.propagation': 'false'});
      container.overrideWithInstance<BootConfig>(config);
      await configureRuntime(container, router, config);
    });
  });
}
