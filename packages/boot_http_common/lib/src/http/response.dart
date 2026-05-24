import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;

/// HTTP response.
class Response {
  final int statusCode;
  final Map<String, String> headers;
  final String? _body;
  final Stream<List<int>>? _bodyStream;

  const Response(this.statusCode, {this.headers = const {}, String? body, Stream<List<int>>? bodyStream})
      : _body = body, _bodyStream = bodyStream;

  factory Response.ok([String? body]) => Response(200, body: body);

  factory Response.json(Object object, {int statusCode = 200}) => Response(
        statusCode,
        headers: {'content-type': 'application/json'},
        body: jsonEncode(object),
      );

  factory Response.created([Object? body]) => Response(
        201,
        headers: body != null ? {'content-type': 'application/json'} : const {},
        body: body != null ? jsonEncode(body) : null,
      );

  factory Response.noContent() => const Response(204);

  factory Response.notFound([String? message]) =>
      Response(404, body: message ?? 'Not Found');

  factory Response.badRequest([String? message]) =>
      Response(400, body: message ?? 'Bad Request');

  factory Response.error([String? message]) =>
      Response(500, body: message ?? 'Internal Server Error');

  factory Response.status(int code, {String? body}) =>
      Response(code, body: body);

  factory Response.redirect(String location, {int statusCode = 302}) =>
      Response(statusCode, headers: {'location': location});

  factory Response.text(String body) =>
      Response(200, headers: {'content-type': 'text/plain'}, body: body);

  factory Response.html(String body) =>
      Response(200, headers: {'content-type': 'text/html'}, body: body);

  /// Create a streaming response (SSE, chunked downloads, etc.)
  factory Response.stream(Stream<List<int>> body, {int statusCode = 200, Map<String, String> headers = const {}}) =>
      Response(statusCode, headers: headers, bodyStream: body);

  String? get body => _body;

  /// Convert to shelf Response (internal use only).
  shelf.Response toShelf() => shelf.Response(
        statusCode,
        body: _bodyStream ?? _body,
        headers: headers,
      );
}

/// Mutable response (for server filters to modify headers/status after handler).
class MutableResponse {
  int statusCode;
  final Map<String, String> headers;
  String? body;

  MutableResponse(this.statusCode, {Map<String, String>? headers, this.body})
      : headers = headers ?? {};

  void header(String name, String value) => headers[name] = value;

  Response toResponse() => Response(statusCode, headers: headers, body: body);
}
