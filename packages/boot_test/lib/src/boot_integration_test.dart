import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:boot/boot.dart';

import 'boot_test_environment.dart';
import 'boot_test_websocket.dart';
import 'test_client.dart';
import 'test_container.dart';

/// Integration test helper — starts a real BootServer on a random port.
/// Use for testing WebSocket connections, TLS, streaming, and real HTTP.
Future<void> bootIntegrationTest(
  BootContextRegistrar configure, {
  void Function(TestContainer container)? overrides,
  String env = 'test',
  Map<String, String>? properties,
  Duration? timeout,
  required Future<void> Function(BootIntegrationClient client, TestContainer container) test,
}) async {
  final testEnv = BootTestEnvironment();
  await testEnv.setUp(configure,
      overrides: overrides, env: env, properties: properties);

  final effectiveTimeout =
      timeout ?? testEnv.integrationTimeout ?? const Duration(seconds: 15);

  final server = BootServer(
    router: testEnv.router,
    port: 0,
    address: '127.0.0.1',
    webSocketServer: testEnv.wsServer,
  );
  await server.start();

  final client = BootIntegrationClient(
    Uri.parse('http://127.0.0.1:${server.actualPort}'),
  );

  try {
    await test(client, testEnv.container).timeout(effectiveTimeout,
        onTimeout: () => throw TimeoutException(
            'bootIntegrationTest exceeded ${effectiveTimeout.inSeconds}s timeout'));
  } finally {
    await client.closeAll();
    await server.stop();
    await testEnv.tearDown();
  }
}

/// Real HTTP + WebSocket client for integration tests.
class BootIntegrationClient {
  final Uri serverUri;
  final _httpClient = io.HttpClient();
  final _openWebSockets = <BootTestWebSocket>[];

  BootIntegrationClient(this.serverUri);

  /// HTTP GET
  Future<TestResponse> get(String path, {Map<String, String>? headers}) =>
      _send('GET', path, headers: headers);

  /// HTTP POST
  Future<TestResponse> post(String path, {Object? body, Map<String, String>? headers}) =>
      _send('POST', path, body: body, headers: headers);

  /// HTTP PUT
  Future<TestResponse> put(String path, {Object? body, Map<String, String>? headers}) =>
      _send('PUT', path, body: body, headers: headers);

  /// HTTP DELETE
  Future<TestResponse> delete(String path, {Map<String, String>? headers}) =>
      _send('DELETE', path, headers: headers);

  /// Open a real WebSocket connection.
  Future<BootTestWebSocket> ws(String path, {Map<String, String>? headers}) async {
    final wsUri = serverUri.replace(scheme: 'ws', path: path);
    final socket = await io.WebSocket.connect(wsUri.toString(), headers: headers);
    final testWs = BootTestWebSocket.fromWebSocket(socket);
    _openWebSockets.add(testWs);
    return testWs;
  }

  Future<TestResponse> _send(String method, String path,
      {Object? body, Map<String, String>? headers}) async {
    final uri = serverUri.resolve(path);
    final request = await _httpClient.openUrl(method, uri);

    headers?.forEach((k, v) => request.headers.set(k, v));

    if (body != null) {
      final bodyStr = body is String ? body : jsonEncode(body);
      request.headers.contentType = io.ContentType.json;
      request.write(bodyStr);
    }

    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    final responseHeaders = <String, String>{};
    response.headers.forEach((name, values) => responseHeaders[name] = values.join(', '));

    return TestResponse(response.statusCode, responseBody, responseHeaders);
  }

  /// Close all open WebSocket connections and the HTTP client.
  Future<void> closeAll() async {
    for (final ws in _openWebSockets) {
      if (!ws.isClosed) await ws.close();
    }
    _httpClient.close();
  }
}
