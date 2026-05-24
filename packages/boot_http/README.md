# boot_http

HTTP server module for the Boot Framework.

## Features

- `@Controller` — route grouping with auto-derived paths
- `@Get`, `@Post`, `@Put`, `@Delete` — route annotations
- `@PathParam`, `@QueryParam`, `@Body` — parameter binding
- `BootRouter` — route registration, filters, exception handlers
- Security — `AuthenticationProvider`, `@Secured`, intercept-url-map
- Static files — serving with ETag, caching, gzip
- WebSocket — `@ServerWebSocket`, `@OnMessage`, `@OnClose`
- SSE — `Stream<SseEvent>` return type
- Health — `HealthIndicator`, `/health` endpoint
- CORS — YAML-driven configuration
