import 'dart:async';

import 'package:boot/boot.dart';

import 'boot_test_environment.dart';
import 'test_client.dart';
import 'test_container.dart';

export 'test_client.dart';
export 'test_container.dart';

/// Unit test helper — in-memory HTTP client, no real server.
Future<void> bootTest(
  BootContextRegistrar configure, {
  void Function(TestContainer container)? overrides,
  String env = 'test',
  Map<String, String>? properties,
  Duration? timeout,
  required Future<void> Function(BootTestClient client, TestContainer container)
      test,
}) async {
  final testEnv = BootTestEnvironment();
  await testEnv.setUp(configure,
      overrides: overrides, env: env, properties: properties);

  final effectiveTimeout =
      timeout ?? testEnv.testTimeout ?? const Duration(seconds: 5);
  final client = BootTestClient(testEnv.router, wsServer: testEnv.wsServer);

  try {
    await test(client, testEnv.container).timeout(effectiveTimeout,
        onTimeout: () => throw TimeoutException(
            'bootTest exceeded ${effectiveTimeout.inSeconds}s timeout'));
  } finally {
    await testEnv.tearDown();
  }
}
