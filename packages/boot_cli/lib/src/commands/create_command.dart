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

/// Generates dependency YAML for a given package.
String _dep(String package, String? gitUrl, String? ref) {
  if (gitUrl == null) return '  $package: ^0.1.0';
  final refLine = ref != null ? '\n      ref: $ref' : '';
  return '  $package:\n    git:\n      url: $gitUrl\n      path: packages/$package$refLine';
}

class CreateAppCommand extends Command<int> {
  CreateAppCommand() {
    argParser.addOption('git', help: 'Git repository URL for Boot packages.');
    argParser.addOption('ref', help: 'Git ref (branch, tag, or SHA).', defaultsTo: null);
  }

  @override
  String get name => 'app';

  @override
  String get description => 'Create a new Boot application.';

  @override
  String get invocation => 'boot create app <name> [--git <url>] [--ref <ref>]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: boot create app <name>');
      return 64;
    }

    final projectName = argResults!.rest.first;
    final gitUrl = argResults!['git'] as String?;
    final ref = argResults!['ref'] as String?;
    final dir = Directory(p.join(Directory.current.path, projectName));

    if (dir.existsSync()) {
      stderr.writeln('Error: Directory "$projectName" already exists.');
      return 1;
    }

    print('⚡ Creating Boot app "$projectName"...');
    dir.createSync();

    final bootDep = _dep('boot', gitUrl, ref);
    final generatorDep = _dep('boot_generator', gitUrl, ref);
    final testDep = _dep('boot_test', gitUrl, ref);

    _write(dir, 'pubspec.yaml', '''
name: $projectName
description: A Boot framework application.

environment:
  sdk: ^3.5.0

dependencies:
$bootDep

dev_dependencies:
$generatorDep
$testDep
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
boot:
  env: dev
  logging:
    level: info

server:
  host: 0.0.0.0
  port: 8080
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
  CreateLibraryCommand() {
    argParser.addOption('git', help: 'Git repository URL for Boot packages.');
    argParser.addOption('ref', help: 'Git ref (branch, tag, or SHA).', defaultsTo: null);
  }

  @override
  String get name => 'library';

  @override
  String get description => 'Create a new Boot library.';

  @override
  String get invocation => 'boot create library <name> [--git <url>] [--ref <ref>]';

  @override
  Future<int> run() async {
    if (argResults!.rest.isEmpty) {
      stderr.writeln('Usage: boot create library <name>');
      return 64;
    }

    final projectName = argResults!.rest.first;
    final gitUrl = argResults!['git'] as String?;
    final ref = argResults!['ref'] as String?;
    final dir = Directory(p.join(Directory.current.path, projectName));

    if (dir.existsSync()) {
      stderr.writeln('Error: Directory "$projectName" already exists.');
      return 1;
    }

    print('⚡ Creating Boot library "$projectName"...');
    dir.createSync();

    final bootDep = _dep('boot', gitUrl, ref);
    final generatorDep = _dep('boot_generator', gitUrl, ref);
    final testDep = _dep('boot_test', gitUrl, ref);

    _write(dir, 'pubspec.yaml', '''
name: $projectName
description: A Boot framework library.
version: 0.1.0

environment:
  sdk: ^3.5.0

dependencies:
$bootDep

dev_dependencies:
$generatorDep
$testDep
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
    print('  boot build');
    print('  dart test');

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
