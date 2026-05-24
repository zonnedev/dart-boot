# Advanced — Extending Boot

For framework contributors and library builders.

## Architecture

```
boot (runtime)          — Annotations, container, HTTP, config
boot_generator          — build_runner code generators
boot_test              — Test utilities
boot_cli               — Developer CLI
```

## How Code Generation Works

Boot uses `build_runner` + `source_gen`. Three per-file builders run first, then an aggregating builder collects everything:

1. **BeanGenerator** — `@Singleton` → `$ClassDefinition` (BeanDefinition subclass)
2. **ControllerGenerator** — `@Controller` → `$ClassRoutes` (route registration)
3. **SerializableGenerator** — `@Serializable` → `toJson()`/`fromJson()`
4. **ContextBuilder** — Aggregates all definitions, validates graph, emits `boot_context.g.dart`

## Writing a Custom Generator

Create a `GeneratorForAnnotation<T>`:

```dart
class MyGenerator extends GeneratorForAnnotation<MyAnnotation> {
  @override
  String generateForAnnotatedElement(
    Element element, ConstantReader annotation, BuildStep buildStep,
  ) {
    return '// generated code as a string';
  }
}
```

Register in `build.yaml`:

```yaml
builders:
  my_builder:
    import: "package:my_package/builder.dart"
    builder_factories: ["myBuilder"]
    build_extensions: {".dart": [".my.g.part"]}
    auto_apply: dependents
    build_to: cache
    applies_builders: ["source_gen|combining_builder"]
```

## BeanDefinition Contract

Generated beans extend `BeanDefinition`:

```dart
class $MyServiceDefinition extends BeanDefinition {
  @override
  String get typeName => 'MyService';

  @override
  MyService create(BeanContainer container) =>
      MyService(container.get<Dependency>());

  @override
  bool get hasPostConstruct => true;

  @override
  void postConstruct(dynamic instance) =>
      (instance as MyService).init();
}
```

## Context Builder — How $configure is Generated

The `ContextBuilder` scans all `.dart` files for `@Singleton`/`@Controller`/`@Factory`:

1. Collects metadata (class name, dependencies, annotations)
2. Validates dependency graph (cycles, missing deps → build error)
3. Topologically sorts beans
4. Generates `$configure()` with conditional registration

## Adding a New Annotation

1. Define annotation in `packages/boot/lib/src/annotations/`
2. Export from `packages/boot/lib/boot.dart`
3. Add detection in `ContextBuilder` (if it affects registration)
4. Add generator in `packages/boot_generator/lib/src/` (if it generates code)
5. Add to showcase example + test
6. Update docs

## Container Internals

```dart
BeanContainer
├── register<T>(def)           — Singleton
├── registerPrototype<T>(def)  — New instance each time
├── registerNamed<T>(name, def)— By name
├── registerPrimary<T>(def)    — Default for type
├── get<T>()                   — Retrieve (creates on first access)
├── getNamed<T>(name)          — Retrieve by name
├── overrideWithInstance<T>(v) — Testing override
└── shutdown()                 — Call @PreDestroy hooks
```

## Build-Time Validation

The context builder fails the build for:
- Circular dependencies (lists the cycle)
- Missing dependencies (names what's missing and where)
- Invalid annotations (wrong target, missing constructor)

Primitive types (`String`, `int`, etc.) and `BeanContainer`/`BootConfig` are excluded from validation.

## Testing the Framework Itself

```bash
dart test packages/boot          # Runtime tests
dart test example/showcase       # Integration tests
dart analyze .                   # Static analysis
```
