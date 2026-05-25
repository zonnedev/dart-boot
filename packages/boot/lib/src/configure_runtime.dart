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
  // Discover and register server filters via annotation metadata
  final serverFilterDefs = container.getDefinitions<HttpServerFilter>();
  for (final def in serverFilterDefs) {
    final ann = def.annotationMetadata.byType(serverFilterAnnotationType);
    final pattern = ann?.values['pattern'] as String? ?? '/**';
    final orderAnn = def.annotationMetadata.byType(orderAnnotationType);
    final order = orderAnn?.values['value'] as int? ?? 0;
    final filter = def.create(container) as HttpServerFilter;
    router.addFilter(pattern, filter, order: order);
  }

  // Discover and register client filters
  for (final filter in container.getAll<HttpClientFilter>()) {
    container.get<HttpClient>().addFilter(filter);
  }

  // Discover and register exception handlers via annotation metadata
  for (final def in container.getDefinitions<ExceptionHandler>()) {
    final ann = def.annotationMetadata.byType(exceptionHandlerAnnotationType);
    final handledType = ann?.values['handledType'] as Type?;
    if (handledType != null) {
      router.addExceptionHandlerForType(handledType, def.create(container));
    }
  }

  // WebSocket server
  if (config.get('boot.websocket.enabled') == 'true') {
    if (!container.has<WebSocketServer>()) {
      final maxFrame = int.tryParse(config.get('boot.websocket.max-frame-size') ?? '') ?? 65536;
      final pingStr = config.get('boot.websocket.ping-interval');
      final ping = pingStr != null ? parseDurationOrNull(pingStr) : null;
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
    // Wire @ServerWebSocket beans via annotation metadata
    WebSocketWiringProcessor(wsServer).wireAll(container);
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
    // Discover all AuthenticationProvider beans and register with router
    for (final provider in container.getAll<AuthenticationProvider>()) {
      router.addAuthenticationProvider(provider);
    }

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
    // Discover all HealthIndicator beans
    for (final indicator in container.getAll<HealthIndicator>()) {
      router.addHealthIndicator(indicator);
    }

    final healthPath = config.get('boot.health.path') ?? '/health';
    final readyPath = config.get('boot.health.ready-path') ?? '/ready';
    final healthEndpoint = HealthEndpoint(router.healthIndicators);
    router.add(RouteEntry(method: 'GET', path: healthPath, handler: healthEndpoint.liveness));
    router.add(RouteEntry(method: 'GET', path: readyPath, handler: healthEndpoint.readiness));
  }

  // Materialize lazy routes (controllers instantiated here, after overrides)
  router.materializeRoutes();

  // Wait for async @PostConstruct
  await container.ready();

  // Discover and apply MethodWiringProcessors (EventListener, Scheduled, etc.)
  final processors = <MethodWiringProcessor>[
    EventListenerWiringProcessor(container.get<EventBus>()),
    ScheduledWiringProcessor(container.get<TaskScheduler>()),
    ...container.getAll<MethodWiringProcessor>(), // user-provided processors
  ];
  if (processors.isNotEmpty) {
    final handledTypes = processors.map((p) => p.handles).toSet();
    final seen = <BeanDefinition>{};
    for (final entry in container.allDefinitions) {
      for (final def in entry.value) {
        if (def.methodMetadata.isEmpty || seen.contains(def)) continue;
        seen.add(def);

        // Only instantiate if at least one method matches a registered processor
        final hasMatch = def.methodMetadata.any(
            (m) => m.annotations.any((a) => handledTypes.contains(a.type)));
        if (!hasMatch) continue;

        final instance = def.create(container);
        for (final method in def.methodMetadata) {
          for (final proc in processors) {
            if (method.annotations.hasType(proc.handles)) {
              proc.wire(instance, method, def);
            }
          }
        }
      }
    }
  }

  // Publish startup event
  container.get<EventBus>().publish(StartupEvent(Uri.parse('boot://runtime')));
}


