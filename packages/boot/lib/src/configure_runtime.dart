import 'package:boot_core/boot_core.dart';
import 'package:boot_events/boot_events.dart';
import 'package:boot_http/boot_http.dart';
import 'package:boot_http_client/boot_http_client.dart';
import 'package:boot_scheduling/boot_scheduling.dart';

/// Shared runtime configuration used by both Boot.run and bootTest.
/// Wires all config-driven features (WebSocket, static files, security, etc.)
/// after $configure has registered beans and routes.
Future<void> configureRuntime(
  BeanContainer container,
  BootRouter router,
  BootConfig config,
) async {
  // WebSocket server
  if (config.get('boot.websocket.enabled') == 'true') {
    if (!container.has<WebSocketServer>()) {
      final maxFrame = int.tryParse(config.get('boot.websocket.max-frame-size') ?? '') ?? 65536;
      final pingStr = config.get('boot.websocket.ping-interval');
      final ping = pingStr != null ? _parseDur(pingStr) : null;
      final wsServer = WebSocketServerBuilder(maxFrameSize: maxFrame, pingInterval: ping).build();
      container.overrideWithInstance<WebSocketServer>(wsServer);
    }
    final wsServer = container.get<WebSocketServer>();
    if (config.get('boot.websocket.auth') == 'true') {
      wsServer.authRequired = true;
      for (final provider in router.authProviders) {
        wsServer.addAuthProvider(provider);
      }
    }
  }

  // CORS
  final corsConfig = CorsConfiguration.fromConfig(config);
  if (corsConfig.enabled) {
    router.enableCors(corsConfig);
  }

  // Static file serving
  if (config.get('boot.static.enabled') == 'true') {
    router.enableStatic(StaticFileHandler(
      urlPath: config.get('boot.static.path') ?? '/static',
      directory: config.get('boot.static.directory') ?? 'public',
      index: config.get('boot.static.index') ?? 'index.html',
      maxAge: int.tryParse(config.get('boot.static.cache.max-age') ?? '') ?? 3600,
      etag: config.get('boot.static.cache.etag') != 'false',
      gzip: config.get('boot.static.gzip') != 'false',
    ));
  }

  // Security
  if (config.get('boot.security.enabled') == 'true') {
    final rules = <SecurityRuleEntry>[];
    for (var i = 0; i < 50; i++) {
      final pattern = config.get('boot.security.intercept-url-map[$i].pattern');
      if (pattern == null) break;
      final method = config.get('boot.security.intercept-url-map[$i].http-method');
      final access = <String>[];
      for (var j = 0; j < 10; j++) {
        final a = config.get('boot.security.intercept-url-map[$i].access[$j]');
        if (a == null) break;
        access.add(a);
      }
      rules.add(SecurityRuleEntry(pattern: pattern, method: method, access: access));
    }
    final defaultAccess = config.get('boot.security.default-access') ?? SecurityRule.isAuthenticated;
    router.enableSecurity(rules, defaultAccess: defaultAccess);
  }

  // Logging
  final logLevel = config.get('boot.logging.level');
  if (logLevel != null) {
    LogManager().rootLevel = Level.values.firstWhere(
        (l) => l.name == logLevel.toLowerCase(), orElse: () => Level.info);
  }
  final logFormat = config.get('boot.logging.format');
  if (logFormat != null) {
    LogManager().setHandlers([ConsoleLogHandler(json: logFormat == 'json')]);
  }
  if (config.get('boot.logging.request-logging') != 'false') {
    router.enableRequestLogging();
  }

  // Stack trace filtering
  if (config.get('boot.logging.stacktrace.filter.enabled') != 'false') {
    final stMaxDepth = config.get('boot.logging.stacktrace.filter.max-depth');
    final stInclude = config.getList('boot.logging.stacktrace.filter.include');
    final stExclude = config.getList('boot.logging.stacktrace.filter.exclude');
    router.configureStackTrace(
      maxDepth: stMaxDepth != null ? int.tryParse(stMaxDepth) : null,
      include: stInclude,
      exclude: stExclude,
    );
  } else {
    router.configureStackTrace(maxDepth: 999, exclude: []);
  }

  // Trace propagation on outgoing HTTP calls
  if (config.get('boot.tracing.propagation') != 'false') {
    container.get<HttpClient>().addFilter(TracePropagationFilter());
  }

  // Health endpoints
  if (config.get('boot.health.enabled') == 'true') {
    final healthPath = config.get('boot.health.path') ?? '/health';
    final readyPath = config.get('boot.health.ready-path') ?? '/ready';
    final healthEndpoint = HealthEndpoint(router.healthIndicators);
    router.add(RouteEntry(method: 'GET', path: healthPath, handler: healthEndpoint.liveness));
    router.add(RouteEntry(method: 'GET', path: readyPath, handler: healthEndpoint.readiness));
  }

  // Wait for async @PostConstruct
  await container.ready();

  // Publish startup event
  container.get<EventBus>().publish(StartupEvent(Uri.parse('boot://runtime')));
}

Duration? _parseDur(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.endsWith('ms')) return Duration(milliseconds: int.parse(value.replaceAll('ms', '')));
  if (value.endsWith('s')) return Duration(seconds: int.parse(value.replaceAll('s', '')));
  if (value.endsWith('m')) return Duration(minutes: int.parse(value.replaceAll('m', '')));
  return null;
}
