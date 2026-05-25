// coverage:ignore-file
import 'dart:io';

import 'package:boot_core/boot_core.dart';
import 'package:boot_events/boot_events.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:boot_scheduling/boot_scheduling.dart';

import 'configure_runtime.dart';

/// Function type for the generated context registration.
typedef BootContextRegistrar = void Function(BeanContainer container, BootRouter router);

class _NamedBuilderDefinition extends BeanDefinition {
  final HttpClientBuilder _builder;
  _NamedBuilderDefinition(this._builder);
  @override
  Type get beanType => HttpClientBuilder;
  @override
  dynamic create(BeanContainer container) => _builder;
}

class _ConfigDefinition extends BeanDefinition {
  final BootConfig _config;
  _ConfigDefinition(this._config);
  @override
  Type get beanType => BootConfig;
  @override
  dynamic create(BeanContainer container) => _config;
}

class _EventBusDefinition extends BeanDefinition {
  final EventBus _bus;
  _EventBusDefinition(this._bus);
  @override
  Type get beanType => EventBus;
  @override
  dynamic create(BeanContainer container) => _bus;
}

class _TaskSchedulerDefinition extends BeanDefinition {
  final TaskScheduler _scheduler;
  _TaskSchedulerDefinition(this._scheduler);
  @override
  Type get beanType => TaskScheduler;
  @override
  dynamic create(BeanContainer container) => _scheduler;
}

class _HttpClientDefinition extends BeanDefinition {
  @override
  Type get beanType => HttpClient;
  @override
  dynamic create(BeanContainer container) {
    final config = container.get<BootConfig>();
    final clientConfig = HttpClientConfiguration.fromConfig(config);
    return HttpClientBuilder.fromServiceConfig(clientConfig).build();
  }
}

Duration? _parseDur(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.endsWith('ms')) return Duration(milliseconds: int.parse(value.replaceAll('ms', '')));
  if (value.endsWith('s')) return Duration(seconds: int.parse(value.replaceAll('s', '')));
  if (value.endsWith('m')) return Duration(minutes: int.parse(value.replaceAll('m', '')));
  return null;
}

/// Main entry point for Boot applications.
class Boot {
  Boot._();

  /// Start a Boot application.
  static Future<BootServer> run(
    BootContextRegistrar configure, {
    int port = 8080,
    String address = '0.0.0.0',
    String? env,
    List<String>? args,
    Map<String, String>? properties,
  }) async {
    final startTime = DateTime.now();
    final config = BootConfig(properties: properties, activeEnv: env, args: args);
    final eventBus = EventBus();
    final taskScheduler = TaskScheduler();
    final container = BeanContainer();
    final router = BootRouter();

    // Register framework beans
    container.register<BootConfig>(_ConfigDefinition(config));
    container.register<EventBus>(_EventBusDefinition(eventBus));
    container.register<TaskScheduler>(_TaskSchedulerDefinition(taskScheduler));
    container.register<HttpClient>(_HttpClientDefinition());

    // Register named HttpClientBuilder beans from boot.http.services.*
    final serviceNames = config.getSubKeys('boot.http.services');
    for (final name in serviceNames) {
      final prefix = 'boot.http.services.$name';
      final serviceConfig = HttpClientConfiguration(
        connectTimeout: _parseDur(config.get('$prefix.connect-timeout')) ?? const Duration(seconds: 5),
        readTimeout: _parseDur(config.get('$prefix.read-timeout')) ?? const Duration(seconds: 30),
        maxRedirects: int.tryParse(config.get('$prefix.max-redirects') ?? '') ?? 5,
      );
      final baseUrl = config.get('$prefix.url') ?? '';
      final builder = HttpClientBuilder.fromServiceConfig(serviceConfig, baseUrl: baseUrl);
      container.registerNamed<HttpClientBuilder>(name, _NamedBuilderDefinition(builder));
    }

    // Run user's generated $configure (registers beans, routes, listeners)
    configure(container, router);

    // Shared runtime configuration (WebSocket, static, security, logging, etc.)
    await configureRuntime(container, router, config);

    // --- Prod-only: server infrastructure ---

    // Allow port override from config
    final configPort = config.get('server.port');
    final effectivePort = configPort != null ? int.parse(configPort) : port;

    // SSL/TLS configuration
    SslConfig? sslConfig;
    if (config.get('boot.server.ssl.enabled') == 'true') {
      final clientAuthStr = config.get('boot.server.ssl.client-auth') ?? 'none';
      final clientAuth = switch (clientAuthStr) {
        'required' => ClientAuth.required,
        'optional' => ClientAuth.optional,
        _ => ClientAuth.none,
      };
      sslConfig = SslConfig(
        certPath: config.get('boot.server.ssl.cert') ?? 'server.pem',
        keyPath: config.get('boot.server.ssl.key') ?? 'server-key.pem',
        trustStorePath: config.get('boot.server.ssl.trust-store'),
        clientAuth: clientAuth,
      );
    }

    final wsServer = container.has<WebSocketServer>() ? container.get<WebSocketServer>() : null;
    final protocol = sslConfig != null ? 'https' : 'http';
    final server = BootServer(router: router, port: effectivePort, address: address, webSocketServer: wsServer, sslConfig: sslConfig);
    await server.start();
    final startupMs = DateTime.now().difference(startTime).inMilliseconds;
    print('Boot started in ${startupMs}ms — $protocol://$address:$effectivePort');

    // Graceful shutdown
    ProcessSignal.sigint.watch().listen((_) async {
      print('\nShutting down...');
      eventBus.publish(const ShutdownEvent());
      taskScheduler.shutdown();
      await server.stop();
      await container.shutdown();
      exit(0);
    });

    return server;
  }
}
