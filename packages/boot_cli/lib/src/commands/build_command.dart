import 'dart:io';

import 'package:args/command_runner.dart';
import '../util.dart';

class BuildCommand extends Command<int> {
  @override
  String get name => 'build';

  @override
  String get description => 'Generate code (runs build_runner).';

  BuildCommand() {
    argParser.addFlag('clean',
        abbr: 'c', help: 'Delete conflicting outputs.', defaultsTo: true);
    argParser.addFlag('watch',
        abbr: 'w', help: 'Watch for changes and rebuild.');
    argParser.addFlag('exe',
        help: 'Compile to native executable after build.');
    argParser.addOption('entry',
        abbr: 'e', help: 'Entry point file.', defaultsTo: 'bin/main.dart');
    argParser.addOption('output',
        abbr: 'o', help: 'Output path for executable.', defaultsTo: 'build/app');
  }

  @override
  Future<int> run() async {
    final root = findProjectRoot();

    // Run pub get if .dart_tool/package_config.json is missing
    final packageConfig = File('$root/.dart_tool/package_config.json');
    if (!packageConfig.existsSync()) {
      print('📦 Resolving dependencies...');
      final pubCode = await runProcess('dart', ['pub', 'get'], workingDir: root);
      if (pubCode != 0) return pubCode;
    }

    final clean = argResults!['clean'] as bool;
    final watch = argResults!['watch'] as bool;
    final exe = argResults!['exe'] as bool;
    final entry = argResults!['entry'] as String;
    final output = argResults!['output'] as String;

    final args = <String>[
      'run',
      'build_runner',
      watch ? 'watch' : 'build',
      if (clean) '--delete-conflicting-outputs',
    ];

    print('⚡ Boot ${watch ? 'watching' : 'building'}...');
    final buildCode = await runProcess('dart', args, workingDir: root);
    if (buildCode != 0 || watch) return buildCode;

    if (exe) {
      print('📦 Compiling to native executable...');
      final dir = Directory('$root/${output.substring(0, output.lastIndexOf('/'))}');
      if (!dir.existsSync()) dir.createSync(recursive: true);
      final compileCode = await runProcess('dart', ['compile', 'exe', entry, '-o', output], workingDir: root);
      if (compileCode != 0) return compileCode;
      print('✅ Compiled to $output');
    }

    return 0;
  }
}
