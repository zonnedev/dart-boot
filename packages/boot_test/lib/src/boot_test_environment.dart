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
    container.container.overrideWithInstance<HttpClient>(HttpClient());

    // Apply overrides BEFORE configure so that pre-populated singletons
    // are found by container.get<T>() during eager route registration,
    // preventing @PostConstruct from running on replaced beans.
    if (overrides != null) {
      overrides(container);
    }

    configure(container.container, router);
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
}
