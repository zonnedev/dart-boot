# boot_cli

Developer CLI for the Boot Framework.

## Install

```bash
dart pub global activate boot_cli
```

## Commands

| Command | Description |
|---|---|
| `boot create app <name>` | Scaffold a new Boot application |
| `boot create library <name>` | Scaffold a new Boot library |
| `boot build` | Run code generation (build_runner) |
| `boot serve` | Build and run the server |
| `boot serve -w` | Watch mode with auto-restart |
| `boot test` | Build and run tests |
| `boot test -w` | Watch mode for tests |
| `boot doctor` | Diagnose project issues |
| `boot beans` | List registered beans |
| `boot routes` | List registered routes |
| `boot --version` | Show CLI version |

## Options

```bash
boot create app myapp --git git@github.com:org/dart-boot.git --ref master
```
