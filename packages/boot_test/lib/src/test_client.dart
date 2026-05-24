import 'dart:convert';

import 'package:boot/boot.dart';
import 'package:shelf/shelf.dart' as shelf;

/// In-memory HTTP test client for Boot applications.
class BootTestClient {
  final shelf.Handler _handler;

  BootTestClient(BootRouter router) : _handler = router.build();

  Future<TestResponse> get(String path, {Map<String, String>? headers}) =>
      _send('GET', path, headers: headers);

  Future<TestResponse> post(String path,
          {Object? body, Map<String, String>? headers}) =>
      _send('POST', path, body: body, headers: headers);

  Future<TestResponse> put(String path,
          {Object? body, Map<String, String>? headers}) =>
      _send('PUT', path, body: body, headers: headers);

  Future<TestResponse> delete(String path, {Map<String, String>? headers}) =>
      _send('DELETE', path, headers: headers);

  Future<TestResponse> _send(String method, String path,
      {Object? body, Map<String, String>? headers}) async {
    final uri = Uri.parse('http://localhost$path');
    String? bodyStr;
    final h = <String, String>{...?headers};

    if (body != null) {
      bodyStr = body is String ? body : jsonEncode(body);
      h['content-type'] ??= 'application/json';
    }

    final request = shelf.Request(method, uri, headers: h, body: bodyStr);
    final response = await _handler(request);
    final responseBody = await response.readAsString();
    return TestResponse(response.statusCode, responseBody, response.headers);
  }
}

/// Test response with assertion helpers.
class TestResponse {
  final int statusCode;
  final String body;
  final Map<String, String> headers;

  TestResponse(this.statusCode, this.body, this.headers);

  Map<String, dynamic> json() => jsonDecode(body) as Map<String, dynamic>;
  List<dynamic> jsonList() => jsonDecode(body) as List<dynamic>;

  TestResponse expectStatus(int expected) {
    if (statusCode != expected) {
      throw TestFailure(
          'Expected status $expected but got $statusCode. Body: $body');
    }
    return this;
  }
}

class TestFailure implements Exception {
  final String message;
  TestFailure(this.message);

  @override
  String toString() => 'TestFailure: $message';
}
