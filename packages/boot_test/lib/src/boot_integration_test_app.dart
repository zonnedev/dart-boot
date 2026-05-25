import 'package:boot/boot.dart';

import 'boot_integration_test.dart';
import 'boot_test_environment.dart';
import 'test_container.dart';

/// A long-lived integration test app for use with test groups.
///
/// Start once in `setUpAll`, share across tests in the group, stop in `tearDownAll`.
/// Tests within the group share the same running server and container state,
/// enabling feature lifecycle tests (create → read → update → delete).
///
/// ```dart
/// group('Order lifecycle', () {
///   final app = BootIntegrationTestApp($configure);
///   setUpAll(() => app.start());
///   tearDownAll(() => app.stop());
///
///   test('create order', () async {
///     final res = await app.client.post('/orders/', body: {'item': 'book'});
///     res.expectStatus(201);
///   });
/// });
/// ```
class BootIntegrationTestApp {
  final BootContextRegistrar _configure;
  final void Function(TestContainer container)? _overrides;
  final String _env;
  final Map<String, String>? _properties;

  late final BootTestEnvironment _testEnv;
  late final BootServer _server;
  late final BootIntegrationClient _client;
  bool _running = false;

  BootIntegrationTestApp(
    this._configure, {
    void Function(TestContainer container)? overrides,
    String env = 'test',
    Map<String, String>? properties,
  })  : _overrides = overrides,
        _env = env,
        _properties = properties;

  /// Start the application server. Call in `setUpAll`.
  Future<void> start() async {
    _testEnv = BootTestEnvironment();
    await _testEnv.setUp(_configure,
        overrides: _overrides, env: _env, properties: _properties);
    _server = BootServer(
      router: _testEnv.router,
      port: 0,
      address: '127.0.0.1',
      webSocketServer: _testEnv.wsServer,
    );
    await _server.start();
    _client = BootIntegrationClient(
        Uri.parse('http://127.0.0.1:${_server.actualPort}'));
    _running = true;
  }

  /// Stop the server and clean up. Call in `tearDownAll`.
  Future<void> stop() async {
    if (!_running) return;
    _running = false;
    await _client.closeAll();
    await _server.stop();
    await _testEnv.tearDown();
  }

  /// The HTTP + WebSocket client connected to the running server.
  BootIntegrationClient get client {
    assert(_running, 'App not started. Call start() in setUpAll.');
    return _client;
  }

  /// The test container — access beans directly.
  TestContainer get container {
    assert(_running, 'App not started. Call start() in setUpAll.');
    return _testEnv.container;
  }

  /// The server URI (http://127.0.0.1:<port>).
  Uri get serverUri => _client.serverUri;

  /// Whether the app is currently running.
  bool get isRunning => _running;
}
