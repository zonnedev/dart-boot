import 'dart:async';
import 'dart:io';

import 'package:args/command_runner.dart';
import '../util.dart';

class TestCommand extends Command<int> {
  TestCommand() {
    argParser.addFlag('watch', abbr: 'w', help: 'Watch for changes and rerun tests.');
  }

  @override
  String get name => 'test';

  @override
  String get description => 'Build and run tests.';

  @override
  Future<int> run() async {
    final root = findProjectRoot();
    final watch = argResults!['watch'] as bool;

    if (watch) return _watchMode(root);

    print('⚡ Boot building...');
    final buildCode = await runProcess('dart', [
      'run', 'build_runner', 'build', '--delete-conflicting-outputs',
    ], workingDir: root);

    if (buildCode != 0) {
      stderr.writeln('Build failed.');
      return buildCode;
    }

    print('🧪 Running tests...');
    return runProcess('dart', ['test', ...argResults!.rest], workingDir: root);
  }

  Future<int> _watchMode(String root) async {
    print('👀 Watching for changes...\n');

    final buildProcess = await Process.start(
      'dart', ['run', 'build_runner', 'watch', '--delete-conflicting-outputs'],
      workingDirectory: root,
    );

    final completer = Completer<void>();
    var testRuns = 0;

    Future<void> runTests() async {
      testRuns++;
      if (testRuns > 1) {
        print('\n┌─────────────────────────────────────');
        print('│ ♻️  Change detected — rerunning tests...');
        print('└─────────────────────────────────────\n');
      } else {
        print('🧪 Running tests...\n');
      }
      await runProcess('dart', ['test', ...argResults!.rest], workingDir: root);
    }

    buildProcess.stdout.listen((data) {
      final line = String.fromCharCodes(data);
      if (line.contains('Succeeded') || line.contains('Built with')) {
        if (!completer.isCompleted) {
          completer.complete();
        } else {
          runTests();
        }
      } else if (line.contains('Failed')) {
        print('❌ Build failed — fix errors and save to retry');
      }
    });
    buildProcess.stderr.listen(stderr.add);

    ProcessSignal.sigint.watch().listen((_) {
      print('\n⏹️  Stopping...');
      buildProcess.kill();
      exit(0);
    });

    await completer.future;
    await runTests();

    return await buildProcess.exitCode;
  }
}
