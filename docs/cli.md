# CLI

## Install

```bash
dart pub global activate boot_cli
```

## Commands

### `boot create app <name>`

Scaffold a new Boot application with controller, test, config, and build setup.

```bash
boot create app myapp
cd myapp && dart pub get && boot serve
```

### `boot create library <name>`

Scaffold a new Boot library with `@BootLibrary`, barrel file, example bean, and README.

```bash
boot create library boot_redis
cd boot_redis && dart pub get && boot build
```

### `boot build`

Run code generation (`build_runner build`).

```bash
boot build
```

### `boot serve`

Build and start the HTTP server.

```bash
boot serve           # build + run
boot serve -w        # watch mode: rebuild + restart on .dart and .yml changes
boot serve -p 3000   # custom port
```

### `boot test`

Build and run tests.

```bash
boot test            # build + run all tests
boot test -w         # watch mode: rerun tests on every change
```

### `boot doctor`

Diagnose common project issues:
- Missing dependencies
- Stale generated code
- Missing `@BootLibrary` module export
- Missing `.g.dart` files

```bash
boot doctor
```

### `boot beans`

List all registered beans and library modules in the app.

```bash
boot beans
```

Output:
```
📦 Boot Beans

Libraries:
  ⬡ BootPgModule
  ⬡ BootPoolModule

Beans:
  • PgClient          @Requires(pg.host)
  • UserController    ⇢ routes
  • ConnectionPool    @Replaces → HighPerfPool
```

### `boot clean`

Remove all generated `.g.dart` files and build cache.

```bash
boot clean
```
