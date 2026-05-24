# Boot Framework

A compile-time dependency injection and HTTP framework for Dart, inspired by [Micronaut](https://micronaut.io). Zero runtime reflection.

## Quick Start

```bash
dart pub global activate boot_cli
boot create app myapp
cd myapp && dart pub get
boot serve
```

Visit `http://localhost:8080/hello/` → `{"message": "Hello from Boot!"}`

## Example

```dart
import 'package:boot/boot.dart';
part 'user_controller.g.dart';

@Controller()  // auto-derives path: /user
class UserController {
  final UserRepository _repo;
  UserController(this._repo);

  @Get('/')
  Future<Response> list(Request req) async {
    return Response.json(await _repo.findAll());
  }

  @Get('/<id>')
  Future<Response> get(Request req, @PathParam() String id) async {
    return Response.json(await _repo.findById(id));
  }

  @Post('/')
  Future<Response> create(Request req, @Body() CreateUser body) async {
    return Response.created(await _repo.save(body));
  }
}
```

## Features

- **Compile-time DI** — `@Singleton`, `@Prototype`, `@Factory`, `@Named`, `@Primary`, `@Requires`
- **Auto-detection** — Interfaces registered automatically, controller paths derived from class names
- **HTTP Server** — `@Controller`, `@Get`/`@Post`/`@Put`/`@Delete`, `@PathParam`, `@QueryParam`, `@Header`, `@Body`
- **HTTP Client** — `@Client(url:)` or `@Client(name:)` with `HttpClientBuilder`
- **HTTP Filters** — `@ServerFilter`, `@ClientFilter` with `@Order` for priority
- **Static Files** — Serve frontend assets with caching, ETag, gzip support
- **File Uploads** — Multipart/form-data parsing with `FormData` and `MultipartFile`
- **Streaming** — `Stream<SseEvent>` for SSE, `Stream<List<int>>` for chunked responses
- **Error Handling** — `ExceptionHandler<E>`, filtered stack traces, crash-proof server
- **Null Safety as Validation** — `String param` = required (400 if missing), `String? param` = optional
- **Security** — `AuthenticationProvider`, mTLS, intercept-url-map, `@Secured`
- **TLS/mTLS** — Client certificate auth for IoT, OCPP, service-to-service
- **CORS** — YAML-driven, automatic preflight handling
- **AOP** — `@Around` with compile-time proxy generation
- **Serialization** — `@Serdeable`, `@Serializable`, `@Deserializable`
- **Configuration** — `application.yml`, profiles, env vars, `@Value`
- **Logging** — Structured (JSON/text), per-request tracing, configurable stack trace filtering
- **Tracing** — W3C `traceparent`, `BootContext`, automatic propagation
- **Events** — `EventBus`, `@EventListener`
- **Scheduling** — `@Scheduled` with fixedRate, fixedDelay
- **Health** — `HealthIndicator` interface, `/health` endpoint
- **WebSocket** — `@ServerWebSocket`, `@OnMessage`, `@OnClose`, token/mTLS auth on upgrade
- **Testing** — `bootTest()` with in-memory HTTP client and bean overrides
- **CLI** — `boot create`, `boot serve -w`, `boot build`, `boot test -w`, `boot doctor`, `boot beans`, `boot routes`
- **Library ecosystem** — `@BootLibrary`, auto-discovery, module functions, transitive deps
- **Build-time validation** — Circular deps, missing beans, ambiguous beans, missing module exports

## Packages

| Package | Description | Depend on this if... |
|---------|-------------|---------------------|
| `boot_core` | Annotations, DI container, config, logging, tracing | You're writing a library that provides beans |
| `boot_aop` | `@Around`, interceptors | You provide AOP interceptors |
| `boot_events` | `EventBus`, `@EventListener` | You publish/subscribe events |
| `boot_scheduling` | `@Scheduled`, `TaskScheduler` | You have scheduled tasks |
| `boot_serialization` | `@Serdeable` | You need serialization |
| `boot_http_common` | `Request`, `Response`, `Filter`, `FormData` | You work with HTTP primitives |
| `boot_http` | Server, Router, Controller, Security, Health, WebSocket | You provide HTTP endpoints |
| `boot_http_client` | `@Client`, `HttpClient` | You provide HTTP clients |
| `boot` | **Umbrella** — re-exports everything + `Boot.run` | You're building an application |
| `boot_generator` | Code generators | Dev dependency for code gen |
| `boot_test` | Testing utilities | Dev dependency for tests |
| `boot_cli` | Developer CLI | Global install |

## Writing a Library

```bash
boot create library boot_redis
```

Library devs depend on `boot_core` (not the full `boot`):

```yaml
dependencies:
  boot_core: ^0.1.0
```

The framework auto-discovers `@BootLibrary` packages and calls their generated module functions. Internal beans, conditional loading, and transitive dependencies all work automatically.

See [docs/libraries.md](docs/libraries.md) for the full guide.

## Architecture

```
User Code (@Singleton, @Controller, @Client, etc.)
        ↓ build_runner
Code Generators (boot_generator)
        ↓ produces
Generated Code ($Definitions, $Proxies, $Routes, $Modules)
        ↓ at runtime
Boot Container + HTTP Server (40ms startup)
```

All wiring is resolved at compile time. The runtime is a lightweight container that instantiates pre-generated definitions — no reflection, no classpath scanning, no proxy generation at runtime.

## Documentation

1. [Getting Started](docs/getting-started.md)
2. [Configuration](docs/configuration.md)
3. [Dependency Injection](docs/dependency-injection.md)
4. [HTTP Server](docs/http-server.md)
5. [HTTP Client](docs/http-client.md)
6. [HTTP Filters](docs/filters.md)
7. [Error Handling](docs/error-handling.md)
8. [Security & mTLS](docs/security.md)
9. [Serialization](docs/serialization.md)
10. [AOP (Interceptors)](docs/aop.md)
11. [Logging & Tracing](docs/logging.md)
12. [WebSockets](docs/websockets.md)
13. [Scheduling](docs/scheduling.md)
14. [Testing](docs/testing.md)
15. [CLI](docs/cli.md)
16. [Writing Libraries](docs/libraries.md)

## License

MIT
