# boot_core

Core DI annotations, container, configuration, and logging for the Boot Framework.

Depend on this package if you're writing a Boot library (not a full app).

## Features

- `BeanContainer` — lightweight DI container
- `@Singleton`, `@Prototype`, `@Factory`, `@Named`, `@Primary`, `@Requires`
- `BootConfig` — YAML + env + CLI config resolution
- `Logger` — structured logging with JSON/text output
- `BootContext` — request-scoped context with W3C tracing

## Usage

```yaml
dependencies:
  boot_core: ^0.1.0
```

```dart
import 'package:boot_core/boot_core.dart';
```
