import 'dart:convert';

import 'package:boot_core/boot_core.dart';
import 'package:boot_http_common/boot_http_common.dart';
import 'package:shelf/shelf.dart' as shelf;
import 'package:test/test.dart';

Request _makeRequest(String method, String path,
    {Map<String, String>? headers, String? body, Map<String, String>? pathParams}) {
  final uri = Uri.parse('http://localhost$path');
  final inner = shelf.Request(method, uri, headers: headers ?? {}, body: body);
  return Request(inner, pathParams: pathParams ?? {});
}

void main() {
  group('Request', () {
    test('method and path', () {
      final req = _makeRequest('GET', '/users/1');
      expect(req.method, 'GET');
      expect(req.path, 'users/1');
    });

    test('query params', () {
      final req = _makeRequest('GET', '/search?q=dart&page=2');
      expect(req.queryParams['q'], 'dart');
      expect(req.queryParams['page'], '2');
    });

    test('headers', () {
      final req = _makeRequest('GET', '/', headers: {'x-custom': 'val'});
      expect(req.headers['x-custom'], 'val');
    });

    test('path params', () {
      final req = _makeRequest('GET', '/users/42', pathParams: {'id': '42'});
      expect(req.pathParams['id'], '42');
    });

    test('body reads string', () async {
      final req = _makeRequest('POST', '/', body: 'hello');
      expect(await req.body(), 'hello');
    });

    test('json parses body', () async {
      final req = _makeRequest('POST', '/',
          headers: {'content-type': 'application/json'},
          body: '{"name":"test"}');
      final json = await req.json();
      expect(json['name'], 'test');
    });

    test('setAttribute and getAttribute', () {
      final req = _makeRequest('GET', '/');
      req.setAttribute('userId', 42);
      expect(req.getAttribute<int>('userId'), 42);
      expect(req.getAttribute<String>('missing'), isNull);
    });

    test('multipart parses form data', () async {
      final boundary = '----boundary';
      final body = '--$boundary\r\n'
          'Content-Disposition: form-data; name="field1"\r\n'
          '\r\n'
          'value1\r\n'
          '--$boundary\r\n'
          'Content-Disposition: form-data; name="file1"; filename="test.txt"\r\n'
          'Content-Type: text/plain\r\n'
          '\r\n'
          'file content\r\n'
          '--$boundary--\r\n';
      final req = _makeRequest('POST', '/',
          headers: {'content-type': 'multipart/form-data; boundary=$boundary'},
          body: body);
      final form = await req.multipart();
      expect(form.field('field1'), 'value1');
      expect(form.file('file1'), isNotNull);
      expect(form.file('file1')!.filename, 'test.txt');
      expect(form.file('file1')!.contentType, 'text/plain');
    });

    test('multipart throws without boundary', () async {
      final req = _makeRequest('POST', '/',
          headers: {'content-type': 'application/json'}, body: '{}');
      expect(() => req.multipart(), throwsFormatException);
    });
  });

  group('Response', () {
    test('Response.json', () {
      final res = Response.json({'key': 'val'});
      expect(res.statusCode, 200);
      expect(res.headers['content-type'], 'application/json');
      expect(jsonDecode(res.body!), {'key': 'val'});
    });

    test('Response.json with custom status', () {
      final res = Response.json({'error': 'x'}, statusCode: 422);
      expect(res.statusCode, 422);
    });

    test('Response.created', () {
      final res = Response.created({'id': 1});
      expect(res.statusCode, 201);
      expect(jsonDecode(res.body!)['id'], 1);
    });

    test('Response.created without body', () {
      final res = Response.created();
      expect(res.statusCode, 201);
      expect(res.body, isNull);
    });

    test('Response.noContent', () {
      final res = Response.noContent();
      expect(res.statusCode, 204);
    });

    test('Response.notFound', () {
      final res = Response.notFound('gone');
      expect(res.statusCode, 404);
      expect(res.body, 'gone');
    });

    test('Response.badRequest', () {
      final res = Response.badRequest('invalid');
      expect(res.statusCode, 400);
      expect(res.body, 'invalid');
    });

    test('Response.error', () {
      final res = Response.error();
      expect(res.statusCode, 500);
    });

    test('Response.redirect', () {
      final res = Response.redirect('/login');
      expect(res.statusCode, 302);
      expect(res.headers['location'], '/login');
    });

    test('Response.text', () {
      final res = Response.text('hello');
      expect(res.headers['content-type'], 'text/plain');
      expect(res.body, 'hello');
    });

    test('Response.html', () {
      final res = Response.html('<h1>Hi</h1>');
      expect(res.headers['content-type'], 'text/html');
    });

    test('Response.ok', () {
      final res = Response.ok('fine');
      expect(res.statusCode, 200);
      expect(res.body, 'fine');
    });

    test('Response.status', () {
      final res = Response.status(418, body: 'teapot');
      expect(res.statusCode, 418);
      expect(res.body, 'teapot');
    });

    test('toShelf converts correctly', () {
      final res = Response.json({'x': 1});
      final shelfRes = res.toShelf();
      expect(shelfRes.statusCode, 200);
    });
  });

  group('MutableRequest', () {
    test('set and read fields', () {
      final req = MutableRequest(method: 'POST', uri: Uri.parse('http://x.com/api'));
      req.header('Authorization', 'Bearer token');
      req.setBody('{"data":1}');
      expect(req.headers['Authorization'], 'Bearer token');
      expect(req.body, '{"data":1}');
      expect(req.method, 'POST');
    });
  });

  group('MutableResponse', () {
    test('build and convert', () {
      final res = MutableResponse(200, headers: {'x-req-id': 'abc'}, body: 'ok');
      res.header('x-extra', 'val');
      res.statusCode = 201;
      final response = res.toResponse();
      expect(response.statusCode, 201);
      expect(response.headers['x-extra'], 'val');
      expect(response.body, 'ok');
    });
  });

  group('HttpExceptions', () {
    test('all exceptions have correct status codes', () {
      expect(const BadRequestException().statusCode, 400);
      expect(const UnauthorizedException().statusCode, 401);
      expect(const ForbiddenException().statusCode, 403);
      expect(const NotFoundException().statusCode, 404);
      expect(const ConflictException().statusCode, 409);
      expect(const UnprocessableException().statusCode, 422);
      expect(const RateLimitException().statusCode, 429);
      expect(const InternalServerException().statusCode, 500);
      expect(const ServiceUnavailableException().statusCode, 503);
    });

    test('custom messages', () {
      expect(const BadRequestException('oops').message, 'oops');
      expect(const NotFoundException('gone').toString(), 'gone');
    });

    test('HttpException base', () {
      const e = HttpException(418, 'teapot');
      expect(e.statusCode, 418);
      expect(e.message, 'teapot');
    });
  });

  group('FilterChain', () {
    test('proceed calls handler when no filters', () async {
      final chain = FilterChain([], (req) async => Response.ok('done'));
      final req = _makeRequest('GET', '/');
      final res = await chain.proceed(req);
      expect(res.body, 'done');
    });

    test('filters execute in order', () async {
      final order = <int>[];
      final f1 = _TestFilter((req, chain) async {
        order.add(1);
        return chain.proceed(req);
      });
      final f2 = _TestFilter((req, chain) async {
        order.add(2);
        return chain.proceed(req);
      });
      final chain = FilterChain([f1, f2], (req) async {
        order.add(3);
        return Response.ok('end');
      });
      await chain.proceed(_makeRequest('GET', '/'));
      expect(order, [1, 2, 3]);
    });

    test('filter can short-circuit', () async {
      final f1 = _TestFilter((req, chain) async => Response(403, body: 'blocked'));
      final chain = FilterChain([f1], (req) async => Response.ok('never'));
      final res = await chain.proceed(_makeRequest('GET', '/'));
      expect(res.statusCode, 403);
      expect(res.body, 'blocked');
    });

    test('filter can modify response', () async {
      final f1 = _TestFilter((req, chain) async {
        final res = await chain.proceed(req);
        return Response(res.statusCode, headers: {...res.headers, 'x-added': 'yes'}, body: res.body);
      });
      final chain = FilterChain([f1], (req) async => Response.ok('hi'));
      final res = await chain.proceed(_makeRequest('GET', '/'));
      expect(res.headers['x-added'], 'yes');
      expect(res.body, 'hi');
    });
  });

  group('DI integration', () {
    test('ExceptionHandler registered in container', () {
      final container = BeanContainer();
      container.overrideWithInstance<ExceptionHandler<NotFoundException>>(_NotFoundHandler());
      final handler = container.get<ExceptionHandler<NotFoundException>>();
      final res = handler.handle(_makeRequest('GET', '/x'), const NotFoundException('gone'));
      expect(res.statusCode, 404);
    });

    test('multiple ExceptionHandlers for different types', () {
      final container = BeanContainer();
      container.overrideWithInstance<ExceptionHandler<NotFoundException>>(_NotFoundHandler());
      container.overrideWithInstance<ExceptionHandler<BadRequestException>>(_BadRequestHandler());

      final h1 = container.get<ExceptionHandler<NotFoundException>>();
      final h2 = container.get<ExceptionHandler<BadRequestException>>();
      expect(h1.handle(_makeRequest('GET', '/'), const NotFoundException()).statusCode, 404);
      expect(h2.handle(_makeRequest('GET', '/'), const BadRequestException()).statusCode, 400);
    });
  });
}

class _TestFilter implements HttpServerFilter {
  final Future<Response> Function(Request, FilterChain) _fn;
  _TestFilter(this._fn);

  @override
  Future<Response> filter(Request request, FilterChain chain) => _fn(request, chain);
}

class _NotFoundHandler implements ExceptionHandler<NotFoundException> {
  @override
  Response handle(Request request, NotFoundException e) =>
      Response(404, headers: {'content-type': 'application/json'}, body: '{"error":"${e.message}"}');
}

class _BadRequestHandler implements ExceptionHandler<BadRequestException> {
  @override
  Response handle(Request request, BadRequestException e) =>
      Response(400, headers: {'content-type': 'application/json'}, body: '{"error":"${e.message}"}');
}
