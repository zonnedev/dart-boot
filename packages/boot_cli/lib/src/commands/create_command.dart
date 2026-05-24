import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

class CreateCommand extends Command<int> {
  CreateCommand() {
    addSubcommand(CreateAppCommand());
    addSubcommand(CreateLibraryCommand());
  }

  @override
  String get name => 'create';

  @override
  String get description => 'Create a new Boot project.';
}

class CreateAppCommand extends Command<int> {
  @override
  String get name => 'app';

  @override
  String get description => 'Create a new Boot application.';

  @override
  String get invocation => 'boot create app <name>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: boot create app <name>');
      return 64;
    }

    final projectName = argResults!.rest.first;
    final dir = Directory(p.join(Directory.current.path, projectName));

    if (dir.existsSync()) {
      stderr.writeln('Error: Directory "$projectName" already exists.');
      return 1;
    }

    print('⚡ Creating Boot app "$projectName"...');
    dir.createSync();

    _write(dir, 'pubspec.yaml', '''
name: $projectName
description: A Boot framework application.

environment:
  sdk: ^3.12.0

dependencies:
  boot: ^0.1.0

dev_dependencies:
  boot_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
  test: ^1.25.0
''');

    _write(dir, 'build.yaml', '''
targets:
  \$default:
    builders:
      boot_generator|context_builder:
        enabled: true
''');

    _write(dir, 'bin/main.dart', '''
import 'package:boot/boot.dart';
import 'package:$projectName/src/generated/boot_context.g.dart';

void main() => Boot.run(\$configure, port: 8080);
''');

    _write(dir, 'lib/$projectName.dart', '''
library $projectName;

export 'src/controllers/hello_controller.dart';
''');

    _write(dir, 'lib/src/controllers/hello_controller.dart', '''
import 'package:boot/boot.dart';

part 'hello_controller.g.dart';

@Controller('/hello')
class HelloController {
  @Get('/')
  Future<Response> hello(Request request) async {
    return Response.json({'message': 'Hello from Boot!'});
  }

  @Get('/<name>')
  Future<Response> greet(Request request, @PathParam() String name) async {
    return Response.json({'message': 'Hello, \$name!'});
  }
}
''');

    _write(dir, 'application.yml', '''
# ─── Boot Application Configuration ───────────────────────────────────────────
# ─── Boot Application Configuration ───────────────────────────────────────────
# All values shown are defaults. Uncomment and modify as needed.

boot:
  env: dev                          # Active environment (dev, test, prod)
  logging:
    level: info                     # Root log level (trace, debug, info, warn, error)
    format: text                    # Log format (text, json)
    # request-logging: true         # Log incoming requests
    stacktrace:
      filter:
        enabled: true               # Set to false to show full unfiltered stack traces
        max-depth: 10               # Max frames to show after filtering
        exclude:                    # Hide frames from these packages
          - dart:
          - package:shelf/
          - package:shelf_router/
        # include:                  # If set, ONLY show frames matching these
        #   - package:myapp/
        #   - package:boot_
  # static:
  #   enabled: true
  #   path: /static
  #   directory: public/
  #   index: index.html
  #   cache:
  #     max-age: 3600
  # security:
  #   enabled: false
  #   intercept-url-map:
  #     - pattern: /api/**
  #       access: [isAuthenticated()]
  #     - pattern: /public/**
  #       access: [permitAll()]
  # websocket:
  #   enabled: false
  #   auth: false

# ─── HTTP Server ──────────────────────────────────────────────────────────────
server:
  host: 0.0.0.0                     # Bind address
  port: 8080                        # Listen port

# ─── CORS ─────────────────────────────────────────────────────────────────────
# cors:
#   enabled: false
#   allowed-origins:
#     - http://localhost:3000
#   allowed-methods: [GET, POST, PUT, DELETE]
#   allowed-headers: [Content-Type, Authorization]
#   max-age: 3600

# ─── Custom application properties ───────────────────────────────────────────
# app:
#   name: $projectName
''');

    _write(dir, 'test/hello_test.dart', '''
import 'package:boot_test/boot_test.dart';
import 'package:$projectName/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('GET /hello returns greeting', () async {
    await bootTest(\$configure, test: (client, container) async {
      final res = await client.get('/hello/');
      res.expectStatus(200);
      expect(res.json()['message'], 'Hello from Boot!');
    });
  });
}
''');

    _write(dir, '.gitignore', '''
.dart_tool/
build/
pubspec.lock
''');

    print('✓ App created at ./$projectName');
    print('');
    print('Next steps:');
    print('  cd $projectName');
    print('  dart pub get');
    print('  boot build');
    print('  boot serve');

    return 0;
  }
}

