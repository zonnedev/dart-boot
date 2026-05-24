# Getting Started

## Install the CLI

```bash
dart pub global activate boot_cli
```

## Create an Application

```bash
boot create app myapp
cd myapp
dart pub get
boot serve
```

Visit `http://localhost:8080/hello/` — you'll see `{"message": "Hello from Boot!"}`.

## Project Structure

```
myapp/
├── bin/main.dart                    # Entry point: Boot.run($configure)
├── lib/
│   ├── myapp.dart                   # Barrel file
│   └── src/
│       ├── controllers/             # @Controller classes
│       └── generated/
│           └── boot_context.g.dart  # Generated wiring (don't edit)
├── test/
├── application.yml                  # Configuration
├── build.yaml                       # Build runner config
└── pubspec.yaml
```

## Development Workflow

```bash
boot serve -w    # Watch mode: auto-rebuild + restart on .dart and .yml changes
boot test -w     # Watch mode: auto-rebuild + rerun tests on changes
boot doctor      # Diagnose issues
boot beans       # List registered beans
```

## Writing a Controller

```dart
import 'package:boot/boot.dart';

part 'user_controller.g.dart';

@Controller('/users')  // or @Controller() → auto-derives '/user'
class UserController {
  final UserService _service;
  UserController(this._service);

  @Get('/')
  Future<Response> list(Request request) async {
    return Response.json(await _service.findAll());
  }

  @Get('/<id>')
  Future<Response> getById(Request req, @PathParam() String id) async {
    final user = await _service.findById(id);
    if (user == null) throw NotFoundException('User not found');
    return Response.json(user.toJson());
  }

  @Post('/')
  Future<Response> create(Request req, @Body() CreateUserRequest body) async {
    final user = await _service.create(body);
    return Response.created(user.toJson());
  }
}
```

## Writing a Library

Library authors depend on `boot_core` (not the full `boot`):

```bash
boot create library boot_redis
cd boot_redis
dart pub get
boot build
```

```yaml
# pubspec.yaml
dependencies:
  boot_core: ^0.1.0
```

See [Writing Libraries](libraries.md) for the full guide.

## Packages

| You're building... | Depend on |
|---|---|
| An application | `boot` (umbrella) |
| A DI-only library | `boot_core` |
| A library with HTTP endpoints | `boot_core` + `boot_http` |
| A library with HTTP client | `boot_core` + `boot_http_client` |
| A library with AOP interceptors | `boot_core` + `boot_aop` |

## Configuration

All framework config lives under `boot.*` in `application.yml`:

```yaml
boot:
  env: dev
  static:
    enabled: true
    path: /static
    directory: public/
  logging:
    level: info
    stacktrace:
      filter:
        enabled: true
        max-depth: 10
        exclude:
          - dart:
          - package:shelf/
```

See [Configuration](configuration.md) for all options.

## Next Steps

- [Dependency Injection](dependency-injection.md)
- [HTTP Server](http-server.md)
- [Configuration](configuration.md)
- [Writing Libraries](libraries.md)
- [CLI](cli.md)
