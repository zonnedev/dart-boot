import 'package:boot/boot.dart';

import 'test_client.dart';
import 'test_container.dart';

export 'test_client.dart';
export 'test_container.dart';

/// Helper to set up a Boot test environment.
/// Uses the same configureRuntime as Boot.run for consistent behavior.
Future<void> bootTest(
  BootContextRegistrar configure, {
  void Function(TestContainer container)? overrides,
  String env = 'test',
  Map<String, String>? properties,
  required Future<void> Function(BootTestClient client, TestContainer container)
      test,
}) async {
  final testContainer = TestContainer();
  final router = BootRouter();

  // Register framework beans (same as Boot.run)
  final config = BootConfig(properties: properties, activeEnv: env);
  testContainer.container.overrideWithInstance<BootConfig>(config);
  testContainer.container.overrideWithInstance<EventBus>(EventBus());
  testContainer.container.overrideWithInstance<TaskScheduler>(TaskScheduler());
  testContainer.container.overrideWithInstance<HttpClient>(HttpClient());

  // Apply overrides BEFORE configure so that pre-populated singletons
  // are found by container.get<T>() during eager route registration,
  // preventing @PostConstruct from running on replaced beans.
  if (overrides != null) {
    overrides(testContainer);
  }

  // Run user's generated $configure (registers beans, routes, listeners)
  configure(testContainer.container, router);

  // Shared runtime configuration — same as production
  await configureRuntime(testContainer.container, router, config);

  final client = BootTestClient(router);

  try {
    await test(client, testContainer);
  } finally {
    // Cleanup: mirror prod shutdown
    testContainer.container.get<EventBus>().publish(const ShutdownEvent());
    testContainer.container.get<TaskScheduler>().shutdown();
    await testContainer.reset();
  }
}