class CreateLibraryCommand extends Command<int> {
  @override
  String get name => 'library';

  @override
  String get description => 'Create a new Boot library.';

  @override
  String get invocation => 'boot create library <name>';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: boot create library <name>');
      return 64;
    }

    final projectName = argResults!.rest.first;
    final dir = Directory(p.join(Directory.current.path, projectName));

    if (dir.existsSync()) {
      stderr.writeln('Error: Directory "$projectName" already exists.');
      return 1;
    }

    print('⚡ Creating Boot library "$projectName"...');
    dir.createSync();

    _write(dir, 'pubspec.yaml', '''
name: $projectName
description: A Boot framework library.
version: 0.1.0

environment:
  sdk: ^3.12.0

dependencies:
  boot: ^0.1.0

dev_dependencies:
  boot_generator: ^0.1.0
  boot_test: ^0.1.0
  build_runner: ^2.4.0
  test: ^1.25.0
''');

    _write(dir, 'build.yaml', '''
targets:
  \$default:
    builders:
      boot_generator|context_builder:
        enabled: true
''');

    final camelName = _toCamelCase(projectName);

    _write(dir, 'lib/$projectName.dart', '''
@BootLibrary()
library $projectName;

import 'package:boot/boot.dart';

export 'src/${projectName}_client.dart';
export 'src/generated/boot_module.g.dart';
''');

    _write(dir, 'lib/src/${projectName}_client.dart', '''
import 'package:boot/boot.dart';

part '${projectName}_client.g.dart';

/// Main client bean for $projectName.
/// Activate by setting `$projectName.enabled: true` in application.yml.
@Singleton()
@Requires(property: '$projectName.enabled', value: 'true')
class ${camelName}Client {
  ${camelName}Client();

  /// Example method — replace with your library's functionality.
  String ping() => 'pong from $projectName';
}
''');

    _write(dir, 'test/${projectName}_test.dart', '''
import 'package:boot_test/boot_test.dart';
import 'package:$projectName/src/generated/boot_context.g.dart';
import 'package:test/test.dart';

void main() {
  test('${camelName}Client is created when enabled', () async {
    await bootTest(\$configure, properties: {
      '$projectName.enabled': 'true',
    }, test: (client, container) async {
      // final bean = container.get<${camelName}Client>();
      // expect(bean.ping(), 'pong from $projectName');
    });
  });
}
''');

    _write(dir, '.gitignore', '''
.dart_tool/
build/
pubspec.lock
''');

    _write(dir, 'README.md', '''
# $projectName

A Boot framework library.

## Usage

Add to your app's `pubspec.yaml`:

```yaml
dependencies:
  $projectName: ^0.1.0
```

Configure in `application.yml`:

```yaml
$projectName:
  enabled: true
```

## Development

```bash
dart pub get
dart run build_runner build --delete-conflicting-outputs
dart test
```

Commit all `.g.dart` files before publishing.
''');

    print('✓ Library created at ./$projectName');
    print('');
    print('Next steps:');
    print('  cd $projectName');
    print('  dart pub get');
    print('  dart run build_runner build --delete-conflicting-outputs');
    print('  dart test');
    print('');
    print('Before publishing:');
    print('  - Commit all .g.dart files');
    print('  - Ensure boot_module.g.dart is exported from barrel');

    return 0;
  }
}

void _write(Directory root, String relativePath, String content) {
  final file = File(p.join(root.path, relativePath));
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

String _toCamelCase(String s) {
  return s.split(RegExp(r'[_\-]')).map((part) =>
    part.isEmpty ? '' : part[0].toUpperCase() + part.substring(1)
  ).join();
}
