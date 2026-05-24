import 'dart:io' as io;

import 'package:boot_core/boot_core.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_http_common/boot_http_common.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

Request _req(String method, String path, {Map<String, String>? headers}) {
  return Request(shelf.Request(method, Uri.parse('http://localhost$path'), headers: headers ?? {}));
}

void main() {
  group('HealthEndpoint', () {
    test('liveness always returns UP', () async {
      final endpoint = HealthEndpoint([]);
      final res = await endpoint.liveness(_req('GET', '/health'));
      expect(res.statusCode, 200);
      expect(res.body, contains('UP'));
    });

    test('readiness with all healthy indicators', () async {
      final endpoint = HealthEndpoint([_OkIndicator()]);
      final res = await endpoint.readiness(_req('GET', '/ready'));
      expect(res.statusCode, 200);
      expect(res.body, contains('UP'));
    });

    test('readiness with failing indicator returns 503', () async {
      final endpoint = HealthEndpoint([_FailIndicator()]);
      final res = await endpoint.readiness(_req('GET', '/ready'));
      expect(res.statusCode, 503);
      expect(res.body, contains('DOWN'));
    });

    test('readiness with throwing indicator returns 503', () async {
      final endpoint = HealthEndpoint([_ThrowIndicator()]);
      final res = await endpoint.readiness(_req('GET', '/ready'));
      expect(res.statusCode, 503);
    });

    test('HealthResult.up and .down', () {
      final up = HealthResult.up('ok');
      final down = HealthResult.down('fail');
      expect(up.up, isTrue);
      expect(up.toJson()['status'], 'UP');
      expect(down.up, isFalse);
      expect(down.toJson()['status'], 'DOWN');
      expect(down.toJson()['message'], 'fail');
    });
  });

  group('CorsConfiguration', () {
    test('fromConfig disabled by default', () {
      final config = BootConfig();
      final cors = CorsConfiguration.fromConfig(config);
      expect(cors.enabled, isFalse);
    });

    test('fromConfig reads properties', () {
      final config = BootConfig(properties: {
        'boot.http.cors.enabled': 'true',
        'boot.http.cors.allowed-origins[0]': 'http://localhost:3000',
        'boot.http.cors.allowed-methods[0]': 'GET',
        'boot.http.cors.allowed-methods[1]': 'POST',
        'boot.http.cors.allowed-headers[0]': 'Content-Type',
        'boot.http.cors.max-age': '3600',
      });
      final cors = CorsConfiguration.fromConfig(config);
      expect(cors.enabled, isTrue);
      expect(cors.allowedOrigins, contains('http://localhost:3000'));
      expect(cors.allowedMethods, ['GET', 'POST']);
      expect(cors.allowedHeaders, ['Content-Type']);
      expect(cors.maxAge, 3600);
    });
  });

  group('SseEvent', () {
    test('encode with data only', () {
      final event = SseEvent(data: 'hello');
      expect(event.encode(), 'data: hello\n\n');
    });

    test('encode with all fields', () {
      final event = SseEvent(data: 'msg', event: 'update', id: '42', retry: 5000);
      final encoded = event.encode();
      expect(encoded, contains('event: update'));
      expect(encoded, contains('id: 42'));
      expect(encoded, contains('retry: 5000'));
      expect(encoded, contains('data: msg'));
    });

    test('encode multiline data', () {
      final event = SseEvent(data: 'line1\nline2');
      final encoded = event.encode();
      expect(encoded, contains('data: line1'));
      expect(encoded, contains('data: line2'));
    });
  });

  group('RequestLoggingFilter', () {
    test('passes request through and returns response', () async {
      final filter = RequestLoggingFilter();
      final chain = FilterChain([], (req) async => Response.ok('logged'));
      final res = await filter.filter(_req('GET', '/test'), chain);
      expect(res.statusCode, 200);
      expect(res.body, 'logged');
    });
  });

  group('StaticFileHandler', () {
    late io.Directory tmpDir;

    setUp(() {
      tmpDir = io.Directory.systemTemp.createTempSync('static_test_');
      io.File('${tmpDir.path}/index.html').writeAsStringSync('<h1>Home</h1>');
      io.File('${tmpDir.path}/style.css').writeAsStringSync('body{}');
      io.Directory('${tmpDir.path}/sub').createSync();
      io.File('${tmpDir.path}/sub/page.html').writeAsStringSync('<p>Sub</p>');
    });

    tearDown(() => tmpDir.deleteSync(recursive: true));

    test('serves index.html for root', () async {
      final handler = StaticFileHandler(
        urlPath: '/static', directory: tmpDir.path, index: 'index.html');
      final res = await handler.handle('GET', '/static/', {});
      expect(res, isNotNull);
      expect(res!.status, 200);
    });

    test('serves file by path', () async {
      final handler = StaticFileHandler(
        urlPath: '/static', directory: tmpDir.path, index: 'index.html');
      final res = await handler.handle('GET', '/static/style.css', {});
      expect(res, isNotNull);
      expect(res!.headers['content-type'], contains('text/css'));
    });

    test('returns null for missing file', () async {
      final handler = StaticFileHandler(
        urlPath: '/static', directory: tmpDir.path, index: 'index.html');
      final res = await handler.handle('GET', '/static/nope.txt', {});
      expect(res, isNull);
    });

    test('blocks path traversal', () async {
      final handler = StaticFileHandler(
        urlPath: '/static', directory: tmpDir.path, index: 'index.html');
      final res = await handler.handle('GET', '/static/../../../etc/passwd', {});
      expect(res, isNull);
    });

    test('serves subdirectory files', () async {
      final handler = StaticFileHandler(
        urlPath: '/static', directory: tmpDir.path, index: 'index.html');
      final res = await handler.handle('GET', '/static/sub/page.html', {});
      expect(res, isNotNull);
      expect(res!.status, 200);
    });
  });

  group('TracePropagationFilter', () {
    test('adds traceparent header from context', () async {
      final filter = TracePropagationFilter();
      final tp = Traceparent(traceId: 'abc', parentId: 'def');
      final ctx = BootContext();
      ctx.set(BootContextKeys.traceparent, tp);

      late MutableRequest captured;
      await ctx.run(() async {
        final req = MutableRequest(method: 'GET', uri: Uri.parse('http://x.com'));
        final chain = ClientFilterChain([], (r) async {
          captured = r;
          return Response.ok('done');
        });
        await filter.filter(req, chain);
      });
      expect(captured.headers['traceparent'], '00-abc-def-01');
    });

    test('does not overwrite existing traceparent', () async {
      final filter = TracePropagationFilter();
      final tp = Traceparent(traceId: 'new', parentId: 'new');
      final ctx = BootContext();
      ctx.set(BootContextKeys.traceparent, tp);

      late MutableRequest captured;
      await ctx.run(() async {
        final req = MutableRequest(method: 'GET', uri: Uri.parse('http://x.com'),
            headers: {'traceparent': 'existing'});
        final chain = ClientFilterChain([], (r) async {
          captured = r;
          return Response.ok('done');
        });
        await filter.filter(req, chain);
      });
      expect(captured.headers['traceparent'], 'existing');
    });
  });
}

class _OkIndicator implements HealthIndicator {
  @override
  String get name => 'ok';
  @override
  Future<HealthResult> check() async => HealthResult.up();
}

class _FailIndicator implements HealthIndicator {
  @override
  String get name => 'fail';
  @override
  Future<HealthResult> check() async => HealthResult.down('broken');
}

class _ThrowIndicator implements HealthIndicator {
  @override
  String get name => 'throw';
  @override
  Future<HealthResult> check() async => throw Exception('crash');
}
