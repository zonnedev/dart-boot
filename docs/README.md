# Boot Framework Documentation

Boot is a compile-time DI and HTTP framework for Dart, inspired by Micronaut. Zero runtime reflection.

## Reference Documentation

1. [Getting Started](getting-started.md)
2. [Configuration](configuration.md)
3. [Dependency Injection](dependency-injection.md)
4. [HTTP Server](http-server.md)
5. [HTTP Client](http-client.md)
6. [HTTP Filters](filters.md)
7. [Error Handling](error-handling.md)
8. [Security & mTLS](security.md)
9. [Serialization](serialization.md)
10. [AOP (Interceptors)](aop.md)
11. [Logging & Tracing](logging.md)
12. [WebSockets](websockets.md)
13. [Scheduling](scheduling.md)
14. [Events](../packages/boot_events/README.md)
15. [Resilience (Retry & Circuit Breaker)](resilience.md)
16. [Testing](testing.md)
17. [CLI](cli.md)
18. [Writing Libraries](libraries.md)
19. [Advanced](advanced.md)

## Step-by-Step Guides

1. [Build a REST API](guides/001-build-a-rest-api.md)
2. [Connect a Database](guides/002-connect-a-database.md)
3. [Add Authentication](guides/003-add-authentication.md)
4. [Add Error Handling](guides/004-add-error-handling.md)
5. [Use Dependency Injection](guides/005-use-dependency-injection.md)
6. [Write HTTP Filters](guides/006-write-http-filters.md)
7. [Add AOP Interceptors](guides/007-add-aop-interceptors.md)
8. [Serve Static Files](guides/008-serve-static-files.md)
9. [File Uploads](guides/009-file-uploads.md)
10. [Server-Sent Events](guides/010-server-sent-events.md)
11. [Build a WebSocket Chat](guides/011-build-a-websocket-chat.md)
12. [WebSocket with Auth](guides/012-websocket-with-auth.md)
13. [Schedule Background Tasks](guides/013-schedule-background-tasks.md)
14. [Publish and Subscribe Events](guides/014-publish-and-subscribe-events.md)
15. [Create a Library](guides/015-create-a-library.md)
16. [Consume External APIs](guides/016-consume-external-apis.md)
17. [Configure for Multiple Environments](guides/017-configure-for-multiple-envs.md)
18. [mTLS IoT Server](guides/018-mtls-iot-server.md)
19. [Deploy with Docker](guides/019-deploy-with-docker.md)
20. [Test Your Application](guides/020-test-your-application.md)

## Quick Example

```dart
@Controller('/hello')
class HelloController {
  @Get('/<name>')
  Future<Response> hello(Request req, @PathParam() String name) async {
    return Response.json({'message': 'Hello, $name!'});
  }
}
```

```bash
boot build && boot serve
curl http://localhost:8080/hello/World
```

## Installation

```yaml
dependencies:
  boot: ^0.1.0
dev_dependencies:
  boot_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
```

CLI: `dart pub global activate boot_cli`
