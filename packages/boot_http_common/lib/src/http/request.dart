import 'dart:convert';

import 'package:shelf/shelf.dart' as shelf;
import 'multipart.dart';



/// Immutable HTTP request.
class Request {
  final shelf.Request _inner;
  final Map<String, String> pathParams;
  final Map<String, dynamic> _attributes = {};

  Request(this._inner, {this.pathParams = const {}});

  String get method => _inner.method;
  String get path => _inner.url.path;
  Uri get uri => _inner.url;
  Map<String, String> get queryParams => _inner.url.queryParameters;
  Map<String, String> get headers => _inner.headers;

  /// Store a request-scoped attribute (e.g., authentication).
  void setAttribute(String key, dynamic value) => _attributes[key] = value;

  /// Retrieve a request-scoped attribute.
  T? getAttribute<T>(String key) => _attributes[key] as T?;

  /// Get the authenticated user (set by SecurityFilter).
  dynamic get authentication => _attributes['authentication'] as dynamic;

  Future<String> body() => _inner.readAsString();

  Future<List<int>> bodyBytes() => _inner.read().expand((b) => b).toList();

  Future<Map<String, dynamic>> json() async {
    final raw = await body();
    return jsonDecode(raw) as Map<String, dynamic>;
  }

  /// Parse multipart/form-data body.
  Future<FormData> multipart() async {
    final contentType = headers['content-type'] ?? '';
    final boundaryMatch = RegExp(r'boundary=(.+)').firstMatch(contentType);
    if (boundaryMatch == null) {
      throw FormatException('No boundary in content-type for multipart request');
    }
    final bytes = await bodyBytes();
    return parseMultipart(bytes, boundaryMatch.group(1)!.trim());
  }
}

/// Mutable HTTP request (for client filters to modify before sending).
class MutableRequest {
  String method;
  Uri uri;
  final Map<String, String> headers;
  String? _body;

  MutableRequest({
    required this.method,
    required this.uri,
    Map<String, String>? headers,
    String? body,
  })  : headers = headers ?? {},
        _body = body;

  void header(String name, String value) => headers[name] = value;
  void setBody(String body) => _body = body;
  String? get body => _body;
}
