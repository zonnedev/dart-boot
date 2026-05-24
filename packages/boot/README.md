# Boot Framework

Compile-time DI and HTTP framework for Dart. Zero reflection, zero runtime overhead.

This is the umbrella package — it re-exports all Boot modules and provides `Boot.run()`.

## Quick Start

```yaml
dependencies:
  boot: ^0.1.0
dev_dependencies:
  boot_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
```

```dart
import 'package:boot/boot.dart';

void main() => Boot.run($configure, port: 8080);
```

## Documentation

See the [full documentation](https://github.com/zonnedev/dart-boot/tree/master/docs).
