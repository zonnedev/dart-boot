# boot_generator

Code generators for the Boot Framework. Add as a dev dependency.

Generates:
- `$XxxDefinition` — bean definitions from `@Singleton`, `@Controller`, etc.
- `$XxxRoutes` — route registrations from `@Get`, `@Post`, etc.
- `$Xxx$Proxy` — AOP proxies for `@Around` methods
- `$configure` / `$Module` — application/library wiring
- `$Serdeable` — serialization extensions

## Usage

```yaml
dev_dependencies:
  boot_generator: ^0.1.0
  build_runner: ^2.4.0
```

```bash
dart run build_runner build
```
