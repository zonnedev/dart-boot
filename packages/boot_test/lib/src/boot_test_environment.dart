import 'package:boot/boot.dart';

import 'test_container.dart';

/// Shared test environment setup used by both bootTest and bootIntegrationTest.
class BootTestEnvironment {
  final TestContainer container = TestContainer();
  final BootRouter router = BootRouter();
  late final BootConfig config;

  /// Set up the environment: register framework beans, apply overrides, configure, wire runtime.
  Future<void> setUp(
    BootContextRegistrar configure, {
    void Function(TestContainer container)? overrides,
    String env = 'test',
    Map<String, String>? properties,
  }) async {
    config = BootConfig(properties: properties, activeEnv: env);
    container.container.overrideWithInstance<BootConfig>(config);
    container.container.overrideWithInstance<EventBus>(EventBus());
    container.container.overrideWithInstance<TaskScheduler>(TaskScheduler());

    configure(container.container, router);

    // Apply overrides AFTER configure but BEFORE configureRuntime.
    // Routes are lazy (materialized in configureRuntime), so overrides
    // take effect before any controller or service is instantiated.
    if (overrides != null) {
      overrides(container);
    }

    await configureRuntime(container.container, router, config);
  }

  /// Tear down the environment: shutdown events, scheduler, container.
  Future<void> tearDown() async {
    container.container.get<EventBus>().publish(const ShutdownEvent());
    container.container.get<TaskScheduler>().shutdown();
    await container.reset();
  }

  /// Get the WebSocketServer if available.
  WebSocketServer? get wsServer =>
      container.container.has<WebSocketServer>()
          ? container.container.get<WebSocketServer>()
          : null;

  /// Test timeout from config (`boot.test.timeout`).
  Duration? get testTimeout => parseDurationOrNull(config.get('boot.test.timeout'));

  /// Integration test timeout from config (`boot.test.integration-timeout`).
  Duration? get integrationTimeout =>
      parseDurationOrNull(config.get('boot.test.integration-timeout'));
}
